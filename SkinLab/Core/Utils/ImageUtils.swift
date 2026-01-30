import UIKit

// MARK: - Image Compression Configuration

enum ImageCompressionConfig {
    /// Default JPEG compression quality (0.7 = 70%)
    static let defaultQuality: CGFloat = 0.7

    /// Maximum dimension for compressed images (maintains aspect ratio)
    static let defaultMaxDimension: CGFloat = 1024

    /// Default thumbnail size
    static let defaultThumbnailSize = CGSize(width: 200, height: 200)

    /// Quality presets
    enum Quality {
        case low // 0.5 - smaller file size
        case medium // 0.7 - balanced
        case high // 0.85 - better quality

        var value: CGFloat {
            switch self {
            case .low: 0.5
            case .medium: 0.7
            case .high: 0.85
            }
        }
    }
}

// MARK: - UIImage Compression Extension

extension UIImage {
    /// Compress the image with optional resizing
    /// - Parameters:
    ///   - quality: JPEG compression quality (0.0-1.0). Default is 0.7
    ///   - maxDimension: Maximum width or height in pixels. Image will be scaled down if larger. Default is 1024
    /// - Returns: Compressed JPEG data, or nil if compression fails
    func compressed(
        quality: CGFloat = ImageCompressionConfig.defaultQuality,
        maxDimension: CGFloat = ImageCompressionConfig.defaultMaxDimension
    ) -> Data? {
        // Clamp quality to valid range
        let clampedQuality = max(0.0, min(1.0, quality))

        // Calculate actual pixel dimensions (size is in points, multiply by scale)
        let pixelWidth = size.width * scale
        let pixelHeight = size.height * scale

        // Check if resizing is needed based on actual pixels
        let resizedImage: UIImage
        if pixelWidth > maxDimension || pixelHeight > maxDimension {
            let ratio = min(maxDimension / pixelWidth, maxDimension / pixelHeight, 1.0)
            let newPixelSize = CGSize(
                width: (pixelWidth * ratio).rounded(),
                height: (pixelHeight * ratio).rounded()
            )

            // Use UIGraphicsImageRenderer with scale 1.0 for pixel-accurate sizing
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            let renderer = UIGraphicsImageRenderer(size: newPixelSize, format: format)
            resizedImage = renderer.image { _ in
                draw(in: CGRect(origin: .zero, size: newPixelSize))
            }
        } else {
            resizedImage = self
        }

        return resizedImage.jpegData(compressionQuality: clampedQuality)
    }

    /// Compress with quality preset
    /// - Parameters:
    ///   - preset: Quality preset (low, medium, high)
    ///   - maxDimension: Maximum dimension for the image
    /// - Returns: Compressed JPEG data
    func compressed(
        preset: ImageCompressionConfig.Quality,
        maxDimension: CGFloat = ImageCompressionConfig.defaultMaxDimension
    ) -> Data? {
        compressed(quality: preset.value, maxDimension: maxDimension)
    }

    /// Generate a thumbnail image (only downscales, never upscales)
    /// - Parameter size: Target thumbnail size in pixels. Default is 200x200
    /// - Returns: Thumbnail image, or original if already smaller than target
    func thumbnail(size: CGSize = ImageCompressionConfig.defaultThumbnailSize) -> UIImage? {
        // Calculate actual pixel dimensions
        let pixelWidth = self.size.width * scale
        let pixelHeight = self.size.height * scale

        // Calculate aspect-fit size, clamped to <= 1.0 to prevent upscaling
        let widthRatio = size.width / pixelWidth
        let heightRatio = size.height / pixelHeight
        let ratio = min(widthRatio, heightRatio, 1.0)

        // If image is already smaller than target, return self
        if ratio >= 1.0 {
            return self
        }

        let targetSize = CGSize(
            width: (pixelWidth * ratio).rounded(),
            height: (pixelHeight * ratio).rounded()
        )

        // Use UIGraphicsImageRenderer with scale 1.0 for pixel-accurate sizing
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    /// Generate thumbnail data (JPEG)
    /// - Parameters:
    ///   - size: Target thumbnail size
    ///   - quality: JPEG compression quality
    /// - Returns: Thumbnail JPEG data
    func thumbnailData(
        size: CGSize = ImageCompressionConfig.defaultThumbnailSize,
        quality: CGFloat = ImageCompressionConfig.defaultQuality
    ) -> Data? {
        thumbnail(size: size)?.jpegData(compressionQuality: quality)
    }

    /// Estimated memory size of the image (in bytes)
    var estimatedMemorySize: Int {
        let bytesPerPixel = 4 // RGBA
        return Int(size.width * scale) * Int(size.height * scale) * bytesPerPixel
    }
}

// MARK: - Data Extension for Image Loading

extension Data {
    /// Create UIImage from data
    var asImage: UIImage? {
        UIImage(data: self)
    }
}
