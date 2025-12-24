//
//  ForecastEngine.swift
//  SkinLab
//
//  趋势预测引擎
//  使用线性回归和统计方法进行皮肤健康趋势预测
//

import Foundation

/// 趋势预测引擎
struct ForecastEngine {
    
    private let analyzer = TimeSeriesAnalyzer()
    
    // MARK: - Forecast Methods
    
    /// 生成趋势预测
    /// - Parameters:
    ///   - values: 历史数值序列
    ///   - days: 对应的天数序列
    ///   - horizon: 预测未来天数
    ///   - metric: 指标名称
    ///   - confidenceLevel: 置信水平 (0.8, 0.9, 0.95等)
    /// - Returns: 趋势预测结果,包含预测值和置信区间
    func forecast(
        values: [Double],
        days: [Int],
        horizon: Int,
        metric: String,
        confidenceLevel: Double = 0.90
    ) -> TrendForecast? {
        
        guard values.count >= 3, values.count == days.count, horizon > 0 else {
            return nil
        }
        
        // 使用线性回归进行预测
        let (slope, intercept, rSquared) = linearRegression(x: days.map { Double($0) }, y: values)
        
        // 计算残差标准误
        let residuals = calculateResiduals(x: days.map { Double($0) }, y: values, slope: slope, intercept: intercept)
        let standardError = analyzer.standardDeviation(residuals)
        
        // 计算置信区间的t值 (简化为2.0,适用于大多数情况)
        let tValue = getTValue(confidenceLevel: confidenceLevel, degreesOfFreedom: values.count - 2)
        
        // 生成预测点
        let lastDay = days.max() ?? 0
        let lastDate = Date()
        var forecastPoints: [ForecastPoint] = []
        
        for i in 1...horizon {
            let futureDay = lastDay + i
            let futureDate = Calendar.current.date(byAdding: .day, value: i, to: lastDate) ?? lastDate
            
            // 预测值
            let predictedValue = slope * Double(futureDay) + intercept
            
            // 预测区间宽度随时间增加而增大
            let distanceFromMean = Double(i)
            let intervalWidth = tValue * standardError * sqrt(1 + 1.0 / Double(values.count) + pow(distanceFromMean, 2) / sumSquaredDeviations(days.map { Double($0) }))
            
            // 预测上下界
            let lowerBound = max(0, predictedValue - intervalWidth)
            let upperBound = min(100, predictedValue + intervalWidth)
            
            forecastPoints.append(ForecastPoint(
                day: futureDay,
                date: futureDate,
                predictedValue: max(0, min(100, predictedValue)),
                lowerBound: lowerBound,
                upperBound: upperBound
            ))
        }
        
        // 计算预测置信度
        let confidence = calculateForecastConfidence(
            rSquared: rSquared,
            sampleSize: values.count,
            standardError: standardError
        )
        
        return TrendForecast(
            metric: metric,
            horizonDays: horizon,
            points: forecastPoints,
            confidence: confidence
        )
    }
    
    // MARK: - Acne Prediction
    
    /// 痤疮趋势预测 (专门针对痘痘问题的预测)
    /// - Parameters:
    ///   - acneHistory: 痘痘历史数据 (0-10分)
    ///   - days: 对应的天数
    ///   - horizon: 预测天数
    /// - Returns: 痘痘预测结果及风险等级
    func predictAcneTrend(
        acneHistory: [Double],
        days: [Int],
        horizon: Int = 7
    ) -> (forecast: TrendForecast?, riskLevel: RiskLevel) {
        
        guard let forecast = self.forecast(
            values: acneHistory,
            days: days,
            horizon: horizon,
            metric: "痘痘"
        ) else {
            return (nil, .unknown)
        }
        
        // 评估风险等级
        let recentTrend = analyzer.slope(acneHistory)
        let lastValue = acneHistory.last ?? 0
        let predictedValue = forecast.points.last?.predictedValue ?? 0
        
        let riskLevel: RiskLevel
        if predictedValue >= 7 && recentTrend > 0.3 {
            riskLevel = .high
        } else if predictedValue >= 5 || (predictedValue >= 4 && recentTrend > 0.2) {
            riskLevel = .medium
        } else if lastValue >= 6 {
            riskLevel = .medium
        } else {
            riskLevel = .low
        }
        
        return (forecast, riskLevel)
    }
    
    // MARK: - Sensitivity Prediction
    
    /// 敏感性趋势预测 (考虑季节性因素)
    /// - Parameters:
    ///   - sensitivityHistory: 敏感性历史数据
    ///   - dates: 对应的日期
    ///   - horizon: 预测天数
    ///   - currentSeason: 当前季节
    /// - Returns: 敏感性预测结果
    func predictSensitivityTrend(
        sensitivityHistory: [Double],
        dates: [Date],
        horizon: Int = 14,
        currentSeason: Season
    ) -> TrendForecast? {
        
        guard sensitivityHistory.count >= 3 else { return nil }
        
        // 应用季节性调整
        let seasonalAdjustment = getSeasonalAdjustment(for: currentSeason)
        let days = dates.enumerated().map { $0.offset }
        
        let forecast = self.forecast(
            values: sensitivityHistory,
            days: days,
            horizon: horizon,
            metric: "敏感度"
        )
        
        // 对预测值应用季节性调整
        if let forecast = forecast {
            let adjustedPoints = forecast.points.map { point in
                ForecastPoint(
                    day: point.day,
                    date: point.date,
                    predictedValue: min(10, max(0, point.predictedValue + seasonalAdjustment)),
                    lowerBound: min(10, max(0, point.lowerBound + seasonalAdjustment)),
                    upperBound: min(10, max(0, point.upperBound + seasonalAdjustment))
                )
            }
            
            return TrendForecast(
                metric: forecast.metric,
                horizonDays: forecast.horizonDays,
                points: adjustedPoints,
                confidence: forecast.confidence
            )
        }
        
        return nil
    }
    
    // MARK: - Linear Regression
    
    /// 线性回归计算
    /// - Parameters:
    ///   - x: 自变量序列
    ///   - y: 因变量序列
    /// - Returns: (斜率, 截距, R²)
    private func linearRegression(x: [Double], y: [Double]) -> (slope: Double, intercept: Double, rSquared: Double) {
        guard x.count == y.count, x.count >= 2 else {
            return (0, 0, 0)
        }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map { $0 * $1 }.reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n
        
        // 计算R²
        let meanY = sumY / n
        let ssTot = sumY2 - n * meanY * meanY
        let ssRes = y.enumerated().map { i, yi in
            let predicted = slope * x[i] + intercept
            return pow(yi - predicted, 2)
        }.reduce(0.0 as Double, +)
        
        let rSquared = ssTot > 0 ? 1 - (ssRes / ssTot) : 0
        
        return (slope, intercept, max(0, rSquared))
    }
    
    /// 计算残差
    private func calculateResiduals(x: [Double], y: [Double], slope: Double, intercept: Double) -> [Double] {
        return zip(x, y).map { xi, yi in
            let predicted = slope * xi + intercept
            return yi - predicted
        }
    }
    
    /// 计算平方偏差和
    private func sumSquaredDeviations(_ values: [Double]) -> Double {
        let mean = analyzer.mean(values)
        return values.map { pow($0 - mean, 2) }.reduce(0, +)
    }
    
    // MARK: - Confidence Calculation
    
    /// 计算预测置信度
    private func calculateForecastConfidence(
        rSquared: Double,
        sampleSize: Int,
        standardError: Double
    ) -> ConfidenceScore {
        
        // 综合考虑拟合优度、样本量和误差
        var confidenceValue: Double = 0
        
        // R²贡献 (最多0.4)
        confidenceValue += rSquared * 0.4
        
        // 样本量贡献 (最多0.3)
        let sizeScore = min(1.0, Double(sampleSize) / 10.0)
        confidenceValue += sizeScore * 0.3
        
        // 误差贡献 (最多0.3)
        let errorScore = max(0, 1.0 - standardError / 10.0)
        confidenceValue += errorScore * 0.3
        
        return ConfidenceScore(
            value: max(0, min(1, confidenceValue)),
            sampleCount: sampleSize,
            method: "regression"
        )
    }
    
    /// 获取t值 (简化版,实际应用可查表)
    private func getTValue(confidenceLevel: Double, degreesOfFreedom: Int) -> Double {
        // 简化处理,使用常见的t值
        if confidenceLevel >= 0.95 {
            return 2.0
        } else if confidenceLevel >= 0.90 {
            return 1.7
        } else {
            return 1.5
        }
    }
    
    /// 获取季节性调整值
    private func getSeasonalAdjustment(for season: Season) -> Double {
        switch season {
        case .spring: return 0.5   // 春季敏感度略高
        case .summer: return -0.3  // 夏季可能略低
        case .autumn: return 0.2   // 秋季轻微增加
        case .winter: return 0.8   // 冬季敏感度较高
        }
    }
    
    // MARK: - Supporting Types
    
    enum RiskLevel: String, Codable {
        case low = "低风险"
        case medium = "中风险"
        case high = "高风险"
        case unknown = "未知"
    }
    
    enum Season: String, Codable {
        case spring = "春"
        case summer = "夏"
        case autumn = "秋"
        case winter = "冬"
        
        static func current() -> Season {
            let month = Calendar.current.component(.month, from: Date())
            switch month {
            case 3...5: return .spring
            case 6...8: return .summer
            case 9...11: return .autumn
            default: return .winter
            }
        }
    }
}
