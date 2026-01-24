# fn-11-mqh.3 错误恢复路径

## Description
实现统一的错误处理和恢复机制，让用户在遇到错误后能够继续使用。

**当前问题**: 网络错误后用户不知如何继续，只能重启app。

**目标**:
1. 统一错误提示组件
2. 重试按钮
3. 离线模式提示
4. 错误上下文保留

## Key Files
- 新建 `/SkinLab/Core/Components/ErrorRecoveryView.swift` - 错误恢复组件
- `/SkinLab/Core/Network/GeminiService.swift` - 网络错误处理
- `/SkinLab/Features/Analysis/Views/AnalysisView.swift` - 分析错误处理

## Implementation Notes
```swift
struct ErrorRecoveryView: View {
    let error: Error
    let retryAction: () async -> Void
    @State private var isRetrying = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("出错了")
                .font(.headline)

            Text(userFriendlyMessage(for: error))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: retry) {
                if isRetrying {
                    ProgressView()
                } else {
                    Label("重试", systemImage: "arrow.clockwise")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRetrying)
        }
    }
}
```

## Acceptance
- [ ] 统一错误提示UI
- [ ] 错误消息用户友好
- [ ] 重试按钮工作正常
- [ ] 离线时有明确提示
- [ ] 重试时显示loading状态
- [ ] 单元测试覆盖错误处理

## Quick Commands
```bash
xcodebuild build -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Done summary
Implemented unified error recovery component with retry support. Created ErrorRecoveryView with error categorization, offline detection (including NSError/NSURLErrorDomain), rate-limit countdown, and loading states. Integrated into AnalysisView and IngredientScannerView. Added 13 unit tests covering all error categories.
## Evidence
- Commits: 0ca8dbc, b37b9bc, abeb80f, 5d6e4d6
- Tests: xcodebuild test -scheme SkinLab -only-testing:SkinLabTests/ErrorHandlingTests
- PRs: