# fn-14-ofm.1 fatalError替换为优雅降级

## Description
替换 `SkinLabApp.swift:32` 的 fatalError 为优雅降级机制，当 SwiftData 初始化失败时提供恢复选项而非直接崩溃。

**当前问题**:
```swift
fatalError("Could not create ModelContainer: \(error)")
```
用户在任何初始化错误时都会看到应用崩溃。

**目标**:
1. 捕获 ModelContainer 初始化错误
2. 尝试使用默认配置重新初始化
3. 失败时显示恢复UI让用户选择
4. 记录错误日志

## Key Files
- `/SkinLab/App/SkinLabApp.swift:32` - fatalError 位置
- 新建 `/SkinLab/App/AppRecoveryView.swift` - 恢复UI

## Implementation Notes
```swift
@main
struct SkinLabApp: App {
    @State private var showRecovery = false
    @State private var recoveryError: Error?

    var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // 尝试重置
            if let resetContainer = try? ModelContainer(for: schema, configurations: [resetConfiguration]) {
                return resetContainer
            }
            // 返回最小容器，稍后显示恢复UI
            return try! ModelContainer(for: schema)
        }
    }()

    var body: some Scene {
        WindowGroup {
            if showRecovery {
                AppRecoveryView(error: recoveryError) { /* reset action */ }
            } else {
                ContentView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
```

## Acceptance
- [ ] fatalError 被移除
- [ ] 初始化失败时尝试重置
- [ ] 重置失败时显示恢复UI
- [ ] 恢复UI提供"重置数据"和"联系支持"选项
- [ ] 错误被记录到日志

## Quick Commands
```bash
xcodebuild build -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Done summary
Replaced fatalError with graceful degradation for SwiftData initialization. On failure, the app now attempts to reset store files and retry before showing a recovery UI with "Reset Data" and "Contact Support" options. All errors are logged via os.log.
## Evidence
- Commits: a3f6c0f, 7ca4622, 4db09e6, 656407d
- Tests: xcodebuild build -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17'
- PRs: