# fn-13-tl5: 性能优化 - Performance Optimization

## Problem Statement
代码审查发现多个性能瓶颈：
1. **无分页加载**: @Query 一次加载所有数据，大量CheckIn时UI卡顿
2. **SkinMatcher无批处理**: 逐条处理皮肤数据，AI调用效率低
3. **网络无重试**: 请求失败直接报错，无智能重试机制
4. **图片未优化**: 大图直接存储和显示，内存占用高

**用户痛点**: "用久了app变卡"、"加载很慢"

## Scope
- 数据加载分页
- SkinMatcher 批处理优化
- 网络请求重试策略
- 图片压缩与缓存

## Approach

### Task 1: 分页加载
```swift
// 现状: 一次加载全部
@Query private var checkIns: [CheckIn]

// 目标: 分页加载
@Query(sort: \CheckIn.date, order: .reverse)
private var checkIns: [CheckIn]

// 使用 fetchLimit + offset
// 或虚拟化列表 (LazyVStack + onAppear)
```

### Task 2: SkinMatcher 批处理
```swift
// 现状: 单条处理
func findSkinTwins(for analysis: SkinAnalysis) async -> [SkinTwin]

// 目标: 批量处理
func findSkinTwinsBatch(for analyses: [SkinAnalysis]) async -> [[SkinTwin]]

// 合并AI请求，减少网络往返
```

### Task 3: 网络重试
```swift
// 实现指数退避重试
struct RetryPolicy {
    let maxAttempts: Int = 3
    let baseDelay: TimeInterval = 1.0
    let maxDelay: TimeInterval = 30.0

    func delay(for attempt: Int) -> TimeInterval {
        min(baseDelay * pow(2.0, Double(attempt)), maxDelay)
    }
}
```

### Task 4: 图片优化
- 存储前压缩
- 缩略图生成
- 内存缓存 (NSCache)
- 磁盘缓存策略

## Quick commands
```bash
xcodebuild build -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17'
xcodebuild test -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SkinLabTests/PerformanceTests
```

## Acceptance
- [ ] CheckIn列表支持分页或虚拟化
- [ ] 100+ CheckIn时滚动流畅 (60fps)
- [ ] SkinMatcher 支持批量处理
- [ ] AI请求合并减少50%以上
- [ ] 网络请求有自动重试
- [ ] 重试使用指数退避
- [ ] 图片存储前压缩
- [ ] 内存中有图片缓存

## Key Files
- `/SkinLab/Features/Tracking/Views/TrackingView.swift` - CheckIn列表
- `/SkinLab/Features/Tracking/Views/TrackingReportView.swift` - 数据加载
- `/SkinLab/Core/Network/SkinMatcher.swift` - 皮肤匹配
- `/SkinLab/Core/Network/GeminiService.swift` - AI服务
- `/SkinLab/Core/Utils/ImageUtils.swift` - 图片处理

## Technical Details

### 虚拟化列表
```swift
struct CheckInListView: View {
    @Query(sort: \CheckIn.date, order: .reverse)
    private var allCheckIns: [CheckIn]

    @State private var displayedCount = 20

    var body: some View {
        LazyVStack {
            ForEach(allCheckIns.prefix(displayedCount)) { checkIn in
                CheckInRow(checkIn: checkIn)
                    .onAppear {
                        if checkIn == allCheckIns.prefix(displayedCount).last {
                            loadMore()
                        }
                    }
            }
        }
    }

    private func loadMore() {
        displayedCount += 20
    }
}
```

### 网络重试封装
```swift
actor NetworkClient {
    func request<T: Decodable>(
        _ endpoint: Endpoint,
        retryPolicy: RetryPolicy = .default
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0..<retryPolicy.maxAttempts {
            do {
                return try await performRequest(endpoint)
            } catch {
                lastError = error
                if !error.isRetryable { throw error }
                try await Task.sleep(for: .seconds(retryPolicy.delay(for: attempt)))
            }
        }

        throw lastError ?? NetworkError.unknown
    }
}

extension Error {
    var isRetryable: Bool {
        // 网络超时、5xx错误可重试
        // 4xx错误不重试
    }
}
```

### 图片压缩
```swift
extension UIImage {
    func compressed(quality: CGFloat = 0.7, maxDimension: CGFloat = 1024) -> Data? {
        let ratio = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resized?.jpegData(compressionQuality: quality)
    }
}
```

### 图片缓存
```swift
actor ImageCache {
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default

    func image(for key: String) async -> UIImage? {
        // 1. 内存缓存
        if let cached = cache.object(forKey: key as NSString) {
            return cached
        }

        // 2. 磁盘缓存
        if let diskImage = await loadFromDisk(key: key) {
            cache.setObject(diskImage, forKey: key as NSString)
            return diskImage
        }

        return nil
    }

    func store(_ image: UIImage, for key: String) async {
        cache.setObject(image, forKey: key as NSString)
        await saveToDisk(image, key: key)
    }
}
```

## Risks & Mitigations
| 风险 | 缓解措施 |
|------|----------|
| 分页边界问题 | 使用cursor而非offset |
| 批处理失败回退 | 支持单条重试 |
| 缓存过期 | LRU淘汰 + TTL |
| 重试风暴 | 全局重试限制 |

## Dependencies
- Foundation NSCache
- URLSession with retry
- Core Graphics (图片处理)

## References
- `GeminiService.swift` - 现有网络模式
- `ImageUtils.swift` - 现有图片处理
- Apple WWDC - SwiftData Performance
