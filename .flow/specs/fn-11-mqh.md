# fn-11-mqh: 用户体验优化 - UX Improvements

## Problem Statement
分析报告显示多个UX痛点：
1. **信息过载**: TrackingReportView 显示大量数据块，缺乏优先级
2. **空状态缺失**: 新用户首次使用时看到空白页面
3. **错误恢复差**: 网络错误后用户不知如何继续
4. **层级混乱**: 重要信息和次要信息视觉权重相同

**用户痛点**: "报告太长不想看"、"刚下载不知道该做什么"

## Scope
- 报告区块折叠优化（DisclosureGroup）
- 空状态引导设计
- 错误恢复路径
- 信息层级简化

## Approach

### Task 1: 报告区块折叠
```swift
// TrackingReportView.swift:168-191 现有模式
private func disclosureCard<Content: View>(...) -> some View

// 优化目标:
// 1. 默认只展开最重要的1-2个区块
// 2. 记住用户展开偏好
// 3. "全部展开/折叠"按钮
// 4. 关键洞察摘要始终可见
```

### Task 2: 空状态引导
- 首次启动引导流程
- 各页面空状态设计
- 行动号召按钮
- 进度指示器

### Task 3: 错误恢复
- 统一错误提示组件
- 重试按钮
- 离线模式提示
- 错误上下文保留

### Task 4: 信息层级优化
- 视觉层级重设计
- 关键指标突出
- 次要信息收起
- 渐进式披露

## Quick commands
```bash
xcodebuild build -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Acceptance
- [ ] 报告区块支持折叠/展开
- [ ] 用户展开偏好被记住
- [ ] 各主要页面有空状态设计
- [ ] 空状态有明确的下一步操作按钮
- [ ] 网络错误有统一提示和重试选项
- [ ] 关键信息视觉突出
- [ ] 次要信息可折叠

## Key Files
- `/SkinLab/Features/Tracking/Views/TrackingReportView.swift:168-191` - DisclosureCard
- `/SkinLab/Features/Analysis/Views/HomeView.swift` - 首页空状态
- `/SkinLab/Features/Tracking/Views/TrackingView.swift` - 追踪页空状态
- `/SkinLab/Features/Products/Views/ProductListView.swift` - 产品页空状态

## Technical Details

### 展开偏好存储
```swift
// 使用 @AppStorage
@AppStorage("report.expandedSections")
private var expandedSections: Set<String> = ["summary", "skinScore"]

// 或 UserDefaults 编码
struct ReportPreferences: Codable {
    var expandedSections: Set<String>
    var showDetailedCharts: Bool
}
```

### 空状态组件
```swift
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(message).font(.subheadline).foregroundStyle(.secondary)
            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
        }
    }
}
```

### 错误恢复组件
```swift
struct ErrorRecoveryView: View {
    let error: Error
    let retryAction: () async -> Void

    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
            Text(error.localizedDescription)
            Button("重试") { Task { await retryAction() } }
        }
    }
}
```

## Risks & Mitigations
| 风险 | 缓解措施 |
|------|----------|
| 折叠后信息找不到 | 添加搜索/跳转功能 |
| 引导流程太长 | 可跳过，核心步骤3个以内 |
| 错误信息不友好 | 本地化错误消息 |

## Dependencies
- SwiftUI DisclosureGroup
- @AppStorage for preferences
- 现有 UI 组件库

## References
- `TrackingReportView.swift:168-191` - disclosureCard 模式
- Apple HIG - Empty States
- Apple HIG - Error Handling
