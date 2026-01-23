# fn-4-osk.6 Extract TrackingConstants for check-in days

## Description
将硬编码的 check-in 天数常量 `[0, 7, 14, 21, 28]` 提取到集中的常量文件中，消除所有文件中的重复。

**Size:** S
**Files:**
- `SkinLab/Features/Tracking/Models/TrackingConstants.swift` (new)
- `SkinLab/Features/Tracking/Views/TrackingDetailView.swift` (update)
- `SkinLab/Features/Tracking/Views/TrackingView.swift` (update)
- `SkinLab/Features/Tracking/Models/TrackingSession.swift` (update)
- `SkinLab/Features/Tracking/Services/ReliabilityScorer.swift` (update)

## Approach

1. 创建 `TrackingConstants.swift` 包含 `checkInDays` 常量
2. 添加到 SkinLab target (via Xcode 或 ruby 脚本)
3. 搜索所有 `[0, 7, 14, 21, 28]` 字面量并替换
4. 验证没有遗漏：`grep -r "\[0, 7, 14, 21, 28\]" SkinLab/Features/Tracking`

## Key Context

已知重复位置：
- `TrackingDetailView.swift` - timeline section
- `TrackingView.swift` - check-in node UI
- `TrackingSession.swift` - nextCheckInDay logic (2 处)
- `ReliabilityScorer.swift` - expectedDay extension

**Critical**: 必须替换所有出现位置，验证命令：
```bash
grep -r "\[0, 7, 14, 21, 28\]" SkinLab/Features/Tracking --include="*.swift"
```
此命令应返回空结果。

## References

- Research identified 4+ files with duplicated constant

## Acceptance
- [ ] 创建 `TrackingConstants.swift`
- [ ] 定义 `static let checkInDays = [0, 7, 14, 21, 28]`
- [ ] 新文件已添加到 SkinLab target
- [ ] 更新 `TrackingDetailView.swift` 使用常量
- [ ] 更新 `TrackingView.swift` 使用常量
- [ ] 更新 `TrackingSession.swift` 使用常量 (2 处)
- [ ] 更新 `ReliabilityScorer.swift` 使用常量
- [ ] `grep -r "\[0, 7, 14, 21, 28\]" SkinLab/Features/Tracking` 返回空
- [ ] 项目可以成功编译

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
