//
//  ImageCache.swift
//  SkinLab
//
//  Thread-safe image caching with memory and disk layers.
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

// MARK: - Disk I/O Queue
/// Dedicated queue for disk operations to avoid blocking actor
private let diskIOQueue = DispatchQueue(label: "com.skinlab.imagecache.diskio", qos: .utility)

// MARK: - Image Cache
actor ImageCache {
    /// Shared singleton instance
    static let shared = ImageCache()

    // MARK: - Private Properties

    /// Memory cache using NSCache (thread-safe internally)
    private let memoryCache: NSCache<NSString, UIImage>

    /// Disk cache directory URL
    private let diskCacheURL: URL

    /// File manager for disk operations
    private let fileManager: FileManager

    /// Track pending disk writes for removal coordination
    private var pendingWrites: Set<String> = []

    // MARK: - Initialization

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        // Configure memory cache
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = ImageCacheConfig.memoryCacheLimit
        cache.totalCostLimit = ImageCacheConfig.memoryCostLimit
        self.memoryCache = cache

        // Setup disk cache directory
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.diskCacheURL = cacheDir.appendingPathComponent(
            ImageCacheConfig.diskCacheDirectory,
            isDirectory: true
        )

        // Create disk cache directory if needed
        try? fileManager.createDirectory(
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

        // 1. Check memory cache first
        if let cached = memoryCache.object(forKey: nsKey) {
            return cached
        }

        // 2. Check disk cache (synchronous read on actor is acceptable for cache hits)
        if let diskImage = loadFromDisk(key: key) {
            // Promote to memory cache
            let cost = diskImage.estimatedMemorySize
            memoryCache.setObject(diskImage, forKey: nsKey, cost: cost)
            return diskImage
        }

        return nil
    }

    /// Store an image in cache (both memory and disk)
    /// - Parameters:
    ///   - image: Image to cache
    ///   - key: Cache key
    func store(_ image: UIImage, for key: String) {
        let nsKey = key as NSString
        let cost = image.estimatedMemorySize

        // Store in memory
        memoryCache.setObject(image, forKey: nsKey, cost: cost)

        // Encode image off-actor, then write to disk
        pendingWrites.insert(key)
        let fileURL = diskFileURL(for: key)

        diskIOQueue.async { [weak self] in
            guard let data = image.jpegData(compressionQuality: 0.8) else {
                Task { await self?.removePendingWrite(key) }
                return
            }
            try? data.write(to: fileURL, options: .atomic)
            Task { await self?.removePendingWrite(key) }
        }
    }

    /// Store image data directly (more efficient if you already have Data)
    /// - Parameters:
    ///   - data: Image data (JPEG/PNG)
    ///   - key: Cache key
    func storeData(_ data: Data, for key: String) {
        // Load into memory cache
        if let image = UIImage(data: data) {
            let nsKey = key as NSString
            let cost = image.estimatedMemorySize
            memoryCache.setObject(image, forKey: nsKey, cost: cost)
        }

        // Write data directly to disk on background queue
        pendingWrites.insert(key)
        let fileURL = diskFileURL(for: key)

        diskIOQueue.async { [weak self] in
            try? data.write(to: fileURL, options: .atomic)
            Task { await self?.removePendingWrite(key) }
        }
    }

    /// Remove an image from cache
    /// - Parameter key: Cache key
    func remove(for key: String) {
        // Remove from memory
        memoryCache.removeObject(forKey: key as NSString)

        // Cancel pending write if any
        pendingWrites.remove(key)

        // Remove from disk synchronously to ensure removal completes
        let fileURL = diskFileURL(for: key)
        try? fileManager.removeItem(at: fileURL)
    }

    /// Clear all memory cache
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    /// Clear old cache entries from disk
    /// - Parameter days: Remove entries older than this many days. Default is 7
    func clearOldCache(olderThan days: Int = ImageCacheConfig.defaultExpirationDays) {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: diskCacheURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else {
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
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }

    /// Clear all cache (memory and disk)
    func clearAllCache() {
        // Clear memory
        memoryCache.removeAllObjects()

        // Cancel all pending writes
        pendingWrites.removeAll()

        // Clear disk synchronously
        try? fileManager.removeItem(at: diskCacheURL)
        try? fileManager.createDirectory(
            at: diskCacheURL,
            withIntermediateDirectories: true
        )
    }

    /// Get current disk cache size in bytes
    func diskCacheSize() -> Int {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: diskCacheURL,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        ) else {
            return 0
        }

        var totalSize = 0
        for fileURL in contents {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += size
            }
        }

        return totalSize
    }

    // MARK: - Private Helpers

    private func removePendingWrite(_ key: String) {
        pendingWrites.remove(key)
    }

    // MARK: - Disk Operations

    /// Generate disk file URL for a cache key using SHA256 hash
    private func diskFileURL(for key: String) -> URL {
        // Use SHA256 hash for fixed-length, safe filenames
        let keyData = Data(key.utf8)
        let hash = SHA256.hash(data: keyData)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()

        return diskCacheURL.appendingPathComponent(hashString)
    }

    /// Load image from disk cache
    private func loadFromDisk(key: String) -> UIImage? {
        let fileURL = diskFileURL(for: key)

        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        // Update modification date on access (for LRU-like behavior)
        try? fileManager.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: fileURL.path
        )

        return UIImage(data: data)
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

        // Load from file system
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(path)

        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
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
    /// Reset cache (for testing)
    func reset() {
        clearAllCache()
    }

    /// Check if key exists in memory cache
    func isInMemoryCache(key: String) -> Bool {
        memoryCache.object(forKey: key as NSString) != nil
    }

    /// Check if key exists on disk
    func isOnDisk(key: String) -> Bool {
        let fileURL = diskFileURL(for: key)
        return fileManager.fileExists(atPath: fileURL.path)
    }
}
