//
//  AnomalyDetector.swift
//  SkinLab
//
//  异常检测工具
//  使用统计方法检测时间序列数据中的异常值,提升数据可靠性
//

import Foundation

/// 异常检测器
struct AnomalyDetector {
    
    private let analyzer = TimeSeriesAnalyzer()
    
    // MARK: - Detection Methods
    
    /// 检测时间序列中的异常点
    /// - Parameters:
    ///   - values: 数值序列
    ///   - days: 对应的天数序列
    ///   - dates: 对应的日期序列
    ///   - metric: 指标名称
    ///   - method: 检测方法 ("zscore", "mad", "iqr")
    ///   - threshold: 阈值倍数
    /// - Returns: 异常点列表
    func detect(
        values: [Double],
        days: [Int],
        dates: [Date],
        metric: String,
        method: DetectionMethod = .mad,
        threshold: Double = 2.5
    ) -> [AnomalyDetectionResult] {
        
        guard values.count == days.count,
              values.count == dates.count,
              values.count >= 3 else {
            return []
        }
        
        switch method {
        case .zscore:
            return detectWithZScore(values: values, days: days, dates: dates, metric: metric, threshold: threshold)
        case .mad:
            return detectWithMAD(values: values, days: days, dates: dates, metric: metric, threshold: threshold)
        case .iqr:
            return detectWithIQR(values: values, days: days, dates: dates, metric: metric)
        }
    }
    
    // MARK: - Z-Score Method
    
    /// 使用Z-Score方法检测异常 (适用于正态分布数据)
    private func detectWithZScore(
        values: [Double],
        days: [Int],
        dates: [Date],
        metric: String,
        threshold: Double
    ) -> [AnomalyDetectionResult] {
        
        let mean = analyzer.mean(values)
        let std = analyzer.standardDeviation(values)
        
        guard std > 0 else { return [] }
        
        var anomalies: [AnomalyDetectionResult] = []
        
        for i in 0..<values.count {
            let zScore = (values[i] - mean) / std
            
            if abs(zScore) > threshold {
                let severity: AnomalyDetectionResult.Severity
                if abs(zScore) > 3.5 {
                    severity = .severe
                } else if abs(zScore) > 3.0 {
                    severity = .moderate
                } else {
                    severity = .mild
                }
                
                let reason = zScore > 0
                    ? "数值异常偏高 (Z-score: \(String(format: "%.2f", zScore)))"
                    : "数值异常偏低 (Z-score: \(String(format: "%.2f", zScore)))"
                
                anomalies.append(AnomalyDetectionResult(
                    id: UUID(),
                    metric: metric,
                    day: days[i],
                    date: dates[i],
                    value: values[i],
                    zScore: zScore,
                    severity: severity,
                    reason: reason
                ))
            }
        }
        
        return anomalies
    }
    
    // MARK: - MAD Method
    
    /// 使用中位数绝对偏差(MAD)方法检测异常 (更鲁棒,适用于非正态分布)
    private func detectWithMAD(
        values: [Double],
        days: [Int],
        dates: [Date],
        metric: String,
        threshold: Double
    ) -> [AnomalyDetectionResult] {
        
        let median = analyzer.median(values)
        let mad = analyzer.medianAbsoluteDeviation(values)
        
        guard mad > 0 else { return [] }
        
        var anomalies: [AnomalyDetectionResult] = []
        
        // Modified Z-score using MAD
        let k = 1.4826 // 常数因子,使MAD与标准差一致
        
        for i in 0..<values.count {
            let modifiedZScore = k * (values[i] - median) / mad
            
            if abs(modifiedZScore) > threshold {
                let severity: AnomalyDetectionResult.Severity
                if abs(modifiedZScore) > 4.0 {
                    severity = .severe
                } else if abs(modifiedZScore) > 3.0 {
                    severity = .moderate
                } else {
                    severity = .mild
                }
                
                let reason = modifiedZScore > 0
                    ? "数值显著高于中位数 (MAD-score: \(String(format: "%.2f", modifiedZScore)))"
                    : "数值显著低于中位数 (MAD-score: \(String(format: "%.2f", modifiedZScore)))"
                
                anomalies.append(AnomalyDetectionResult(
                    id: UUID(),
                    metric: metric,
                    day: days[i],
                    date: dates[i],
                    value: values[i],
                    zScore: modifiedZScore,
                    severity: severity,
                    reason: reason
                ))
            }
        }
        
        return anomalies
    }
    
    // MARK: - IQR Method
    
    /// 使用四分位距(IQR)方法检测异常
    private func detectWithIQR(
        values: [Double],
        days: [Int],
        dates: [Date],
        metric: String
    ) -> [AnomalyDetectionResult] {
        
        let sorted = values.sorted()
        let n = sorted.count
        
        // 计算Q1和Q3
        let q1Index = n / 4
        let q3Index = (3 * n) / 4
        let q1 = sorted[q1Index]
        let q3 = sorted[q3Index]
        let iqr = q3 - q1
        
        guard iqr > 0 else { return [] }
        
        // 异常值边界
        let lowerBound = q1 - 1.5 * iqr
        let upperBound = q3 + 1.5 * iqr
        let extremeLowerBound = q1 - 3.0 * iqr
        let extremeUpperBound = q3 + 3.0 * iqr
        
        var anomalies: [AnomalyDetectionResult] = []
        
        for i in 0..<values.count {
            let value = values[i]
            
            if value < lowerBound || value > upperBound {
                let severity: AnomalyDetectionResult.Severity
                if value < extremeLowerBound || value > extremeUpperBound {
                    severity = .severe
                } else {
                    severity = .mild
                }
                
                let reason = value > upperBound
                    ? "数值超出正常上限 (Q3 + 1.5×IQR: \(String(format: "%.1f", upperBound)))"
                    : "数值低于正常下限 (Q1 - 1.5×IQR: \(String(format: "%.1f", lowerBound)))"
                
                // 计算归一化的Z-score (用于统一接口)
                let mean = analyzer.mean(values)
                let std = analyzer.standardDeviation(values)
                let zScore = std > 0 ? (value - mean) / std : 0
                
                anomalies.append(AnomalyDetectionResult(
                    id: UUID(),
                    metric: metric,
                    day: days[i],
                    date: dates[i],
                    value: value,
                    zScore: zScore,
                    severity: severity,
                    reason: reason
                ))
            }
        }
        
        return anomalies
    }
    
    // MARK: - Jump Detection
    
    /// 检测突变点 (相邻点之间的异常跳变)
    /// - Parameters:
    ///   - values: 数值序列
    ///   - days: 对应的天数序列
    ///   - dates: 对应的日期序列
    ///   - metric: 指标名称
    ///   - threshold: 跳变阈值(相对于平均绝对变化量的倍数)
    /// - Returns: 突变点列表
    func detectJumps(
        values: [Double],
        days: [Int],
        dates: [Date],
        metric: String,
        threshold: Double = 3.0
    ) -> [AnomalyDetectionResult] {
        
        guard values.count >= 3 else { return [] }
        
        // 计算相邻点差值
        var diffs: [Double] = []
        for i in 1..<values.count {
            diffs.append(abs(values[i] - values[i - 1]))
        }
        
        let meanDiff = analyzer.mean(diffs)
        let stdDiff = analyzer.standardDeviation(diffs)
        
        guard stdDiff > 0 else { return [] }
        
        var jumps: [AnomalyDetectionResult] = []
        
        for i in 1..<values.count {
            let diff = abs(values[i] - values[i - 1])
            let zScore = (diff - meanDiff) / stdDiff
            
            if zScore > threshold {
                let severity: AnomalyDetectionResult.Severity = zScore > 5.0 ? .severe : .moderate
                let direction = values[i] > values[i - 1] ? "突增" : "突降"
                let reason = "数值(direction) (变化量: \(String(format: "%.1f", diff)), Z-score: \(String(format: "%.2f", zScore)))"
                
                jumps.append(AnomalyDetectionResult(
                    id: UUID(),
                    metric: metric,
                    day: days[i],
                    date: dates[i],
                    value: values[i],
                    zScore: zScore,
                    severity: severity,
                    reason: reason
                ))
            }
        }
        
        return jumps
    }
    
    // MARK: - Data Quality Assessment
    
    /// 评估数据质量
    /// - Parameter values: 数值序列
    /// - Returns: (质量分数 0-1, 质量描述)
    func assessDataQuality(values: [Double]) -> (score: Double, description: String) {
        guard values.count >= 3 else {
            return (0.0, "样本量不足")
        }
        
        let stats = analyzer.calculateStatistics(values)
        let cv = stats.coefficientOfVariation
        let sampleSize = values.count
        
        // 质量分数综合考虑样本量和稳定性
        var score: Double = 0
        
        // 样本量贡献 (最多0.5分)
        let sizeScore = min(0.5, Double(sampleSize) / 20.0 * 0.5)
        score += sizeScore
        
        // 稳定性贡献 (最多0.5分)
        let stabilityScore: Double
        if cv < 0.1 {
            stabilityScore = 0.5
        } else if cv < 0.2 {
            stabilityScore = 0.4
        } else if cv < 0.3 {
            stabilityScore = 0.3
        } else {
            stabilityScore = 0.2
        }
        score += stabilityScore
        
        let description: String
        if score >= 0.8 {
            description = "数据质量优秀"
        } else if score >= 0.6 {
            description = "数据质量良好"
        } else if score >= 0.4 {
            description = "数据质量一般"
        } else {
            description = "数据质量较差"
        }
        
        return (score, description)
    }
    
    // MARK: - Detection Method Enum
    
    enum DetectionMethod {
        case zscore  // Z-Score方法 (适用于正态分布)
        case mad     // MAD方法 (鲁棒性更好)
        case iqr     // IQR方法 (四分位距)
    }
}
