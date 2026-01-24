# fn-8-fxq: 场景化护肤模式 - Scene-based Skincare

## Problem Statement
通用护肤建议无法满足用户在不同场景下的特定需求。用户在旅行、运动、熬夜、生理期等场景下需要针对性的护肤指导。

**市场痛点**: "我明天要去海边，该怎么护肤？" —— 现有建议过于通用。

## Scope
- 定义常见护肤场景（8-10种）
- 场景选择入口和 UI
- 基于场景生成针对性建议
- 与现有推荐系统整合

## Approach

### 1. 场景定义
```swift
enum SkinScenario: String, CaseIterable, Codable {
    case office = "办公室"        // 长时间空调、蓝光暴露
    case outdoor = "户外运动"     // 高UV、出汗
    case travel = "长途旅行"      // 干燥机舱、时区变化
    case postMakeup = "浓妆后"    // 深层清洁需求
    case menstrual = "生理期"     // 荷尔蒙变化、敏感
    case stressful = "高压期"     // 熬夜、压力大
    case seasonal = "换季期"      // 温湿度变化
    case recovery = "医美后"      // 修复期特殊护理
    case beach = "海边度假"       // 高UV、海水盐分
    case homeRelax = "居家放松"   // 深层护理时机

    var icon: String {
        switch self {
        case .office: return "building.2"
        case .outdoor: return "figure.run"
        case .travel: return "airplane"
        case .postMakeup: return "face.dashed"
        case .menstrual: return "heart.circle"
        case .stressful: return "moon.zzz"
        case .seasonal: return "leaf"
        case .recovery: return "cross.circle"
        case .beach: return "sun.horizon"
        case .homeRelax: return "house"
        }
    }
}
```

### 2. 场景建议模型
```swift
struct ScenarioRecommendation: Codable {
    let scenario: SkinScenario
    let summary: String
    let doList: [String]        // 应该做的
    let dontList: [String]      // 避免做的
    let productTips: [String]   // 产品选择建议
    let ingredientFocus: [String]  // 推荐成分
    let ingredientAvoid: [String]  // 避免成分
}
```

### 3. 建议生成逻辑
```swift
// 新建 ScenarioAdvisor.swift
struct ScenarioAdvisor {
    func generateRecommendation(
        scenario: SkinScenario,
        profile: UserProfile,
        currentAnalysis: SkinAnalysis?
    ) -> ScenarioRecommendation

    // 复用现有的 SeasonalityAnalyzer 和 RoutineService
}
```

### 4. UI 入口
- 首页添加"今日场景"快捷选择
- 或在 Check-in 时可选标记场景
- 专门的"场景护肤指南"页面

### 5. 整合现有系统
- 参考 `SeasonalityAnalyzer.generateSeasonalRecommendations()` 模式
- 可调用 `RoutineService` 生成场景特定的 AI 护肤方案
- 与 `LifestyleFactors` 整合（添加 sceneContext 字段）

## Quick commands
```bash
xcodebuild test -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SkinLabTests/Tracking
```

## Acceptance
- [ ] 定义至少8种护肤场景
- [ ] 用户可选择当前场景
- [ ] 每个场景有针对性的 Do/Don't 列表
- [ ] 场景建议与用户肤质结合
- [ ] 建议包含具体产品/成分指导
- [ ] UI 入口清晰易用

## Key Files
- 新建 `/SkinLab/Features/Scenario/Models/ScenarioModels.swift`
- 新建 `/SkinLab/Features/Scenario/Services/ScenarioAdvisor.swift`
- 新建 `/SkinLab/Features/Scenario/Views/ScenarioSelectionView.swift`
- `/SkinLab/Features/Tracking/Services/SeasonalityAnalyzer.swift` - 参考模式
- `/SkinLab/Core/Network/RoutineService.swift` - AI 建议生成
- `/SkinLab/Features/Tracking/Models/TrackingMetadataModels.swift` - 扩展 LifestyleFactors

## Technical Details

### 场景特定建议规则
| 场景 | 关键成分推荐 | 避免成分 | 核心建议 |
|------|-------------|----------|----------|
| 办公室 | 保湿、抗蓝光 | 高刺激性 | 多补水、定时喷雾 |
| 户外运动 | 防晒、抗氧化 | 厚重油脂 | SPF50+、运动后及时清洁 |
| 长途旅行 | 保湿、修复 | 新产品 | 精简护肤、保湿喷雾 |
| 浓妆后 | 温和卸妆、修复 | 酸类、磨砂 | 双重清洁、加强保湿 |
| 生理期 | 舒缓、抗炎 | 刺激性酸 | 简化流程、重保湿 |
| 高压期 | 抗氧化、修复 | 高活性成分 | 保证睡眠、减少步骤 |

### 与 LifestyleFactors 整合
```swift
// TrackingMetadataModels.swift 扩展
struct LifestyleFactors: Codable, Sendable {
    // 现有字段...
    let sceneContext: SkinScenario?  // 新增
}
```

## Risks & Mitigations
| 风险 | 缓解措施 |
|------|----------|
| 场景太多用户困惑 | 首页只显示最常用4-5个，其他折叠 |
| 建议过于通用 | 结合用户肤质和历史数据个性化 |
| AI 建议质量不一 | 预设核心规则，AI 补充细节 |

## References
- `SeasonalityAnalyzer.swift:159-204` - generateSeasonalRecommendations 模式
- `RoutineService.swift` - AI 护肤方案生成
- `TrackingMetadataModels.swift:116-163` - LifestyleFactors 定义
