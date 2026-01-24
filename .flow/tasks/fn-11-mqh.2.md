# fn-11-mqh.2 空状态引导设计

## Description
为各主要页面设计空状态，引导新用户开始使用。

**当前问题**: 新用户首次打开app看到空白页面，不知道该做什么。

**目标**:
1. 首页空状态引导开始首次分析
2. 追踪页空状态引导开始打卡
3. 产品页空状态引导添加产品
4. 统一的空状态组件

## Key Files
- `/SkinLab/Features/Analysis/Views/HomeView.swift` - 首页
- `/SkinLab/Features/Tracking/Views/TrackingView.swift` - 追踪页
- `/SkinLab/Features/Products/Views/ProductListView.swift` - 产品页
- 新建 `/SkinLab/Core/Components/EmptyStateView.swift` - 通用组件

## Implementation Notes
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
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

## Acceptance
- [ ] 首页有空状态设计
- [ ] 追踪页有空状态设计
- [ ] 产品页有空状态设计
- [ ] 空状态有明确的下一步操作按钮
- [ ] 图标和文案友好
- [ ] 无障碍支持

## Quick Commands
```bash
xcodebuild build -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Done summary
Created reusable EmptyStateView component with full accessibility support and unified empty states across TrackingView and ProductsView. Added search filtering with empty state for ProductsView.
## Evidence
- Commits: 14d0a61, 5a58a67, d47ce77
- Tests: xcodebuild build -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17'
- PRs: