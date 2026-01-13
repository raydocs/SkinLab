//
//  TimeSeriesAnalyzer.swift
//  SkinLab
//
//  时间序列分析工具
//  提供趋势分析、平滑处理、斜率计算和波动性评估
//

import Foundation

/// 时间序列分析器
struct TimeSeriesAnalyzer {
    
    // MARK: - Moving Average
    
    /// 计算移动平均值 (Simple Moving Average)
    /// - Parameters:
    ///   - values: 原始数值序列
    ///   - window: 窗口大小
    /// - Returns: 平滑后的数值序列
    func movingAverage(_ values: [Double], window: Int) -> [Double] {
        guard values.count >= window else { return values }
        
        var result: [Double] = []
        
        for i in 0..<values.count {
            let start = max(0, i - window + 1)
            let end = i + 1
            let windowValues = Array(values[start..<end])
            let avg = windowValues.reduce(0, +) / Double(windowValues.count)
            result.append(avg)
        }
        
        return result
    }
    
    /// 计算指数移动平均 (Exponential Moving Average)
    /// - Parameters:
    ///   - values: 原始数值序列
    ///   - alpha: 平滑系数 (0-1, 值越大越接近原始数据)
    /// - Returns: 平滑后的数值序列
    func exponentialMovingAverage(_ values: [Double], alpha: Double = 0.3) -> [Double] {
        guard !values.isEmpty else { return [] }
        
        var result: [Double] = [values[0]]
        
        for i in 1..<values.count {
            let ema = alpha * values[i] + (1 - alpha) * result[i - 1]
            result.append(ema)
        }
        
        return result
    }
    
    // MARK: - Trend Analysis
    
    /// 计算线性回归斜率 (Ordinary Least Squares)
    /// - Parameter values: 数值序列
    /// - Returns: 斜率值 (正值表示上升,负值表示下降)
    func slope(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }
        
        let n = Double(values.count)
        let x = Array(0..<values.count).map { Double($0) }
        let y = values
        
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map { $0 * $1 }.reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        
        return slope
    }
    
    /// 计算R² (决定系数,衡量拟合优度)
    /// - Parameter values: 数值序列
    /// - Returns: R²值 (0-1, 越接近1拟合越好)
    func rSquared(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }
        
        let meanY = mean(values)
        let slope = self.slope(values)
        let intercept = meanY - slope * Double(values.count - 1) / 2.0
        
        var ssTot: Double = 0
        var ssRes: Double = 0
        
        for i in 0..<values.count {
            let predicted = slope * Double(i) + intercept
            ssTot += pow(values[i] - meanY, 2)
            ssRes += pow(values[i] - predicted, 2)
        }
        
        return ssTot > 0 ? 1 - (ssRes / ssTot) : 0
    }
    
    // MARK: - Volatility
    
    /// 计算波动性 (基于标准差)
    /// - Parameter values: 数值序列
    /// - Returns: 波动性指标 (0-1)
    func volatility(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }
        
        let std = standardDeviation(values)
        let avg = mean(values)
        
        // 变异系数 (Coefficient of Variation)
        let cv = avg != 0 ? std / abs(avg) : 0
        
        // 归一化到 0-1
        return min(cv, 1.0)
    }
    
    /// 计算最大回撤 (Maximum Drawdown)
    /// - Parameter values: 数值序列
    /// - Returns: 最大回撤百分比
    func maxDrawdown(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }
        
        var peak = values[0]
        var maxDD: Double = 0
        
        for value in values {
            if value > peak {
                peak = value
            }
            let drawdown = (peak - value) / peak
            maxDD = max(maxDD, drawdown)
        }
        
        return maxDD * 100
    }
    
    // MARK: - Statistical Functions
    
    /// 计算均值
    func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    /// 计算中位数
    func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        
        if sorted.count % 2 == 0 {
            return (sorted[mid - 1] + sorted[mid]) / 2
        } else {
            return sorted[mid]
        }
    }
    
    /// 计算标准差
    func standardDeviation(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }
        
        let avg = mean(values)
        let sumSquaredDiffs = values.map { pow($0 - avg, 2) }.reduce(0, +)
        let variance = sumSquaredDiffs / Double(values.count - 1)
        
        return sqrt(variance)
    }
    
    /// 计算中位数绝对偏差 (MAD - Median Absolute Deviation)
    func medianAbsoluteDeviation(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        
        let med = median(values)
        let absoluteDeviations = values.map { abs($0 - med) }
        return median(absoluteDeviations)
    }
    
    // MARK: - Data Quality
    
    /// 计算统计指标汇总
    func calculateStatistics(_ values: [Double]) -> StatisticalMetrics {
        guard !values.isEmpty else {
            return StatisticalMetrics(
                mean: 0,
                standardDeviation: 0,
                median: 0,
                min: 0,
                max: 0
            )
        }
        
        return StatisticalMetrics(
            mean: mean(values),
            standardDeviation: standardDeviation(values),
            median: median(values),
            min: values.min() ?? 0,
            max: values.max() ?? 0
        )
    }
    
    /// 检测数据间隔的一致性
    /// - Parameter dates: 日期序列
    /// - Returns: (平均间隔天数, 间隔标准差)
    func analyzeIntervalConsistency(_ dates: [Date]) -> (avgInterval: Double, stdInterval: Double) {
        guard dates.count >= 2 else { return (0, 0) }
        
        let sortedDates = dates.sorted()
        var intervals: [Double] = []
        
        for i in 1..<sortedDates.count {
            let interval = sortedDates[i].timeIntervalSince(sortedDates[i - 1]) / 86400.0
            intervals.append(interval)
        }
        
        return (mean(intervals), standardDeviation(intervals))
    }
    
    // MARK: - Correlation Methods
    
    /// Calculate Pearson correlation coefficient (linear correlation)
    func pearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count, x.count >= 2 else { return 0 }
        
        let n = Double(x.count)
        let meanX = mean(x)
        let meanY = mean(y)
        
        var numerator: Double = 0
        var sumSqX: Double = 0
        var sumSqY: Double = 0
        
        for i in 0..<x.count {
            let dx = x[i] - meanX
            let dy = y[i] - meanY
            numerator += dx * dy
            sumSqX += dx * dx
            sumSqY += dy * dy
        }
        
        let denominator = sqrt(sumSqX * sumSqY)
        return denominator > 0 ? numerator / denominator : 0
    }
    
    /// Calculate Spearman rank correlation (robust to outliers)
    func spearmanCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count, x.count >= 2 else { return 0 }
        
        let rankX = rank(x)
        let rankY = rank(y)
        
        return pearsonCorrelation(rankX, rankY)
    }
    
    /// Convert values to ranks (with tie handling)
    private func rank(_ values: [Double]) -> [Double] {
        let sorted = values.enumerated().sorted { $0.element < $1.element }
        var ranks = [Double](repeating: 0, count: values.count)

        var i = 0
        while i < sorted.count {
            var j = i
            while j < sorted.count && sorted[j].element == sorted[i].element {
                j += 1
            }

            let avgRank = (Double(i + 1) + Double(j)) / 2.0
            for k in i..<j {
                ranks[sorted[k].offset] = avgRank
            }

            i = j
        }

        return ranks
    }
}
