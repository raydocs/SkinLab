# fn-14-ofm.3 移除调试print语句

## Description
移除生产代码中遗留的 print() 调试语句，这些语句会影响性能并可能泄露敏感信息。

**已知位置**:
- `WeatherCardView.swift:482` - `print("Tapped")`
- `WeatherCardView.swift:488` - `print("Retry")`
- `StreakBadgeView.swift:157` - `print("Freeze tapped")`
- `StreakBadgeView.swift:168` - print语句
- `StreakBadgeView.swift:179` - print语句

**目标**:
1. 搜索并移除所有 print() 语句
2. 对需要保留日志的地方替换为 Logger
3. 验证无遗留调试代码

## Key Files
- `/SkinLab/Features/Weather/Views/WeatherCardView.swift:482,488`
- `/SkinLab/Features/Engagement/Views/StreakBadgeView.swift:157,168,179`
- 全局搜索其他 print 语句

## Implementation Notes
```bash
# 搜索所有print语句
grep -rn "print(" --include="*.swift" SkinLab/

# 排除注释中的print
grep -rn "^\s*print(" --include="*.swift" SkinLab/
```

**替换策略**:
- 纯调试用途：直接删除
- 需要保留日志：替换为 `Logger.debug()`
- 用户可见信息：保持原状（如 analytics print）

```swift
// 删除
print("Tapped")  // 直接删除

// 替换为Logger
print("API response: \(response)")  // 改为
Logger.debug("API response: \(response)")
```

## Acceptance
- [ ] WeatherCardView print 语句移除
- [ ] StreakBadgeView print 语句移除
- [ ] 全局搜索无遗留 print
- [ ] 必要日志替换为 Logger
- [ ] Build 成功

## Quick Commands
```bash
grep -rn "^\s*print(" --include="*.swift" SkinLab/ | wc -l
xcodebuild build -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Done summary
Removed all debug print() statements from production code. Preview action placeholders cleared in WeatherCardView, StreakBadgeView, IngredientAIInsightView, AchievementUnlockAnimationView, and StreakCelebrationView. Production error logging replaced with AppLogger calls in CameraPreviewView, TrackingReportExtensions, and TrackingReportView.
## Evidence
- Commits: acf6511385d3348633b76d2e9d0dfd8ece4333ae
- Tests: xcodebuild build -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17', grep -rn 'print(' --include='*.swift' SkinLab/
- PRs: