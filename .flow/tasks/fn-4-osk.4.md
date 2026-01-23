# fn-4-osk.4 Add ReliabilityScorer unit tests

## Description
为 ReliabilityScorer 添加单元测试，验证照片质量可靠性评分逻辑。

**Size:** M
**Files:**
- `SkinLabTests/Tracking/ReliabilityScorerTests.swift` (new)

## Approach

1. 创建新的测试文件
2. 添加到 SkinLabTests target (via Xcode 或 ruby 脚本)
3. 测试评分计算逻辑
4. 测试实际 scorer 使用的维度
5. 测试边缘情况

## Key Context

- fn-3.3 修复了 `tooBright` 映射错误 (was `.lowLight`, should be `.highLight`)
- 可靠性在 capture 时计算，不仅在 report 生成时
- ReliabilityScorer 实际使用的评分维度：
  - `lighting` (low/high light)
  - `faceDetected`
  - `yaw/pitch/roll` (face angle)
  - `distance`
  - `captureSource == .library`
  - `userOverride == .userFlaggedIssue`
  - **timing penalty**: `captureDate` vs expected date

## Test Cases

1. `testScoreWithPerfectPhoto` - 所有指标正常得高分
2. `testScoreWithLowLight` - 低光照降低分数
3. `testScoreWithHighLight` - 高光照 (tooBright) 降低分数，验证 `.highLight` 映射
4. `testScoreWithBadFaceAngle` - yaw/pitch/roll 超标降低分数
5. `testScoreFromLibrary` - captureSource == .library 的影响
6. `testScoreWithUserFlaggedIssue` - userOverride 的影响
7. `testTimingPenalty` - 延迟 check-in 的时间惩罚 (captureDate vs expected)

## References

- `SkinLab/Features/Tracking/Services/ReliabilityScorer.swift`
- fn-3.3 spec for tooBright fix details

## Acceptance
- [ ] 创建 `ReliabilityScorerTests.swift`
- [ ] 新文件已添加到 SkinLabTests target
- [ ] 至少 7 个测试用例
- [ ] 测试 `tooBright` 正确映射到 `.highLight`
- [ ] 测试时间惩罚逻辑 (captureDate vs expected)
- [ ] 测试所有实际 scorer 使用的维度
- [ ] 所有测试通过

## Done summary
Added 18 comprehensive unit tests for ReliabilityScorer covering all scoring dimensions: lighting (low/high), face angle, distance, face detection, library photos, user flags, timing penalty, analysis confidence, and camera position consistency. Tests verify the fn-3.3 fix for tooBright -> .highLight mapping.
## Evidence
- Commits: 11026e87a1f7ac00df3695b49da96c0cee4bc539
- Tests: xcodebuild test -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' -only-testing:SkinLabTests/ReliabilityScorerTests
- PRs: