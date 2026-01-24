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
TBD

## Evidence
- Commits:
- Tests:
- PRs:
