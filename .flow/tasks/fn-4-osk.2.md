# fn-4-osk.2 Fix TrackingReportView redundant ternary logic

## Description
修复 TrackingReportView.swift 中 `sortedCheckInIds` 的冗余三元表达式。当前代码两个分支返回相同的值，是复制粘贴错误。

**Size:** S
**Files:**
- `SkinLab/Features/Tracking/Views/TrackingReportView.swift`

## Approach

1. 打开 TrackingReportView.swift
2. 定位 `sortedCheckInIds` 变量赋值
3. 修复三元表达式：当 `timelineReliable` 不为空时使用它

## Key Context

当前错误代码:
```swift
let sortedCheckInIds = report.timelineReliable.isEmpty
    ? report.timeline.map { $0.checkInId }
    : report.timeline.map { $0.checkInId }  // 两个分支相同！
```

应该是:
```swift
let sortedCheckInIds = report.timelineReliable.isEmpty
    ? report.timeline.map { $0.checkInId }
    : report.timelineReliable.map { $0.checkInId }
```

## References

- `EnhancedTrackingReport` model with `timeline` and `timelineReliable` properties

## Acceptance
- [ ] `sortedCheckInIds` 三元表达式两个分支返回不同的值
- [ ] 当 `timelineReliable` 不为空时，使用 `timelineReliable.map { $0.checkInId }`
- [ ] 项目可以成功编译
- [ ] 追踪报告视图显示正确

## Done summary
Fixed redundant ternary expression in TrackingReportView.swift where sortedCheckInIds was incorrectly using report.timeline in both branches. Now correctly uses report.timelineReliable when available.
## Evidence
- Commits: 3be36dcef9a3d348c3fed5af1529a5b9450fe6b6
- Tests: xcodebuild build -scheme SkinLab (successful)
- PRs: