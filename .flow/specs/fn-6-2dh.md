# fn-6-2dh: 产品归因增强 - Multi-Product Attribution

## Problem Statement
当用户同时使用多款产品时，现有 `ProductEffectAnalyzer` 独立评估每款产品效果，无法准确判断皮肤改善/恶化究竟由哪款产品引起。

**市场痛点**: "我用了5款产品皮肤变好了，但不知道是哪款起效" - 产品选择困难症的根源。

## Scope
- 检测产品使用重叠期
- 分析多产品组合效应
- 提供更精准的单品归因
- 生成产品组合建议

## Approach

### 1. 现有架构分析
`ProductEffectAnalyzer` (ProductEffectAnalyzer.swift:25-71):
- 当前: 遍历 `checkIn.usedProducts`，为每个产品独立构建 `ProductUsageData`
- 效果公式: `0.5*scoreChange + 0.3*feelingScore + 0.2*ingredientScore`
- 置信度: Bayesian-lite (使用次数 + 稳定性 + 间隔一致性)

### 2. 扩展数据模型
```swift
// 扩展 ProductUsageData (私有结构)
private struct ProductUsageData {
    // 现有字段...
    var coUsedProducts: [String: Int] = [:]  // 新增: 同日使用的其他产品 -> 次数
    var soloUsageDays: [Int] = []  // 新增: 单独使用的日期
}

// 新增: 产品组合分析结果
struct ProductCombinationInsight: Codable {
    let productIds: Set<String>
    let combinedEffectScore: Double  // 组合效果
    let synergyScore: Double  // 协同/拮抗评分 (-1 to 1)
    let usageCount: Int
    let confidence: ConfidenceScore
}
```

### 3. 归因算法增强
1. **重叠检测**: 识别哪些产品经常一起使用
2. **单独使用对比**: 对比产品单独使用 vs 组合使用的效果差异
3. **变化归因**: 当皮肤状态变化时，计算各产品的贡献权重
4. **参考模式**: 复用 `LifestyleCorrelationAnalyzer` 的 Spearman 相关性方法

### 4. 新增方法
```swift
// ProductEffectAnalyzer.swift 扩展
func detectProductOverlap(checkIns: [CheckIn]) -> [Set<String>: Int]
func analyzeCombinationEffect(products: Set<String>, checkIns: [CheckIn], analyses: [UUID: SkinAnalysis]) -> ProductCombinationInsight?
func calculateAttributionWeights(products: [String], scoreChange: Double) -> [String: Double]
```

### 5. UI 展示
- 在产品效果报告中显示"组合效果"
- 标识"可能是主要贡献者"的产品
- 建议"尝试单独使用X天以验证效果"

## Quick commands
```bash
xcodebuild test -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SkinLabTests/TrackingModelsTests
```

## Acceptance
- [ ] 能检测产品使用重叠期（同日使用多产品）
- [ ] 分析产品组合的协同/拮抗效应
- [ ] 单品归因准确度提升（有单独使用数据时）
- [ ] 报告中显示"主要贡献者"标识
- [ ] 提供"单独验证"建议
- [ ] 单元测试覆盖新增逻辑

## Key Files
- `/SkinLab/Features/Tracking/Services/ProductEffectAnalyzer.swift` - 主要扩展
- `/SkinLab/Features/Tracking/Services/LifestyleCorrelationAnalyzer.swift` - 相关性分析参考
- `/SkinLab/Features/Tracking/Models/TrendAnalyticsModels.swift` - ProductEffectInsight 模型
- `/SkinLab/Features/Tracking/Models/TrackingReportExtensions.swift:231` - 调用入口

## Technical Details

### 归因权重计算
```swift
// 简化的归因算法
func calculateAttributionWeights(products: [String], checkIns: [CheckIn], scoreChange: Double) -> [String: Double] {
    var weights: [String: Double] = [:]

    for product in products {
        // 因素1: 产品单独使用时的平均效果
        let soloEffect = calculateSoloEffect(product, checkIns)

        // 因素2: 产品使用频率
        let frequency = calculateUsageFrequency(product, checkIns)

        // 因素3: 产品成分已知效果（从历史数据）
        let ingredientScore = calculateIngredientHistoryScore(product)

        weights[product] = 0.4 * soloEffect + 0.3 * frequency + 0.3 * ingredientScore
    }

    // 归一化使总和为1
    return normalize(weights)
}
```

## Risks & Mitigations
| 风险 | 缓解措施 |
|------|----------|
| 缺少单独使用数据 | 提示用户"单独使用X天可提高分析准确度" |
| 组合太多难以分析 | 限制分析最常见的前5种组合 |
| 置信度过低 | 明确显示置信度，低于阈值时标注"参考价值有限" |

## References
- `ProductEffectAnalyzer.swift:190-222` - 现有 Bayesian-lite 置信度计算
- `LifestyleCorrelationAnalyzer.swift:62-91` - 连续配对构建模式
- `TrendAnalyticsModels.swift:229-275` - ProductEffectInsight 定义
