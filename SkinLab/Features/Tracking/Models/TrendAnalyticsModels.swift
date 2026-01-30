import Foundation

// MARK: - Confidence Score

/// 置信度评分,用于量化分析结果的可靠性
struct ConfidenceScore: Codable, Sendable {
    /// 置信度值 (0-1)
    let value: Double

    /// 样本数量
    let sampleCount: Int

    /// 计算方法 ("mad", "regression", "bayes-lite")
    let method: String

    /// 置信度等级
    var level: ConfidenceLevel {
        switch value {
        case 0.8 ... 1.0: .high
        case 0.6 ..< 0.8: .medium
        case 0.4 ..< 0.6: .low
        default: .veryLow
        }
    }

    enum ConfidenceLevel: String, Codable, Sendable {
        case high = "高"
        case medium = "中等"
        case low = "较低"
        case veryLow = "非常低"
    }
}

// MARK: - Anomaly Detection

/// 异常检测结果,标识数据中的异常点
struct AnomalyDetectionResult: Codable, Identifiable, Sendable {
    let id: UUID

    /// 指标名称 ("acne", "redness", "overallScore")
    let metric: String

    /// 异常发生的天数
    let day: Int

    /// 异常发生的日期
    let date: Date

    /// 异常值
    let value: Double

    /// Z-score (标准分数)
    let zScore: Double

    /// 异常严重程度
    let severity: Severity

    /// 异常原因说明
    let reason: String

    enum Severity: String, Codable, Sendable {
        case mild = "轻度"
        case moderate = "中度"
        case severe = "严重"
    }

    /// 异常标签
    var label: String {
        "(metric) (severity.rawValue)异常"
    }
}

// MARK: - Trend Forecasting

/// 预测点数据
struct ForecastPoint: Codable, Identifiable, Sendable {
    let id: UUID

    /// 预测的天数
    let day: Int

    /// 预测的日期
    let date: Date

    /// 预测值
    let predictedValue: Double

    /// 预测下界 (置信区间)
    let lowerBound: Double

    /// 预测上界 (置信区间)
    let upperBound: Double

    init(day: Int, date: Date, predictedValue: Double, lowerBound: Double, upperBound: Double) {
        self.id = UUID()
        self.day = day
        self.date = date
        self.predictedValue = predictedValue
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }
}

/// 趋势预测结果
struct TrendForecast: Codable, Sendable {
    /// 预测的指标
    let metric: String

    /// 预测时间跨度(天)
    let horizonDays: Int

    /// 预测点列表
    let points: [ForecastPoint]

    /// 预测置信度
    let confidence: ConfidenceScore

    /// 预测趋势方向
    var trendDirection: String {
        guard let first = points.first, let last = points.last else { return "未知" }
        let change = last.predictedValue - first.predictedValue
        if abs(change) < 0.5 { return "稳定" }
        return change > 0 ? "上升" : "下降"
    }

    /// 风险预警 - 基于预测结果生成预测性护肤预警
    var riskAlert: PredictiveAlert? {
        guard let last = points.last, let first = points.first else { return nil }

        let predictedChange = last.predictedValue - first.predictedValue
        let predictedDate = last.date

        switch metric {
        case "痘痘", "acne":
            return generateAcneAlert(
                predictedValue: last.predictedValue,
                change: predictedChange,
                predictedDate: predictedDate
            )

        case "泛红", "redness":
            return generateRednessAlert(
                predictedValue: last.predictedValue,
                change: predictedChange,
                predictedDate: predictedDate
            )

        case "综合评分", "overall", "overallScore":
            return generateOverallScoreAlert(
                predictedValue: last.predictedValue,
                change: predictedChange,
                predictedDate: predictedDate
            )

        case "敏感度", "sensitivity":
            return generateSensitivityAlert(
                predictedValue: last.predictedValue,
                change: predictedChange,
                predictedDate: predictedDate
            )

        default:
            return nil
        }
    }

    // MARK: - Alert Generation Helpers

    /// 生成痘痘风险预警
    private func generateAcneAlert(
        predictedValue: Double,
        change: Double,
        predictedDate: Date
    ) -> PredictiveAlert? {
        // 痘痘指标: 值越高越严重 (0-10)
        // 高风险: 预测值 >= 7 且上升 >= 2
        // 中等风险: 预测值 >= 5 且上升 >= 1
        // 低风险: 预测值 >= 4 且上升

        if predictedValue >= 7, change >= 2 {
            return PredictiveAlert(
                metric: "痘痘",
                severity: .high,
                message: "痘痘问题可能显著加重",
                actionSuggestion: "建议立即加强清洁,使用含水杨酸的产品,避免高糖饮食和熬夜",
                predictedDate: predictedDate,
                confidence: confidence
            )
        } else if predictedValue >= 5, change >= 1 {
            return PredictiveAlert(
                metric: "痘痘",
                severity: .medium,
                message: "痘痘有加重趋势",
                actionSuggestion: "注意面部清洁,减少油腻食物摄入,保持规律作息",
                predictedDate: predictedDate,
                confidence: confidence
            )
        } else if predictedValue >= 4, change > 0 {
            return PredictiveAlert(
                metric: "痘痘",
                severity: .low,
                message: "痘痘状况需要关注",
                actionSuggestion: "保持当前护肤习惯,注意观察皮肤变化",
                predictedDate: predictedDate,
                confidence: confidence
            )
        }

        return nil
    }

    /// 生成泛红风险预警
    private func generateRednessAlert(
        predictedValue: Double,
        change: Double,
        predictedDate: Date
    ) -> PredictiveAlert? {
        // 泛红指标: 值越高越严重 (0-10)
        // 高风险: 预测值 >= 7 且上升 >= 2
        // 中等风险: 预测值 >= 5 且上升 >= 1
        // 低风险: 预测值 >= 4 且上升

        if predictedValue >= 7, change >= 2 {
            return PredictiveAlert(
                metric: "泛红",
                severity: .high,
                message: "泛红问题可能显著加重",
                actionSuggestion: "立即使用舒缓修复产品,避免刺激性成分,外出做好防晒",
                predictedDate: predictedDate,
                confidence: confidence
            )
        } else if predictedValue >= 5, change >= 1 {
            return PredictiveAlert(
                metric: "泛红",
                severity: .medium,
                message: "泛红有加重趋势",
                actionSuggestion: "加强保湿补水,使用温和型护肤品,避免过度清洁",
                predictedDate: predictedDate,
                confidence: confidence
            )
        } else if predictedValue >= 4, change > 0 {
            return PredictiveAlert(
                metric: "泛红",
                severity: .low,
                message: "泛红状况需要关注",
                actionSuggestion: "注意皮肤保湿,避免冷热刺激",
                predictedDate: predictedDate,
                confidence: confidence
            )
        }

        return nil
    }

    /// 生成综合评分下降预警
    private func generateOverallScoreAlert(
        predictedValue: Double,
        change: Double,
        predictedDate: Date
    ) -> PredictiveAlert? {
        // 综合评分: 值越高越好 (0-100)
        // 高风险: 预测值 < 40 且下降 >= 15
        // 中等风险: 预测值 < 50 且下降 >= 10
        // 低风险: 预测值 < 60 且下降 >= 5

        if predictedValue < 40, change <= -15 {
            return PredictiveAlert(
                metric: "综合评分",
                severity: .high,
                message: "皮肤状态可能明显恶化",
                actionSuggestion: "建议调整护肤方案,检查近期使用的新产品,考虑咨询皮肤科医生",
                predictedDate: predictedDate,
                confidence: confidence
            )
        } else if predictedValue < 50, change <= -10 {
            return PredictiveAlert(
                metric: "综合评分",
                severity: .medium,
                message: "皮肤状态呈下降趋势",
                actionSuggestion: "回顾近期护肤习惯和生活作息,适当简化护肤步骤",
                predictedDate: predictedDate,
                confidence: confidence
            )
        } else if predictedValue < 60, change <= -5 {
            return PredictiveAlert(
                metric: "综合评分",
                severity: .low,
                message: "皮肤状态略有下降",
                actionSuggestion: "保持健康作息,注意饮食均衡和充足睡眠",
                predictedDate: predictedDate,
                confidence: confidence
            )
        }

        return nil
    }

    /// 生成敏感度上升预警
    private func generateSensitivityAlert(
        predictedValue: Double,
        change: Double,
        predictedDate: Date
    ) -> PredictiveAlert? {
        // 敏感度指标: 值越高越敏感 (0-10)
        // 高风险: 预测值 >= 7 且上升 >= 2
        // 中等风险: 预测值 >= 5 且上升 >= 1
        // 低风险: 预测值 >= 4 且上升

        if predictedValue >= 7, change >= 2 {
            return PredictiveAlert(
                metric: "敏感度",
                severity: .high,
                message: "皮肤敏感度可能显著增加",
                actionSuggestion: "暂停使用功效型产品,只用温和的基础保湿,避免更换护肤品",
                predictedDate: predictedDate,
                confidence: confidence
            )
        } else if predictedValue >= 5, change >= 1 {
            return PredictiveAlert(
                metric: "敏感度",
                severity: .medium,
                message: "皮肤敏感度有上升趋势",
                actionSuggestion: "减少护肤步骤,选择无香精无酒精的产品,加强屏障修复",
                predictedDate: predictedDate,
                confidence: confidence
            )
        } else if predictedValue >= 4, change > 0 {
            return PredictiveAlert(
                metric: "敏感度",
                severity: .low,
                message: "皮肤敏感度需要关注",
                actionSuggestion: "注意观察皮肤反应,避免使用刺激性成分",
                predictedDate: predictedDate,
                confidence: confidence
            )
        }

        return nil
    }
}

// MARK: - Predictive Alerts

/// 预警严重程度等级
enum AlertSeverity: String, Codable, Sendable {
    case low = "提醒"
    case medium = "注意"
    case high = "警告"

    /// 显示图标
    var icon: String {
        switch self {
        case .low: "info.circle.fill"
        case .medium: "exclamationmark.triangle.fill"
        case .high: "exclamationmark.octagon.fill"
        }
    }

    /// 主题颜色名称 (用于 Color(colorName))
    var colorName: String {
        switch self {
        case .low: "blue"
        case .medium: "orange"
        case .high: "red"
        }
    }
}

/// 预测性护肤预警
/// 基于趋势分析预测未来可能出现的皮肤问题
struct PredictiveAlert: Codable, Identifiable, Sendable {
    let id: UUID

    /// 预警相关指标 ("痘痘", "泛红", "综合评分", "敏感度")
    let metric: String

    /// 预警严重程度
    let severity: AlertSeverity

    /// 预警消息
    let message: String

    /// 行动建议
    let actionSuggestion: String

    /// 预测发生日期
    let predictedDate: Date

    /// 预测置信度
    let confidence: ConfidenceScore

    init(
        id: UUID = UUID(),
        metric: String,
        severity: AlertSeverity,
        message: String,
        actionSuggestion: String,
        predictedDate: Date,
        confidence: ConfidenceScore
    ) {
        self.id = id
        self.metric = metric
        self.severity = severity
        self.message = message
        self.actionSuggestion = actionSuggestion
        self.predictedDate = predictedDate
        self.confidence = confidence
    }

    /// 显示图标
    var icon: String {
        severity.icon
    }

    /// 主题颜色名称
    var colorName: String {
        severity.colorName
    }

    /// 预测距今天数
    var daysFromNow: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: predictedDate).day ?? 0
    }

    /// 格式化的预测日期文本
    var predictedDateText: String {
        let days = daysFromNow
        if days == 0 {
            return "今天"
        } else if days == 1 {
            return "明天"
        } else if days > 0 {
            return "\(days)天后"
        } else {
            return "已过期"
        }
    }

    /// 完整预警标签
    var label: String {
        "[\(severity.rawValue)] \(metric): \(message)"
    }
}

// MARK: - Heatmap Data

/// 热力图单元格数据
struct HeatmapCell: Codable, Identifiable, Sendable {
    let id: UUID

    /// 天数
    let day: Int

    /// 维度名称 ("T区", "痘痘", "泛红" 等)
    let dimension: String

    /// 数值 (0-1标准化)
    let value: Double

    init(day: Int, dimension: String, value: Double) {
        self.id = UUID()
        self.day = day
        self.dimension = dimension
        self.value = value
    }
}

/// 热力图数据结构
struct HeatmapData: Codable, Sendable {
    /// 热力图标题
    let title: String

    /// 热力图单元格列表
    let cells: [HeatmapCell]

    /// 数值范围
    let valueRange: ClosedRange<Double>

    /// 维度列表(去重后)
    var dimensions: [String] {
        Array(Set(cells.map(\.dimension))).sorted()
    }

    /// 天数列表(去重后)
    var days: [Int] {
        Array(Set(cells.map(\.day))).sorted()
    }
}

// MARK: - Seasonal Patterns

/// 季节性模式分析
struct SeasonalPattern: Codable, Sendable {
    /// 季节名称
    let season: String

    /// 平均泛红指数
    let avgRedness: Double

    /// 平均敏感度
    let avgSensitivity: Double

    /// 样本数量
    let sampleCount: Int

    /// 置信度
    let confidence: ConfidenceScore

    /// 季节建议
    var recommendation: String {
        let rednessLevel = avgRedness >= 6 ? "较高" : avgRedness >= 4 ? "中等" : "较低"
        let sensitivityLevel = avgSensitivity >= 6 ? "较高" : avgSensitivity >= 4 ? "中等" : "较低"

        return "\(season)季节泛红\(rednessLevel),敏感度\(sensitivityLevel)。"
    }
}

// MARK: - Product Combination Insights

/// 产品组合分析结果
/// 用于评估多个产品同时使用时的协同效果
struct ProductCombinationInsight: Codable, Sendable {
    /// 参与组合的产品ID集合
    let productIds: Set<String>

    /// 组合效果评分 (-1 to 1)
    /// 正值表示组合使用后皮肤状态改善
    let combinedEffectScore: Double

    /// 协同/拮抗评分 (-1 to 1)
    /// 正值表示1+1>2的协同效果
    /// 负值表示1+1<2的拮抗效果
    let synergyScore: Double

    /// 组合使用次数
    let usageCount: Int

    /// 置信度
    let confidence: ConfidenceScore

    /// 协同效果等级
    var synergyLevel: SynergyLevel {
        switch synergyScore {
        case 0.3 ... 1.0: .highSynergy
        case 0.1 ..< 0.3: .mildSynergy
        case -0.1 ..< 0.1: .neutral
        case -0.3 ..< -0.1: .mildAntagonism
        default: .highAntagonism
        }
    }

    enum SynergyLevel: String, Codable, Sendable {
        case highSynergy = "高度协同"
        case mildSynergy = "轻度协同"
        case neutral = "中性"
        case mildAntagonism = "轻度拮抗"
        case highAntagonism = "明显拮抗"
    }

    /// 详细说明
    var detailedDescription: String {
        let productList = productIds.prefix(3).joined(separator: " + ")
        return "\(productList) 组合\(synergyLevel.rawValue)(置信度:\(confidence.level.rawValue))。"
    }
}

// MARK: - Product Effect Insights

/// 产品效果深度分析
struct ProductEffectInsight: Codable, Sendable {
    /// 产品ID
    let productId: String

    /// 产品名称
    let productName: String

    /// 效果评分 (-1 to 1, 负值表示恶化)
    let effectivenessScore: Double

    /// 置信度
    let confidence: ConfidenceScore

    /// 影响因素列表
    let contributingFactors: [String]

    /// 使用次数
    let usageCount: Int

    /// 平均间隔天数
    let avgDayInterval: Double

    // MARK: - Multi-Product Attribution Fields

    /// 归因权重 (0-1, 表示该产品对皮肤变化的贡献比例)
    /// 当多个产品同时使用时, > 0.4 被视为主要贡献者
    let attributionWeight: Double?

    /// 单独使用天数列表
    /// 如果为空, 表示该产品总是与其他产品一起使用
    let soloUsageDays: [Int]?

    /// 经常一起使用的产品ID列表 (按共同使用次数排序)
    let coUsedProductIds: [String]?

    /// 效果等级
    var effectLevel: EffectLevel {
        switch effectivenessScore {
        case 0.5 ... 1.0: .highlyEffective
        case 0.2 ..< 0.5: .effective
        case -0.2 ..< 0.2: .neutral
        case -0.5 ..< -0.2: .ineffective
        default: .harmful
        }
    }

    enum EffectLevel: String, Codable, Sendable {
        case highlyEffective = "非常有效"
        case effective = "有效"
        case neutral = "中性"
        case ineffective = "效果不明显"
        case harmful = "可能有害"
    }

    /// 详细说明
    var detailedDescription: String {
        let factorsText = contributingFactors.prefix(3).joined(separator: ", ")
        return "\(productName) \(effectLevel.rawValue)(置信度:\(confidence.level.rawValue))。主要因素:\(factorsText)。"
    }

    // MARK: - Attribution UI Helpers

    /// 是否为主要贡献者 (attributionWeight > 0.4)
    var isPrimaryContributor: Bool {
        guard let weight = attributionWeight else { return false }
        return weight > 0.4
    }

    /// 是否缺少单独使用数据
    var needsSoloUsageValidation: Bool {
        guard let soloUsage = soloUsageDays else { return true }
        return soloUsage.isEmpty
    }

    /// 建议单独使用天数 (用于验证效果)
    var suggestedSoloUsageDays: Int {
        // 建议至少单独使用5天以验证效果
        5
    }

    /// 归因建议文案
    var attributionSuggestion: String? {
        guard needsSoloUsageValidation else { return nil }
        return "建议单独使用\(suggestedSoloUsageDays)天以验证效果"
    }
}

// MARK: - Statistical Metrics

/// 统计指标汇总
struct StatisticalMetrics: Codable, Sendable {
    /// 均值
    let mean: Double

    /// 标准差
    let standardDeviation: Double

    /// 中位数
    let median: Double

    /// 最小值
    let min: Double

    /// 最大值
    let max: Double

    /// 变异系数 (CV)
    var coefficientOfVariation: Double {
        mean != 0 ? (standardDeviation / abs(mean)) : 0
    }

    /// 数据稳定性评级
    var stability: String {
        let cv = coefficientOfVariation
        if cv < 0.1 { return "非常稳定" }
        if cv < 0.2 { return "稳定" }
        if cv < 0.3 { return "中等波动" }
        return "波动较大"
    }
}
