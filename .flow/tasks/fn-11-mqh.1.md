# fn-11-mqh.1 报告区块折叠优化

## Description
优化TrackingReportView中的报告区块，使用DisclosureGroup实现折叠功能，减少信息过载。

**当前问题**: 报告页面显示大量数据块，用户难以找到关键信息。

**目标**:
1. 默认只展开最重要的1-2个区块
2. 记住用户展开偏好
3. "全部展开/折叠"按钮
4. 关键洞察摘要始终可见

## Key Files
- `/SkinLab/Features/Tracking/Views/TrackingReportView.swift:168-191` - disclosureCard模式
- 新建 `/SkinLab/Core/Components/CollapsibleSection.swift` - 通用折叠组件

## Implementation Notes
```swift
// 使用 @AppStorage 存储展开偏好
@AppStorage("report.expandedSections")
private var expandedSectionsData: Data = Data()

var expandedSections: Set<String> {
    get { ... }
    set { ... }
}

// 默认展开: summary, skinScore
// 其他区块默认折叠
```

## Acceptance
- [ ] 报告区块支持折叠/展开
- [ ] 用户展开偏好被持久化
- [ ] 有"全部展开/折叠"按钮
- [ ] 关键摘要始终可见
- [ ] 折叠动画流畅
- [ ] 无障碍支持(VoiceOver)

## Quick Commands
```bash
xcodebuild build -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Done summary
Implemented collapsible sections with persistence for TrackingReportView. Created reusable CollapsibleSection component with @MainActor-safe CollapsibleSectionManager using @Published + @AppStorage for user preference persistence. Added expand/collapse all button, summary badges on collapsed sections, and VoiceOver accessibility support. Key insights (header stats, trend chart, AI summary) remain always visible while detailed analysis sections default to collapsed state.
## Evidence
- Commits: 5361a29d19a08b3e1c8c8e76fb05a6e5e92b44a2, 3aac885a7f7ebb651d238c8a1c1d5322c356bea8
- Tests: xcodebuild build -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17'
- PRs: