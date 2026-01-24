# fn-14-ofm.2 统一错误处理策略

## Description
替换代码库中 50+ 处的 `try?` 静默失败为统一的错误处理模式，添加日志记录和用户反馈。

**当前问题**:
```swift
let records = (try? modelContext.fetch(descriptor)) ?? []  // 静默失败
try? modelContext.save()  // 可能数据丢失
```

**目标**:
1. 创建统一的 AppError 类型
2. 创建 Logger 工具类
3. 替换关键路径的 try? 为正确的错误处理
4. ViewModel 层转换为用户友好消息

## Key Files
- 新建 `/SkinLab/Core/Utils/Logger.swift` - 日志工具
- 新建 `/SkinLab/Core/Models/AppError.swift` - 错误类型
- `/SkinLab/Features/Community/ViewModels/SkinTwinViewModel.swift` - 多处try?
- `/SkinLab/Features/Engagement/Services/AchievementService.swift` - 多处try?
- `/SkinLab/Core/Utils/UserHistoryStore.swift` - 多处try?

## Implementation Notes
```swift
// AppError.swift
enum AppError: LocalizedError {
    case dataFetch(underlying: Error)
    case dataSave(underlying: Error)
    case networkRequest(underlying: Error)
    case imageProcessing(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .dataFetch: return "无法加载数据"
        case .dataSave: return "保存失败"
        case .networkRequest: return "网络请求失败"
        case .imageProcessing: return "图片处理失败"
        }
    }
}

// Logger.swift
import os.log

enum Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.skinlab"

    static func error(_ message: String, error: Error? = nil) {
        let log = OSLog(subsystem: subsystem, category: "Error")
        os_log(.error, log: log, "%{public}@: %{public}@", message, error?.localizedDescription ?? "")
    }
}

// 使用示例
do {
    let records = try modelContext.fetch(descriptor)
} catch {
    Logger.error("Fetch failed", error: error)
    throw AppError.dataFetch(underlying: error)
}
```

## Acceptance
- [ ] Logger 工具类创建
- [ ] AppError 枚举定义
- [ ] 关键路径 try? 替换完成
- [ ] 错误消息用户友好
- [ ] 错误被记录到系统日志
- [ ] 单元测试验证错误路径

## Quick Commands
```bash
xcodebuild build -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Done summary
Implemented unified error handling with AppLogger and AppError utilities. Replaced try? silent failures with proper error logging across UserHistoryStore, SkinTwinViewModel, AchievementService, and data export models. User-facing errors now show friendly Chinese messages while underlying errors are logged for debugging.
## Evidence
- Commits: 5b0cfe2, a37ff05, 026e5738e82d45c6b5c970f6c1b6a100e6397726
- Tests: ErrorHandlingTests
- PRs: