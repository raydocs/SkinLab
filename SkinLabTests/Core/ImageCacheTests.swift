//
//  ImageCacheTests.swift
//  SkinLabTests
//
//  Unit tests for ImageCache and ImageUtils.
//

import XCTest
@testable import SkinLab

final class ImageCacheTests: XCTestCase {

    var testCache: ImageCache!

    override func setUp() async throws {
        try await super.setUp()
        // Create a fresh cache instance for each test
        testCache = ImageCache()
        await testCache.reset()
    }

    override func tearDown() async throws {
        await testCache.reset()
        testCache = nil
        try await super.tearDown()
    }

    // MARK: - Image Compression Tests

    func testImageCompressionReducesSize() {
        // Create a test image (note: UIGraphicsImageRenderer creates images at screen scale)
        let testImage = createTestImage(size: CGSize(width: 2000, height: 2000))

        // Compress the image
        let compressedData = testImage.compressed(quality: 0.5, maxDimension: 1024)

        XCTAssertNotNil(compressedData, "Compressed data should not be nil")

        // Verify the compression actually produces data
        if let data = compressedData, let compressedImage = UIImage(data: data) {
            // Original pixel dimensions = size.width * scale
            let originalPixelWidth = testImage.size.width * testImage.scale
            // Compressed pixel dimensions
            let compressedPixelWidth = compressedImage.size.width * compressedImage.scale

            // Compressed should be <= maxDimension (1024) in pixel terms
            XCTAssertLessThanOrEqual(
                compressedPixelWidth,
                1024,
                "Compressed image should have pixel width <= maxDimension"
            )

            // Data size should be reasonable (smaller than uncompressed RGBA)
            let uncompressedSize = Int(originalPixelWidth * testImage.size.height * testImage.scale) * 4
            XCTAssertLessThan(
                data.count,
                uncompressedSize,
                "Compressed data should be smaller than uncompressed RGBA"
            )
        }
    }

    func testImageCompressionPreservesAspectRatio() {
        // Create a non-square test image
        let testImage = createTestImage(size: CGSize(width: 3000, height: 2000))

        let compressedData = testImage.compressed(maxDimension: 1000)

        XCTAssertNotNil(compressedData)

        if let data = compressedData, let compressedImage = UIImage(data: data) {
            let originalRatio = testImage.size.width / testImage.size.height
            let compressedRatio = compressedImage.size.width / compressedImage.size.height

            XCTAssertEqual(
                originalRatio,
                compressedRatio,
                accuracy: 0.01,
                "Aspect ratio should be preserved"
            )
        }
    }

    func testCompressionQualityClamping() {
        let testImage = createTestImage(size: CGSize(width: 100, height: 100))

        // Test that invalid quality values are clamped
        let lowQualityData = testImage.compressed(quality: -0.5)
        let highQualityData = testImage.compressed(quality: 1.5)

        XCTAssertNotNil(lowQualityData, "Should handle negative quality")
        XCTAssertNotNil(highQualityData, "Should handle quality > 1")
    }

    func testCompressionWithQualityPreset() {
        let testImage = createTestImage(size: CGSize(width: 500, height: 500))

        let lowData = testImage.compressed(preset: .low)
        let mediumData = testImage.compressed(preset: .medium)
        let highData = testImage.compressed(preset: .high)

        XCTAssertNotNil(lowData)
        XCTAssertNotNil(mediumData)
        XCTAssertNotNil(highData)

        // Higher quality should generally produce larger files
        // (not guaranteed but usually true for same content)
        if let low = lowData, let high = highData {
            // Low quality data should typically be smaller
            XCTAssertLessThanOrEqual(low.count, high.count * 2)
        }
    }

    func testSmallImageNotResized() {
        // Create an image smaller than maxDimension in actual pixels
        // At 3x scale, 300 points = 900 pixels, which is less than 1024
        let smallImage = createTestImage(size: CGSize(width: 300, height: 300))

        let compressedData = smallImage.compressed(maxDimension: 1024)

        XCTAssertNotNil(compressedData)

        if let data = compressedData, let compressed = UIImage(data: data) {
            // Image should retain approximately the same pixel dimensions
            let expectedPixels = smallImage.size.width * smallImage.scale
            let compressedPixels = compressed.size.width * compressed.scale
            XCTAssertEqual(compressedPixels, expectedPixels, accuracy: expectedPixels * 0.1)
        }
    }

    // MARK: - Thumbnail Tests

    func testThumbnailGeneration() {
        let testImage = createTestImage(size: CGSize(width: 1000, height: 1000))

        let thumbnail = testImage.thumbnail(size: CGSize(width: 200, height: 200))

        XCTAssertNotNil(thumbnail)

        if let thumb = thumbnail {
            XCTAssertLessThanOrEqual(thumb.size.width, 200)
            XCTAssertLessThanOrEqual(thumb.size.height, 200)
        }
    }

    func testThumbnailPreservesAspectRatio() {
        // Non-square image
        let testImage = createTestImage(size: CGSize(width: 1600, height: 900))

        let thumbnail = testImage.thumbnail(size: CGSize(width: 200, height: 200))

        XCTAssertNotNil(thumbnail)

        if let thumb = thumbnail {
            let originalRatio = testImage.size.width / testImage.size.height
            let thumbRatio = thumb.size.width / thumb.size.height

            XCTAssertEqual(
                originalRatio,
                thumbRatio,
                accuracy: 0.01,
                "Thumbnail should preserve aspect ratio"
            )
        }
    }

    func testThumbnailData() {
        let testImage = createTestImage(size: CGSize(width: 500, height: 500))

        let thumbnailData = testImage.thumbnailData(
            size: CGSize(width: 100, height: 100),
            quality: 0.8
        )

        XCTAssertNotNil(thumbnailData)
        XCTAssertGreaterThan(thumbnailData?.count ?? 0, 0)
    }

    // MARK: - Memory Size Tests

    func testEstimatedMemorySize() {
        let testImage = createTestImage(size: CGSize(width: 100, height: 100))

        let memorySize = testImage.estimatedMemorySize

        // 100x100 points * scale^2 * 4 bytes per pixel (RGBA)
        // UIGraphicsImageRenderer creates images at screen scale
        let scale = Int(testImage.scale)
        let expectedSize = 100 * scale * 100 * scale * 4
        XCTAssertEqual(memorySize, expectedSize)
    }

    // MARK: - Cache Storage Tests

    func testCacheStoreAndRetrieve() async {
        let testImage = createTestImage(size: CGSize(width: 100, height: 100))
        let key = "test-image-\(UUID().uuidString)"

        await testCache.store(testImage, for: key)

        // Allow disk write to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let retrieved = await testCache.image(for: key)

        XCTAssertNotNil(retrieved, "Should retrieve stored image")
    }

    func testCacheReturnsNilForMissingKey() async {
        let result = await testCache.image(for: "non-existent-key")
        XCTAssertNil(result, "Should return nil for missing key")
    }

    func testCacheRemove() async {
        let testImage = createTestImage(size: CGSize(width: 100, height: 100))
        let key = "remove-test-\(UUID().uuidString)"

        await testCache.store(testImage, for: key)

        // Allow disk write to complete
        try? await Task.sleep(nanoseconds: 100_000_000)

        await testCache.remove(for: key)

        // Allow disk removal to complete
        try? await Task.sleep(nanoseconds: 50_000_000)

        let retrieved = await testCache.image(for: key)
        XCTAssertNil(retrieved, "Should return nil after removal")
    }

    func testMemoryCacheCheck() async {
        let testImage = createTestImage(size: CGSize(width: 100, height: 100))
        let key = "memory-test-\(UUID().uuidString)"

        await testCache.store(testImage, for: key)

        let isInMemory = await testCache.isInMemoryCache(key: key)
        XCTAssertTrue(isInMemory, "Image should be in memory cache")
    }

    func testDiskCacheCheck() async {
        let testImage = createTestImage(size: CGSize(width: 100, height: 100))
        let key = "disk-test-\(UUID().uuidString)"

        await testCache.store(testImage, for: key)

        // Allow disk write to complete
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        let isOnDisk = await testCache.isOnDisk(key: key)
        XCTAssertTrue(isOnDisk, "Image should be on disk")
    }

    func testClearMemoryCache() async {
        let testImage = createTestImage(size: CGSize(width: 100, height: 100))
        let key = "clear-memory-test-\(UUID().uuidString)"

        await testCache.store(testImage, for: key)
        await testCache.clearMemoryCache()

        let isInMemory = await testCache.isInMemoryCache(key: key)
        XCTAssertFalse(isInMemory, "Memory cache should be cleared")

        // Allow disk write
        try? await Task.sleep(nanoseconds: 100_000_000)

        // But disk should still have it
        let isOnDisk = await testCache.isOnDisk(key: key)
        XCTAssertTrue(isOnDisk, "Disk cache should still have image")
    }

    func testClearAllCache() async {
        let testImage = createTestImage(size: CGSize(width: 100, height: 100))
        let key = "clear-all-test-\(UUID().uuidString)"

        await testCache.store(testImage, for: key)

        // Allow disk write
        try? await Task.sleep(nanoseconds: 100_000_000)

        await testCache.clearAllCache()

        // Allow clearing to complete
        try? await Task.sleep(nanoseconds: 50_000_000)

        let isInMemory = await testCache.isInMemoryCache(key: key)
        let isOnDisk = await testCache.isOnDisk(key: key)

        XCTAssertFalse(isInMemory, "Memory cache should be cleared")
        XCTAssertFalse(isOnDisk, "Disk cache should be cleared")
    }

    func testDiskCacheSize() async {
        await testCache.clearAllCache()

        let initialSize = await testCache.diskCacheSize()
        XCTAssertEqual(initialSize, 0, "Initial disk cache should be empty")

        let testImage = createTestImage(size: CGSize(width: 200, height: 200))
        await testCache.store(testImage, for: "size-test-1")
        await testCache.store(testImage, for: "size-test-2")

        // Allow disk writes
        try? await Task.sleep(nanoseconds: 200_000_000)

        let newSize = await testCache.diskCacheSize()
        XCTAssertGreaterThan(newSize, 0, "Disk cache should have content")
    }

    func testStoreData() async {
        let testImage = createTestImage(size: CGSize(width: 100, height: 100))
        let data = testImage.jpegData(compressionQuality: 0.8)!
        let key = "data-test-\(UUID().uuidString)"

        await testCache.storeData(data, for: key)

        // Allow disk write
        try? await Task.sleep(nanoseconds: 100_000_000)

        let retrieved = await testCache.image(for: key)
        XCTAssertNotNil(retrieved, "Should retrieve image stored as data")
    }

    // MARK: - Data Extension Tests

    func testDataAsImage() {
        let testImage = createTestImage(size: CGSize(width: 100, height: 100))
        let data = testImage.jpegData(compressionQuality: 0.8)!

        let result = data.asImage

        XCTAssertNotNil(result, "Data.asImage should create UIImage")
    }

    func testInvalidDataAsImage() {
        let invalidData = Data([0x00, 0x01, 0x02, 0x03])

        let result = invalidData.asImage

        XCTAssertNil(result, "Invalid data should return nil")
    }

    // MARK: - Helpers

    /// Create a test image with solid color
    private func createTestImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Fill with a random color for variety
            UIColor(
                red: CGFloat.random(in: 0...1),
                green: CGFloat.random(in: 0...1),
                blue: CGFloat.random(in: 0...1),
                alpha: 1.0
            ).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Add some pattern to make compression more realistic
            UIColor.white.setStroke()
            for i in stride(from: 0, to: size.width, by: 20) {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: i, y: 0))
                path.addLine(to: CGPoint(x: i, y: size.height))
                path.stroke()
            }
        }
    }
}
