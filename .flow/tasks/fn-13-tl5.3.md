# fn-13-tl5.3 网络请求重试策略

## Description
实现智能网络重试策略，提高请求成功率。

**当前问题**: 网络请求失败直接报错，无重试机制。

**目标**:
1. 指数退避重试
2. 可重试错误识别
3. 最大重试次数限制
4. 全局重试限制防止风暴

## Key Files
- `/SkinLab/Core/Network/GeminiService.swift` - AI服务
- `/SkinLab/Core/Network/WeatherService.swift` - 天气服务
- 新建 `/SkinLab/Core/Network/RetryPolicy.swift` - 重试策略

## Implementation Notes
```swift
struct RetryPolicy {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval

    static let `default` = RetryPolicy(
        maxAttempts: 3,
        baseDelay: 1.0,
        maxDelay: 30.0
    )

    func delay(for attempt: Int) -> TimeInterval {
        min(baseDelay * pow(2.0, Double(attempt)), maxDelay)
    }
}

extension Error {
    var isRetryable: Bool {
        if let urlError = self as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                return true
            default:
                return false
            }
        }
        // 5xx服务端错误可重试
        if let httpResponse = (self as? HTTPError)?.response,
           (500...599).contains(httpResponse.statusCode) {
            return true
        }
        return false
    }
}

actor NetworkClient {
    func request<T: Decodable>(
        _ request: URLRequest,
        retryPolicy: RetryPolicy = .default
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0..<retryPolicy.maxAttempts {
            do {
                return try await performRequest(request)
            } catch {
                lastError = error
                guard error.isRetryable else { throw error }

                let delay = retryPolicy.delay(for: attempt)
                try await Task.sleep(for: .seconds(delay))
            }
        }

        throw lastError ?? NetworkError.unknown
    }
}
```

## Acceptance
- [ ] 实现RetryPolicy结构
- [ ] 指数退避延迟计算
- [ ] 可重试错误正确识别
- [ ] GeminiService使用重试
- [ ] WeatherService使用重试
- [ ] 单元测试覆盖重试逻辑

## Quick Commands
```bash
xcodebuild test -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SkinLabTests/NetworkTests
```

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
