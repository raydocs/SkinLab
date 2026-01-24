# fn-13-tl5.4 图片压缩与缓存

## Description
实现图片压缩和缓存机制，减少存储占用和加载时间。

**当前问题**: 大图直接存储和显示，内存占用高。

**目标**:
1. 存储前压缩
2. 生成缩略图
3. 内存缓存(NSCache)
4. 磁盘缓存策略

## Key Files
- `/SkinLab/Core/Utils/ImageUtils.swift` - 图片处理
- 新建 `/SkinLab/Core/Utils/ImageCache.swift` - 图片缓存

## Implementation Notes
```swift
// 图片压缩
extension UIImage {
    func compressed(
        quality: CGFloat = 0.7,
        maxDimension: CGFloat = 1024
    ) -> Data? {
        let ratio = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resized?.jpegData(compressionQuality: quality)
    }

    func thumbnail(size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// 图片缓存
actor ImageCache {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCacheURL: URL

    init() {
        diskCacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ImageCache")
        memoryCache.countLimit = 50
    }

    func image(for key: String) async -> UIImage? {
        // 1. 内存缓存
        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached
        }

        // 2. 磁盘缓存
        if let diskImage = await loadFromDisk(key: key) {
            memoryCache.setObject(diskImage, forKey: key as NSString)
            return diskImage
        }

        return nil
    }

    func store(_ image: UIImage, for key: String) async {
        memoryCache.setObject(image, forKey: key as NSString)
        await saveToDisk(image, key: key)
    }

    func clearOldCache(olderThan days: Int = 7) async {
        // 清理超过7天的缓存
    }
}
```

## Acceptance
- [ ] 图片存储前压缩
- [ ] 支持生成缩略图
- [ ] 内存缓存工作正常
- [ ] 磁盘缓存工作正常
- [ ] 缓存有过期清理
- [ ] 单元测试覆盖缓存逻辑

## Quick Commands
```bash
xcodebuild test -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Done summary
Implemented image compression and caching system with actor-based ImageCache (memory + disk layers), UIImage compression/thumbnail extensions, and SwiftUI CachedImageView components. Includes 27 unit tests and integration with AnalysisViewModel.
## Evidence
- Commits: b336115375b3157b7ca4ce6af8e683938ac9441e, 94f21c7
- Tests: xcodebuild test -scheme SkinLab -only-testing:SkinLabTests/ImageCacheTests
- PRs: