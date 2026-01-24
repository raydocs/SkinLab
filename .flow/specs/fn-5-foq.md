# fn-5-foq: 成分冲突检测增强

## Problem Statement
用户同时使用多款护肤品时，某些成分组合可能产生不良反应（如 Retinol + AHA 刺激、Vitamin C + Niacinamide pH冲突）。当前 `IngredientRiskAnalyzer` 仅检测单品风险，缺乏成分间相互作用的检测能力。

**市场痛点**: 用户不知道哪些成分不能同时使用，导致皮肤问题反复。

## Scope
- 建立本地成分冲突知识库
- 实时检测扫描产品中的冲突成分
- 在现有 UI 中展示冲突警告和使用建议
- 整合到 `EnhancedIngredientScanResult` 输出

## Approach

### 1. 数据模型
```swift
// 新增到 IngredientRiskAnalyzer.swift
struct IngredientConflict: Codable, Identifiable {
    let id: UUID
    let ingredient1: String  // 归一化成分名
    let ingredient2: String
    let severity: ConflictSeverity
    let description: String  // 中文说明
    let recommendation: String  // 使用建议（如"间隔12小时"）
}

enum ConflictSeverity: String, Codable {
    case warning = "警告"   // 建议分开使用
    case danger = "危险"    // 不建议同时使用
}
```

### 2. 冲突知识库（静态数据，至少15对）
| 成分1 | 成分2 | 严重程度 | 说明 |
|-------|-------|----------|------|
| retinol | aha | danger | 过度刺激，屏障受损 |
| retinol | bha | danger | 刺激叠加 |
| retinol | benzoyl peroxide | danger | 相互失效 |
| retinol | vitamin c | warning | pH环境冲突 |
| vitamin c | niacinamide | warning | 高浓度时可能冲突 |
| aha | vitamin c | warning | 刺激叠加 |
| benzoyl peroxide | vitamin c | danger | 氧化失效 |
| aha | bha | warning | 过度去角质 |
| retinol | azelaic acid | warning | 刺激叠加 |
| hydroquinone | benzoyl peroxide | danger | 皮肤染色 |
| 更多... | | | |

### 3. 扩展现有架构
- **文件**: `/SkinLab/Core/Utils/IngredientRiskAnalyzer.swift`
- **新增方法**:
  ```swift
  private func detectConflicts(ingredients: [ParsedIngredient]) -> [IngredientConflict]
  ```
- **整合位置**: `analyzeForUser()` 方法内调用
- **输出扩展**: 在 `EnhancedIngredientScanResult` 添加 `conflicts: [IngredientConflict]` 字段

### 4. 复用现有代码
- `IngredientNormalizer` (IngredientOCR.swift:390-698) - 成分名归一化
- `RiskLevel` enum (IngredientAIModels.swift) - 风险等级模式参考
- `IngredientAIResult.avoidCombos` - AI 冲突补充

### 5. UI 展示
- 在 `EnhancedIngredientResultView` 添加冲突警告 Section
- 红色边框显示 danger，橙色显示 warning
- 展开详情显示说明和使用建议

## Quick commands
```bash
# 运行相关测试
xcodebuild test -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SkinLabTests/ProductModelTests
```

## Acceptance
- [ ] 成分冲突知识库包含至少15对常见冲突
- [ ] 扫描含冲突成分的产品时显示警告
- [ ] 冲突严重程度正确区分（danger/warning）
- [ ] 每个冲突显示使用建议
- [ ] 单元测试覆盖冲突检测逻辑
- [ ] UI 正确展示冲突信息

## Key Files
- `/SkinLab/Core/Utils/IngredientRiskAnalyzer.swift` - 主要扩展
- `/SkinLab/Core/Utils/IngredientOCR.swift` - IngredientNormalizer 复用
- `/SkinLab/Features/Products/Views/EnhancedIngredientResultView.swift` - UI

## Risks & Mitigations
| 风险 | 缓解措施 |
|------|----------|
| 成分名匹配不精确 | 使用 IngredientNormalizer + lowercased() |
| 警告过多引起恐慌 | 区分严重程度，提供忽略功能 |
| 知识库不全面 | 核心冲突固定，AI avoidCombos 补充 |

## References
- `.factory/skills/ingredient-scanner/SKILL.md:172-209` - 已有冲突设计
- `/SkinLab/Features/Products/Models/IngredientAIModels.swift:102` - avoidCombos 字段
