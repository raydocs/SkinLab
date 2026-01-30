import CryptoKit
import UIKit

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

// MARK: - Pending Write Token

/// Token to track and cancel pending disk writes
private final class WriteToken: @unchecked Sendable {
    private let lock = NSLock()
    private var _cancelled = false

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _cancelled
    }

    func cancel() {
        lock.lock()
        _cancelled = true
        lock.unlock()
    }
}

// MARK: - Image Cache

/// Thread-safe image cache with memory (NSCache) and disk layers.
/// All disk I/O is serialized through a single dispatch queue with no spawned Tasks.
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

    /// Pending write tokens by key - allows cancellation
    private var pendingTokens: [String: WriteToken] = [:]

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

    /// Retrieve an image from cache (memory first, then disk) - async
    /// - Parameter key: Cache key (typically the image path or identifier)
    /// - Returns: Cached image, or nil if not found
    func image(for key: String) async -> UIImage? {
        let nsKey = key as NSString

        // 1. Check memory cache first (fast path)
        if let cached = memoryCache.object(forKey: nsKey) {
            return cached
        }

        // 2. Check disk cache - async to avoid blocking actor
        let fileURL = diskFileURL(for: key)
        let diskImage: UIImage? = await withCheckedContinuation { continuation in
            diskQueue.async {
                guard let data = try? Data(contentsOf: fileURL) else {
                    continuation.resume(returning: nil)
                    return
                }
                // Update modification date on access (for LRU-like behavior)
                try? FileManager.default.setAttributes(
                    [.modificationDate: Date()],
                    ofItemAtPath: fileURL.path
                )
                continuation.resume(returning: UIImage(data: data))
            }
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

        // Create cancellable token for this write
        let token = WriteToken()
        pendingTokens[key] = token

        let fileURL = diskFileURL(for: key)

        // All I/O happens directly on diskQueue (no Task spawning)
        diskQueue.async {
            // Check if cancelled before writing
            guard !token.isCancelled else { return }

            if let data = image.jpegData(compressionQuality: 0.8) {
                // Check again after encoding (in case cancelled during encode)
                guard !token.isCancelled else { return }
                try? data.write(to: fileURL, options: .atomic)
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

        // Create cancellable token
        let token = WriteToken()
        pendingTokens[key] = token

        let fileURL = diskFileURL(for: key)

        // All I/O happens directly on diskQueue
        diskQueue.async {
            guard !token.isCancelled else { return }
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    /// Store data and wait for disk write to complete
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

        // No token needed for sync - we wait for completion
        let fileURL = diskFileURL(for: key)
        await withCheckedContinuation { continuation in
            diskQueue.async {
                try? data.write(to: fileURL, options: .atomic)
                continuation.resume()
            }
        }
    }

    /// Remove an image from cache - waits for disk removal
    /// - Parameter key: Cache key
    func remove(for key: String) async {
        // Remove from memory immediately
        memoryCache.removeObject(forKey: key as NSString)

        // Cancel any pending write for this key
        pendingTokens[key]?.cancel()
        pendingTokens.removeValue(forKey: key)

        // Remove from disk on queue
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

        // Cancel ALL pending writes
        for (_, token) in pendingTokens {
            token.cancel()
        }
        pendingTokens.removeAll()

        // Clear disk on queue
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
    /// Load image from path (file system or cache) - async
    /// - Parameter path: Relative path to image (e.g., "analysis_photos/uuid.jpg")
    /// - Returns: Loaded image
    func loadImage(fromPath path: String) async -> UIImage? {
        // Check cache first
        if let cached = await image(for: path) {
            return cached
        }

        // Load from file system on disk queue
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(path)

        let result: (data: Data, image: UIImage)? = await withCheckedContinuation { continuation in
            diskQueue.async {
                guard let data = try? Data(contentsOf: fileURL),
                      let image = UIImage(data: data) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: (data, image))
            }
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
    func preloadImages(paths: [String]) async {
        for path in paths {
            _ = await loadImage(fromPath: path)
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

    /// Check if key exists on disk (async, serialized through disk queue)
    func isOnDisk(key: String) async -> Bool {
        let fileURL = diskFileURL(for: key)
        return await withCheckedContinuation { continuation in
            diskQueue.async {
                continuation.resume(returning: FileManager.default.fileExists(atPath: fileURL.path))
            }
        }
    }

    /// Flush all pending disk operations (for testing)
    func flush() async {
        await withCheckedContinuation { continuation in
            diskQueue.async {
                continuation.resume()
            }
        }
    }
}
