# fn-10-khd.3 Freeze冻结功能完成

## Description
完成连续打卡冻结(Freeze)功能，允许用户在忘记打卡时使用冻结保护连续记录。

**当前状态**:
- `HomeView.swift:133` 有TODO但未实现freeze使用入口
- `StreakTrackingService.swift:153-176` 已有 `useStreakFreeze()` 方法

**目标**:
1. UI显示当前可用freeze数量
2. 手动触发freeze使用
3. 断签时自动检测并提示使用freeze

## Key Files
- `/SkinLab/Features/Analysis/Views/HomeView.swift:133` - freeze入口
- `/SkinLab/Features/Engagement/Services/StreakTrackingService.swift:153-176` - useStreakFreeze
- `/SkinLab/Features/Engagement/Models/EngagementModels.swift` - StreakMetrics

## Implementation Notes
```swift
// 添加断签检测方法
func shouldSuggestFreeze() -> Bool {
    // 昨天没打卡 && 有可用freeze && 当前有连续记录
}

// HomeView 添加UI
// 显示"🔥 连续 X 天 | ❄️ X个冻结可用"
// 断签提示："昨天忘记打卡？使用冻结保护连续记录"
```

## Acceptance
- [ ] HomeView显示freeze可用数量
- [ ] 用户可手动使用freeze
- [ ] 断签时显示使用提示
- [ ] freeze使用后数量正确扣减
- [ ] freeze使用有确认对话框
- [ ] 单元测试覆盖freeze逻辑

## Quick Commands
```bash
xcodebuild test -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SkinLabTests/EngagementTests
```

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
