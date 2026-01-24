# fn-7-5gr: 预测性护肤 - Predictive Skincare Alerts

## Problem Statement
当前护肤建议是被动响应已发生的问题。现有 `ForecastEngine` 已有预测能力和 `riskAlert` 机制，但：
1. 预测结果未推送通知
2. 仅基于皮肤数据，未融合生活方式因素
3. 可视化组件已存在但未集成到主报告视图

**市场痛点**: 用户希望"在痘痘爆发前收到预警"，而非事后补救。

## Scope
- 整合预测结果到主报告视图
- 实现预测性通知推送
- 融合生活方式因素提高预测准确度
- 完善风险预警逻辑

## Approach

### 1. 现有能力盘点 (85%复用)
| 组件 | 位置 | 状态 |
|------|------|------|
| ForecastEngine | ForecastEngine.swift | ✅ 完整 |
| TrendForecast.riskAlert | TrendAnalyticsModels.swift:135-150 | ✅ 有基础逻辑 |
| ForecastChartView | AnalyticsVisualizationViews.swift:15-129 | ✅ 已实现但未集成 |
| AnomalyListView | AnalyticsVisualizationViews.swift:132-173 | ✅ 已实现但未集成 |
| StreakNotificationService | StreakNotificationService.swift | ✅ 通知模式参考 |

### 2. 增强 riskAlert 逻辑
```swift
// TrendForecast 扩展
var riskAlert: PredictiveAlert? {
    guard let last = points.last else { return nil }

    // 现有逻辑...
    // 新增: 生活方式因素融合
    // 新增: 更多指标预警
}

struct PredictiveAlert: Codable {
    let metric: String
    let severity: AlertSeverity  // low, medium, high
    let message: String
    let actionSuggestion: String
    let predictedDate: Date
    let confidence: ConfidenceScore
}

enum AlertSeverity: String, Codable {
    case low = "提醒"
    case medium = "注意"
    case high = "警告"
}
```

### 3. 通知服务
```swift
// 新建 PredictiveAlertNotificationService.swift
// 参考 StreakNotificationService 模式
@MainActor
final class PredictiveAlertNotificationService {
    func scheduleAlertNotification(alert: PredictiveAlert) async
    func cancelAllPredictiveAlerts()
}
```

### 4. 视图集成
- 在 `TrackingReportView` 添加 `ForecastChartView`
- 显示预测趋势和置信区间
- 高亮风险预警

### 5. 设置页面
- 添加 `@AppStorage("notifications.predictiveAlerts")` 开关
- 在 `NotificationSettingsView` 中显示

## Quick commands
```bash
xcodebuild test -scheme SkinLab -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SkinLabTests/Tracking
```

## Acceptance
- [ ] ForecastChartView 集成到 TrackingReportView
- [ ] 预测风险通知推送功能
- [ ] 用户可在设置中开关预测通知
- [ ] riskAlert 覆盖更多指标（痘痘、泛红、综合评分、敏感度）
- [ ] 预警显示预测日期和置信度
- [ ] 提供具体行动建议

## Key Files
- `/SkinLab/Features/Tracking/Services/ForecastEngine.swift` - 预测引擎
- `/SkinLab/Features/Tracking/Models/TrendAnalyticsModels.swift` - TrendForecast 模型
- `/SkinLab/Features/Tracking/Views/AnalyticsVisualizationViews.swift` - 已有可视化组件
- `/SkinLab/Features/Tracking/Views/TrackingReportView.swift` - 集成目标
- `/SkinLab/Features/Engagement/Services/StreakNotificationService.swift` - 通知模式参考
- `/SkinLab/Features/Profile/Views/NotificationSettingsView.swift` - 设置页面

## Technical Details

### 多因素预测融合
```swift
// 扩展 ForecastEngine
func predictWithLifestyle(
    skinHistory: [Double],
    lifestyleFactors: [LifestyleFactors],
    days: [Int]
) -> TrendForecast? {
    // 1. 基础皮肤趋势预测
    let baseForecast = forecast(values: skinHistory, days: days, horizon: 7, metric: "综合")

    // 2. 生活方式相关性调整
    let sleepCorrelation = calculateLifestyleImpact(.sleep, lifestyleFactors)
    let stressCorrelation = calculateLifestyleImpact(.stress, lifestyleFactors)

    // 3. 调整预测值
    return adjustForecast(baseForecast, sleepImpact: sleepCorrelation, stressImpact: stressCorrelation)
}
```

## Risks & Mitigations
| 风险 | 缓解措施 |
|------|----------|
| 预测不准确引起焦虑 | 明确显示置信度，强调"仅供参考" |
| 通知过多打扰用户 | 仅 high severity 推送，其他仅 in-app 显示 |
| 数据不足预测失效 | 最少3个数据点才启用预测 |

## References
- `ForecastEngine.swift:26-90` - 线性回归预测
- `ForecastEngine.swift:100-132` - predictAcneTrend 方法
- `AnalyticsVisualizationViews.swift:15-129` - ForecastChartView
- `StreakNotificationService.swift` - 通知服务模式
