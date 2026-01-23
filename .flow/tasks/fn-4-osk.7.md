# fn-4-osk.7 Split TrackingDetailView into smaller components

**Depends on:** fn-4-osk.6 (TrackingConstants extraction)

## Description
将 927 行的 TrackingDetailView.swift 拆分为更小的组件文件，提高代码可维护性。

**Size:** M
**Files:**
- `SkinLab/Features/Tracking/Views/TrackingDetailView.swift` (update, target < 600 lines)
- `SkinLab/Features/Tracking/Views/Components/CheckInView.swift` (new)
- `SkinLab/Features/Tracking/Views/Components/TrackingDetailComponents.swift` (new) - CheckInRow, FeelingButton, LifestyleDraft

## Approach

1. 分析 TrackingDetailView.swift 识别可提取组件
2. 提取 `CheckInView` 到独立文件（最大的子视图）
3. 提取 `CheckInRow`, `FeelingButton`, `LifestyleDraft` 到 `TrackingDetailComponents.swift`
4. 添加新文件到 SkinLab target (via Xcode 或 ruby 脚本)
5. 确保所有引用更新正确

## Key Context

当前结构 (927 lines):
- `TrackingDetailView` - 主视图
- `CheckInRow` - check-in 列表行
- `LifestyleDraft` - 生活方式草稿
- `CheckInView` - check-in 详情（~500 行，最大子视图）
- `FeelingButton` - 心情按钮

**Target**: TrackingDetailView.swift < 600 行（原 500 行目标过于严格）

## References

- `SkinLab/Features/Tracking/Views/TrackingDetailView.swift`
- SwiftUI component extraction best practices

## Acceptance
- [ ] TrackingDetailView.swift < 600 行
- [ ] 创建 `CheckInView.swift`
- [ ] 创建 `TrackingDetailComponents.swift` (CheckInRow, FeelingButton, LifestyleDraft)
- [ ] 新文件已添加到 SkinLab target
- [ ] 所有组件可正确 import 和使用
- [ ] UI 功能不变
- [ ] 项目可以成功编译

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
