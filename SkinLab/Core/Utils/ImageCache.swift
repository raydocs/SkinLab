//
//  ImageCache.swift
//  SkinLab
//
//  Thread-safe image caching with memory and disk layers.
//  All disk operations are serialized through a single DispatchQueue.
//

import UIKit
import CryptoKit

// MARK: - Cache Configuration
enum ImageCacheConfig {
    /// Maximum number of images in memory cache
    static let memoryCacheLimit = 50

    /// Maximum total memory cost (50MB)
    static let memoryCostLimit = 50 * 1024 * 1024

    /// Disk cache subdirectory name
    static let diskCacheDirectory = "ImageCache"

    /// Default cache expiration (7 days)
    static let defaultExpirationDays = 7
}

// MARK: - Image Cache
/// Thread-safe image cache with memory (NSCache) and disk layers.
/// All disk I/O is serialized through a single dispatch queue to prevent race conditions.
actor ImageCache {
    /// Shared singleton instance
    static let shared = ImageCache()

    // MARK: - Private Properties

    /// Memory cache using NSCache (thread-safe internally)
    private let memoryCache: NSCache<NSString, UIImage>

    /// Disk cache directory URL
    private let diskCacheURL: URL

    /// Serial queue for ALL disk operations (reads, writes, deletes)
    private let diskQueue = DispatchQueue(label: "com.skinlab.imagecache.disk", qos: .utility)

    /// Generation counter to invalidate pending writes after clear
    private var generation: UInt64 = 0

    // MARK: - Initialization

    init() {
        // Configure memory cache
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = ImageCacheConfig.memoryCacheLimit
        cache.totalCostLimit = ImageCacheConfig.memoryCostLimit
        self.memoryCache = cache

        // Setup disk cache directory
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.diskCacheURL = cacheDir.appendingPathComponent(
            ImageCacheConfig.diskCacheDirectory,
            isDirectory: true
        )

        // Create disk cache directory if needed
        try? FileManager.default.createDirectory(
            at: diskCacheURL,
            withIntermediateDirectories: true
        )
    }

    // MARK: - Public API

    /// Retrieve an image from cache (memory first, then disk)
    /// - Parameter key: Cache key (typically the image path or identifier)
    /// - Returns: Cached image, or nil if not found
    func image(for key: String) -> UIImage? {
        let nsKey = key as NSString

        // 1. Check memory cache first (fast path)
        if let cached = memoryCache.object(forKey: nsKey) {
            return cached
        }

        // 2. Check disk cache - dispatch sync to serialize with writes
        let fileURL = diskFileURL(for: key)
        let diskImage: UIImage? = diskQueue.sync {
            guard let data = try? Data(contentsOf: fileURL) else {
                return nil
            }
            // Update modification date on access (for LRU-like behavior)
            try? FileManager.default.setAttributes(
                [.modificationDate: Date()],
                ofItemAtPath: fileURL.path
            )
            return UIImage(data: data)
        }

        if let image = diskImage {
            // Promote to memory cache
            let cost = image.estimatedMemorySize
            memoryCache.setObject(image, forKey: nsKey, cost: cost)
            return image
        }

        return nil
    }

    /// Store an image in cache (both memory and disk)
    /// Memory storage is immediate; disk write is async but serialized
    /// - Parameters:
    ///   - image: Image to cache
    ///   - key: Cache key
    func store(_ image: UIImage, for key: String) {
        let nsKey = key as NSString
        let cost = image.estimatedMemorySize

        // Store in memory immediately
        memoryCache.setObject(image, forKey: nsKey, cost: cost)

        // Capture current generation to detect invalidation
        let storeGeneration = generation
        let fileURL = diskFileURL(for: key)

        // Encode image on disk queue (off main/actor)
        diskQueue.async { [weak self] in
            guard let self else { return }
            // Check if cache was cleared since we started
            Task {
                let currentGen = await self.generation
                guard currentGen == storeGeneration else { return }

                // Perform I/O on disk queue
                if let data = image.jpegData(compressionQuality: 0.8) {
                    try? data.write(to: fileURL, options: .atomic)
                }
            }
        }
    }

    /// Store image data directly (more efficient if you already have Data)
    /// Memory storage is immediate; disk write is async but serialized
    /// - Parameters:
    ///   - data: Image data (JPEG/PNG)
    ///   - key: Cache key
    func storeData(_ data: Data, for key: String) {
        // Load into memory cache immediately
        if let image = UIImage(data: data) {
            let nsKey = key as NSString
            let cost = image.estimatedMemorySize
            memoryCache.setObject(image, forKey: nsKey, cost: cost)
        }

        // Capture current generation
        let storeGeneration = generation
        let fileURL = diskFileURL(for: key)
        let dataCopy = data // Copy for sendability

        // Write to disk asynchronously
        diskQueue.async { [weak self] in
            guard let self else { return }
            Task {
                let currentGen = await self.generation
                guard currentGen == storeGeneration else { return }
                try? dataCopy.write(to: fileURL, options: .atomic)
            }
        }
    }

    /// Store data and wait for disk write to complete (for testing)
    /// - Parameters:
    ///   - data: Image data
    ///   - key: Cache key
    func storeDataSync(_ data: Data, for key: String) async {
        // Load into memory cache immediately
        if let image = UIImage(data: data) {
            let nsKey = key as NSString
            let cost = image.estimatedMemorySize
            memoryCache.setObject(image, forKey: nsKey, cost: cost)
        }

        let fileURL = diskFileURL(for: key)
        await withCheckedContinuation { continuation in
            diskQueue.async {
                try? data.write(to: fileURL, options: .atomic)
                continuation.resume()
            }
        }
    }

    /// Remove an image from cache (sync - waits for disk removal)
    /// - Parameter key: Cache key
    func remove(for key: String) async {
        // Remove from memory immediately
        memoryCache.removeObject(forKey: key as NSString)

        // Remove from disk synchronously on disk queue
        let fileURL = diskFileURL(for: key)
        await withCheckedContinuation { continuation in
            diskQueue.async {
                try? FileManager.default.removeItem(at: fileURL)
                continuation.resume()
            }
        }
    }

    /// Clear all memory cache
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    /// Clear old cache entries from disk
    /// - Parameter days: Remove entries older than this many days. Default is 7
    func clearOldCache(olderThan days: Int = ImageCacheConfig.defaultExpirationDays) async {
        await withCheckedContinuation { continuation in
            diskQueue.async { [diskCacheURL] in
                guard let contents = try? FileManager.default.contentsOfDirectory(
                    at: diskCacheURL,
                    includingPropertiesForKeys: [.contentModificationDateKey],
                    options: .skipsHiddenFiles
                ) else {
                    continuation.resume()
                    return
                }

                let cutoffDate = Calendar.current.date(
                    byAdding: .day,
                    value: -days,
                    to: Date()
                ) ?? Date()

                for fileURL in contents {
                    guard let attributes = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]),
                          let modificationDate = attributes.contentModificationDate else {
                        continue
                    }

                    if modificationDate < cutoffDate {
                        try? FileManager.default.removeItem(at: fileURL)
                    }
                }
                continuation.resume()
            }
        }
    }

    /// Clear all cache (memory and disk) - waits for completion
    func clearAllCache() async {
        // Clear memory
        memoryCache.removeAllObjects()

        // Increment generation to invalidate any pending writes
        generation += 1

        // Clear disk synchronously on disk queue
        await withCheckedContinuation { continuation in
            diskQueue.async { [diskCacheURL] in
                try? FileManager.default.removeItem(at: diskCacheURL)
                try? FileManager.default.createDirectory(
                    at: diskCacheURL,
                    withIntermediateDirectories: true
                )
                continuation.resume()
            }
        }
    }

    /// Get current disk cache size in bytes
    func diskCacheSize() async -> Int {
        await withCheckedContinuation { continuation in
            diskQueue.async { [diskCacheURL] in
                guard let contents = try? FileManager.default.contentsOfDirectory(
                    at: diskCacheURL,
                    includingPropertiesForKeys: [.fileSizeKey],
                    options: .skipsHiddenFiles
                ) else {
                    continuation.resume(returning: 0)
                    return
                }

                var totalSize = 0
                for fileURL in contents {
                    if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        totalSize += size
                    }
                }
                continuation.resume(returning: totalSize)
            }
        }
    }

    // MARK: - Disk Operations

    /// Generate disk file URL for a cache key using SHA256 hash
    private nonisolated func diskFileURL(for key: String) -> URL {
        // Use SHA256 hash for fixed-length, safe filenames
        let keyData = Data(key.utf8)
        let hash = SHA256.hash(data: keyData)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()

        return diskCacheURL.appendingPathComponent(hashString)
    }
}

// MARK: - Convenience Extensions
extension ImageCache {
    /// Load image from path (file system or cache)
    /// - Parameter path: Relative path to image (e.g., "analysis_photos/uuid.jpg")
    /// - Returns: Loaded image
    func loadImage(fromPath path: String) -> UIImage? {
        // Check cache first
        if let cached = image(for: path) {
            return cached
        }

        // Load from file system (on disk queue for consistency)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(path)

        let result: (data: Data, image: UIImage)? = diskQueue.sync {
            guard let data = try? Data(contentsOf: fileURL),
                  let image = UIImage(data: data) else {
                return nil
            }
            return (data, image)
        }

        guard let (data, image) = result else {
            return nil
        }

        // Cache the original data for future access (avoids re-encoding)
        storeData(data, for: path)

        return image
    }

    /// Preload images into cache
    /// - Parameter paths: Array of image paths to preload
    func preloadImages(paths: [String]) {
        for path in paths {
            _ = loadImage(fromPath: path)
        }
    }

    /// Generate thumbnail path from image path (extension-safe)
    /// - Parameter path: Original image path
    /// - Returns: Thumbnail path with _thumb suffix before extension
    static func thumbnailPath(for path: String) -> String {
        // Find the last dot for extension
        guard let dotIndex = path.lastIndex(of: ".") else {
            // No extension, just append _thumb
            return path + "_thumb"
        }

        let nameWithoutExt = String(path[..<dotIndex])
        let ext = String(path[path.index(after: dotIndex)...])

        return "\(nameWithoutExt)_thumb.\(ext)"
    }
}

// MARK: - Test Helpers
extension ImageCache {
    /// Reset cache (for testing) - awaitable
    func reset() async {
        await clearAllCache()
    }

    /// Check if key exists in memory cache
    func isInMemoryCache(key: String) -> Bool {
        memoryCache.object(forKey: key as NSString) != nil
    }

    /// Check if key exists on disk (serialized through disk queue)
    func isOnDisk(key: String) -> Bool {
        let fileURL = diskFileURL(for: key)
        return diskQueue.sync {
            FileManager.default.fileExists(atPath: fileURL.path)
        }
    }

    /// Flush all pending disk writes (for testing)
    func flush() async {
        await withCheckedContinuation { continuation in
            diskQueue.async {
                continuation.resume()
            }
        }
    }
}
