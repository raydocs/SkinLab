# fn-11-mqh.4 信息层级简化

## Description
重新设计信息层级，突出关键指标，收起次要信息。

**当前问题**: 重要信息和次要信息视觉权重相同，用户难以快速获取关键洞察。

**目标**:
1. 关键指标视觉突出
2. 次要信息可折叠
3. 渐进式披露
4. 统一的卡片样式

## Key Files
- `/SkinLab/Features/Tracking/Views/TrackingReportView.swift` - 报告页
- `/SkinLab/Features/Analysis/Views/AnalysisResultView.swift` - 分析结果
- `/SkinLab/Core/Components/` - 通用组件

## Implementation Notes

### 视觉层级
1. **主要指标**: 大字体、高对比度、占据显眼位置
   - 综合评分、变化趋势
2. **次要指标**: 中等字体、可折叠
   - 各项详细得分
3. **辅助信息**: 小字体、灰色
   - 数据来源、更新时间

### 渐进式披露
```swift
// 摘要卡片 - 始终可见
SummaryCard(score: 75, trend: .improving)

// 详情卡片 - 点击展开
DisclosureGroup("查看详情") {
    DetailedMetricsView()
}
```

## Acceptance
- [ ] 关键信息视觉突出
- [ ] 次要信息可折叠
- [ ] 信息层级清晰
- [ ] 用户能快速获取关键洞察
- [ ] 统一的样式语言
- [ ] 无障碍支持

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
