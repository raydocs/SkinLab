# fn-14-ofm.4 修复内存泄漏风险

## Description
为所有 DispatchQueue 异步回调添加 `[weak self]` 捕获列表，防止潜在的循环引用和内存泄漏。

**风险位置**:
- HomeView.swift - 动画延迟回调
- AchievementUnlockAnimationView.swift - 动画回调
- StreakCelebrationView.swift - 庆祝动画
- 其他使用 `DispatchQueue.main.asyncAfter` 的位置

**目标**:
1. 搜索所有 DispatchQueue 回调
2. 添加 [weak self] 捕获
3. 使用可选链调用

## Key Files
- `/SkinLab/Features/Analysis/Views/HomeView.swift`
- `/SkinLab/Features/Engagement/Views/AchievementUnlockAnimationView.swift`
- `/SkinLab/Features/Celebration/Views/StreakCelebrationView.swift`
- 其他异步回调位置

## Implementation Notes
```swift
// 搜索模式
grep -rn "DispatchQueue.*{" --include="*.swift" SkinLab/ | grep -v "weak self"

// 修复前
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    self.showAnimation = true
}

// 修复后
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
    self?.showAnimation = true
}

// Task异步也需要检查
Task {
    self.doSomething()  // 需要 [weak self]
}

// 修复后
Task { [weak self] in
    await self?.doSomething()
}
```

**检查清单**:
- `DispatchQueue.main.async`
- `DispatchQueue.main.asyncAfter`
- `DispatchQueue.global().async`
- `Task { }`
- Timer 回调

## Acceptance
- [ ] 所有 DispatchQueue 回调有 [weak self]
- [ ] 所有 Task 回调有 [weak self]
- [ ] 使用可选链 (self?.property)
- [ ] Build 成功
- [ ] 无内存泄漏警告

## Quick Commands
```bash
grep -rn "DispatchQueue" --include="*.swift" SkinLab/ | grep -v "weak self" | head -20
xcodebuild build -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
