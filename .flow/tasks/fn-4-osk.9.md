# fn-4-osk.9 Update CLAUDE.md with fn-2/fn-3 completed features

## Description
更新 CLAUDE.md 文档，记录 fn-2 (Engagement Features) 和 fn-3 (Photo Standardization & Lifestyle) 完成的功能和关键实现细节。

**Size:** S
**Files:**
- `CLAUDE.md` (update)

## Approach

1. 在 `<!-- BEGIN FLOW-NEXT -->` 标记**上方**添加 "## Completed Features" 部分
2. **不要修改** `<!-- BEGIN FLOW-NEXT -->` 和 `<!-- END FLOW-NEXT -->` 之间的内容
3. 记录 fn-2 engagement features (streaks, badges, celebrations)
4. 记录 fn-3 fixes (lifestyle delta, Day 0 baseline, reliability)
5. 添加关键实现规则

## Content to Add

### fn-2 (Engagement Features)
- UserEngagementMetrics 模型
- AchievementProgress 和 AchievementDefinition
- StreakTrackingService 和 AchievementService
- Freeze 机制 (1 per 30 days)

### fn-3 (Photo Standardization & Lifestyle)
- Lifestyle delta 现在使用 checkInId join
- Day 0 baseline 从 analysis 创建
- Reliability 在 capture 时计算
- Lifestyle inputs 真正可选

### Key Rules
- 始终使用 checkInId 进行 join，而非 day
- SwiftData writes 只在 @MainActor

**Critical**: 保持 FLOW-NEXT 标记块不变

## References

- `.flow/specs/fn-2.md` (516 lines)
- `.flow/specs/fn-3.md` (273 lines)

## Acceptance
- [ ] CLAUDE.md 在 `<!-- BEGIN FLOW-NEXT -->` 上方包含 "## Completed Features" 部分
- [ ] fn-2 engagement features 有文档
- [ ] fn-3 fixes 有文档
- [ ] 关键实现规则有记录 (checkInId join rule, @MainActor)
- [ ] `<!-- BEGIN FLOW-NEXT -->` 和 `<!-- END FLOW-NEXT -->` 之间内容未被修改
- [ ] 文档格式与现有风格一致

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
