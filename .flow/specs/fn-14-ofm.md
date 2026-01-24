# fn-14-ofm: 代码健壮性增强 - Code Robustness

## Problem Statement
代码审查发现多个影响应用稳定性的关键问题：
1. **fatalError崩溃**: SwiftData初始化失败直接崩溃，无优雅降级
2. **静默失败**: 50+处使用`try?`静默忽略错误，导致数据丢失和隐藏bug
3. **调试代码泄漏**: 多处`print()`语句遗留在生产代码中
4. **内存泄漏风险**: DispatchQueue回调缺少`[weak self]`
5. **配置分散**: URL和API密钥硬编码在多个文件中

**用户痛点**: "App有时候莫名其妙不工作"、"数据丢失了但没有任何提示"

## Scope
- 替换fatalError为优雅降级
- 统一错误处理策略
- 移除调试print语句
- 修复内存泄漏风险
- 中心化配置管理

## Approach

### Task 1: fatalError替换为优雅降级
```swift
// SkinLabApp.swift:32 现状
fatalError("Could not create ModelContainer: \(error)")

// 目标：优雅降级
do {
    container = try ModelContainer(for: schema, configurations: [config])
} catch {
    // 1. 记录错误
    Logger.error("ModelContainer init failed: \(error)")
    // 2. 尝试重置
    container = try? ModelContainer(for: schema, configurations: [resetConfig])
    // 3. 显示恢复UI
    showRecoveryAlert = true
}
```

### Task 2: 统一错误处理策略
```swift
// 现状：静默失败
let records = (try? modelContext.fetch(descriptor)) ?? []

// 目标：统一模式
enum AppError: LocalizedError {
    case dataFetch(underlying: Error)
    case dataSave(underlying: Error)
    case networkRequest(underlying: Error)
}

// 使用Result类型或throws
func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] {
    do {
        return try modelContext.fetch(descriptor)
    } catch {
        Logger.error("Fetch failed: \(error)")
        throw AppError.dataFetch(underlying: error)
    }
}
```

### Task 3: 移除调试print语句
- WeatherCardView.swift:482,488 - `print("Tapped")`, `print("Retry")`
- StreakBadgeView.swift:157,168,179 - `print("Freeze tapped")`
- 其他散落的print语句

### Task 4: 修复内存泄漏
```swift
// 现状：缺少weak self
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    self.showAnimation = true  // 潜在循环引用
}

// 目标：添加[weak self]
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
    self?.showAnimation = true
}
```

### Task 5: 配置管理中心化
```swift
// 新建 AppConfiguration.swift
enum AppConfiguration {
    enum Environment {
        case development
        case staging
        case production
    }

    static var current: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    static var geminiBaseURL: String {
        switch current {
        case .development: return "https://openrouter.ai/api/v1"
        case .staging: return "https://staging-api.example.com"
        case .production: return "https://openrouter.ai/api/v1"
        }
    }

    static var appReferer: String {
        "https://skinlab.app"
    }
}
```

## Quick commands
```bash
xcodebuild build -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17'
xcodebuild test -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Acceptance
- [ ] App启动失败时显示恢复选项而非崩溃
- [ ] 所有try?替换为适当的错误处理
- [ ] 无调试print语句残留
- [ ] 所有异步回调使用[weak self]
- [ ] URL和配置集中管理
- [ ] 单元测试覆盖错误处理路径

## Key Files
- `/SkinLab/App/SkinLabApp.swift:32` - fatalError
- `/SkinLab/Features/Community/ViewModels/SkinTwinViewModel.swift` - 大量try?
- `/SkinLab/Features/Engagement/Services/AchievementService.swift` - try?
- `/SkinLab/Core/Utils/UserHistoryStore.swift` - try?
- `/SkinLab/Features/Weather/Views/WeatherCardView.swift:482,488` - print
- `/SkinLab/Features/Engagement/Views/StreakBadgeView.swift:157,168,179` - print
- `/SkinLab/Core/Network/GeminiService.swift:7,194,567` - 硬编码URL

## Technical Details

### 错误处理层级
1. **Service层**: throw具体错误类型
2. **ViewModel层**: catch并转换为用户友好消息
3. **View层**: 显示错误UI

### Logger实现
```swift
import os.log

enum Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.skinlab"

    static func error(_ message: String, file: String = #file, function: String = #function) {
        os_log(.error, log: OSLog(subsystem: subsystem, category: "Error"), "%{public}@", message)
        #if DEBUG
        print("❌ [\(file):\(function)] \(message)")
        #endif
    }

    static func info(_ message: String) {
        os_log(.info, log: OSLog(subsystem: subsystem, category: "Info"), "%{public}@", message)
    }
}
```

## Risks & Mitigations
| 风险 | 缓解措施 |
|------|----------|
| 改动范围大 | 分批修改，每个文件单独提交 |
| 可能引入新bug | 每次修改后运行完整测试 |
| 错误处理过度 | 只在关键路径添加，非关键保持简单 |

## Dependencies
- os.log framework
- Swift Concurrency (async/await)

## References
- `GeminiService.swift:7` - baseURL硬编码
- `SkinLabApp.swift:32` - fatalError位置
- Apple WWDC - Unified Logging
