# fn-4-osk.3 Add LifestyleCorrelationAnalyzer unit tests

## Description
为 LifestyleCorrelationAnalyzer 添加单元测试，验证生活方式因素与皮肤状况变化的相关性计算逻辑。

**Size:** M
**Files:**
- `SkinLabTests/Tracking/LifestyleCorrelationAnalyzerTests.swift` (new)

## Approach

1. 创建新的测试文件
2. 添加到 SkinLabTests target (via Xcode 或 ruby 脚本)
3. 测试正常相关性计算
4. 测试边缘情况：空数据、单个数据点、低可靠性过滤
5. 测试 delta 计算逻辑（fn-3.1 修复后的新逻辑）

## Key Context

- `LifestyleCorrelationAnalyzer` 在 fn-3.1 中被修复，现在正确计算 delta
- 使用 `checkInId` 进行 join，而非 `day`
- **Critical**: 需要至少 3 个 check-ins 才能产生 2 个连续 pair
- **Critical**: 每个 pair 的可靠性必须 ≥ 0.5 才会被包含
- 需要测试 `.alcohol` 因素（之前缺失）

## Test Cases

1. `testAnalyzeWithValidData` - 3+ check-ins, reliability ≥ 0.5, 返回正确相关性
2. `testAnalyzeWithEmptyTimeline` - 空 timeline 返回空结果
3. `testAnalyzeWithTwoCheckIns` - 只有 2 个 check-ins 返回空结果 (需要 3+)
4. `testLowReliabilityFiltered` - 低可靠性 pair (<0.5) 被过滤
5. `testAlcoholFactorIncluded` - 验证酒精因素被包含
6. `testDeltaCalculation` - 验证 delta 计算使用 checkInId join

## Test Fixture Strategy (抗噪且可重复)

构造测试数据时遵循以下原则避免测试脆弱性：

1. **单调关系 fixture** (与实现同构):
   ```
   checkIns: 4 points (Day 0/7/14/21)
   pairs: 3 (checkIn[0]→[1], [1]→[2], [2]→[3])
   factorValues (from pair's current checkIn): [1, 2, 3]
   deltas (nextScore - currentScore): [0.1, 0.2, 0.3]
   ```
   - **Critical**: `factorValues` 取自 pair 的 `current checkIn`，最后一个 check-in 的 factor 不会被使用
   - `factorValues.count == pairs.count == checkIns.count - 1`
   - 预期相关性接近 +1.0

2. **断言策略**:
   - 只检查 `abs(correlation) >= 0.3`，不要求精确值
   - 检查相关性符号 (正/负) 而非具体数值

3. **Reliability map key**:
   - 使用 `CheckIn.id` 作为 key（与实现一致）
   - 确保被纳入 pair 的点均 ≥ 0.5

## References

- `SkinLab/Features/Tracking/Services/LifestyleCorrelationAnalyzer.swift`
- `SkinLabTests/Tracking/TimeSeriesAnalyzerTests.swift` (test patterns)

## Acceptance
- [ ] 创建 `LifestyleCorrelationAnalyzerTests.swift`
- [ ] 新文件已添加到 SkinLabTests target
- [ ] 至少 6 个测试用例
- [ ] 测试 fixture 使用 3+ check-ins
- [ ] 测试 fixture 中可靠性 ≥ 0.5
- [ ] 所有测试通过
- [ ] 覆盖正常路径和边缘情况
- [ ] 测试 alcohol 因素

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
