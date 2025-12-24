//
//  TrendAnalyticsModels.swift
//  SkinLab
//
//  AI-Enhanced Trend Analytics Models
//  支持时间序列分析、异常检测、预测模型、热力图和季节性分析
//

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
        case 0.8...1.0: return .high
        case 0.6..<0.8: return .medium
        case 0.4..<0.6: return .low
        default: return .veryLow
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
    
    /// 风险预警
    var riskAlert: String? {
        // 针对痘痘、泛红等指标的风险预警
        guard let last = points.last else { return nil }
        
        if metric == "痘痘" && last.predictedValue >= 6.0 && trendDirection == "上升" {
            return "痘痘风险较高,建议加强清洁和护理"
        }
        if metric == "泛红" && last.predictedValue >= 6.0 && trendDirection == "上升" {
            return "泛红风险较高,注意保湿和舒缓"
        }
        if metric == "综合评分" && last.predictedValue < 50 && trendDirection == "下降" {
            return "皮肤状态趋于恶化,建议调整护肤方案"
        }
        
        return nil
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
        Array(Set(cells.map { $0.dimension })).sorted()
    }
    
    /// 天数列表(去重后)
    var days: [Int] {
        Array(Set(cells.map { $0.day })).sorted()
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
        
        return "(season)季节泛红(rednessLevel),敏感度(sensitivityLevel)。"
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
    
    /// 效果等级
    var effectLevel: EffectLevel {
        switch effectivenessScore {
        case 0.5...1.0: return .highlyEffective
        case 0.2..<0.5: return .effective
        case -0.2..<0.2: return .neutral
        case -0.5..<(-0.2): return .ineffective
        default: return .harmful
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
        return "(productName) (effectLevel.rawValue)(置信度:(confidence.level.rawValue))。主要因素:(factorsText)。"
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
