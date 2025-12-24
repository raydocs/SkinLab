//
//  ProductEffectAnalyzer.swift
//  SkinLab
//
//  产品效果分析器
//  使用统计方法和用户历史数据评估产品的真实效果
//

import Foundation

/// 产品效果分析器
struct ProductEffectAnalyzer {
    
    private let analyzer = TimeSeriesAnalyzer()
    
    // MARK: - Product Effect Evaluation
    
    /// 评估产品效果
    /// - Parameters:
    ///   - checkIns: 打卡记录列表
    ///   - analyses: 分析结果字典 (key: analysisId)
    ///   - productDatabase: 产品数据库
    ///   - historyStore: 用户历史数据存储(可选)
    /// - Returns: 产品效果洞察列表
    func evaluate(
        checkIns: [CheckIn],
        analyses: [UUID: SkinAnalysis],
        productDatabase: [String: Product],
        historyStore: UserHistoryStore? = nil
    ) async -> [ProductEffectInsight] {
        
        // 收集所有使用过的产品
        var productUsageMap: [String: ProductUsageData] = [:]
        
        for (index, checkIn) in checkIns.enumerated() {
            guard let analysis = checkIn.analysisId.flatMap({ analyses[$0] }) else { continue }
            
            for productId in checkIn.usedProducts {
                if productUsageMap[productId] == nil {
                    productUsageMap[productId] = ProductUsageData(
                        productId: productId,
                        productName: productDatabase[productId]?.name ?? productId
                    )
                }
                
                productUsageMap[productId]?.addUsage(
                    day: checkIn.day,
                    overallScore: analysis.overallScore,
                    feeling: checkIn.feeling,
                    checkInIndex: index
                )
            }
        }
        
        // 分析每个产品的效果
        var insights: [ProductEffectInsight] = []
        
        for (productId, usageData) in productUsageMap {
            if let insight = await analyzeProductEffect(
                productId: productId,
                usageData: usageData,
                checkIns: checkIns,
                analyses: analyses,
                historyStore: historyStore
            ) {
                insights.append(insight)
            }
        }
        
        return insights.sorted { $0.effectivenessScore > $1.effectivenessScore }
    }
    
    // MARK: - Single Product Analysis
    
    /// 分析单个产品的效果
    private func analyzeProductEffect(
        productId: String,
        usageData: ProductUsageData,
        checkIns: [CheckIn],
        analyses: [UUID: SkinAnalysis],
        historyStore: UserHistoryStore?
    ) async -> ProductEffectInsight? {
        
        guard usageData.usageCount >= 2 else { return nil }
        
        // 计算效果评分
        let scoreChange = calculateScoreChange(usageData: usageData)
        let feelingScore = calculateFeelingScore(usageData: usageData)
        
        // 成分历史效果 (如果有历史数据)
        var ingredientScore: Double = 0
        if let historyStore = historyStore {
            ingredientScore = await calculateIngredientHistoryScore(
                productId: productId,
                historyStore: historyStore
            )
        }
        
        // 综合效果评分
        let effectivenessScore = 0.5 * scoreChange + 0.3 * feelingScore + 0.2 * ingredientScore
        
        // 计算置信度
        let confidence = calculateEffectConfidence(
            usageCount: usageData.usageCount,
            scoreVariability: usageData.scoreVariability,
            avgInterval: usageData.avgInterval
        )
        
        // 识别影响因素
        let factors = identifyContributingFactors(
            usageData: usageData,
            scoreChange: scoreChange,
            feelingScore: feelingScore
        )
        
        return ProductEffectInsight(
            productId: productId,
            productName: usageData.productName,
            effectivenessScore: max(-1, min(1, effectivenessScore)),
            confidence: confidence,
            contributingFactors: factors,
            usageCount: usageData.usageCount,
            avgDayInterval: usageData.avgInterval
        )
    }
    
    // MARK: - Score Calculation
    
    /// 计算皮肤评分变化
    private func calculateScoreChange(usageData: ProductUsageData) -> Double {
        guard usageData.scores.count >= 2 else { return 0 }
        
        // 对比使用前后的评分变化
        let scores = usageData.scores
        var improvements: [Double] = []
        
        for i in 1..<scores.count {
            let change = Double(scores[i] - scores[i - 1])
            improvements.append(change)
        }
        
        // 平均改善幅度,归一化到-1到1
        let avgImprovement = analyzer.mean(improvements) / 100.0
        return max(-1, min(1, avgImprovement))
    }
    
    /// 计算用户感受评分
    private func calculateFeelingScore(usageData: ProductUsageData) -> Double {
        let feelings = usageData.feelings
        guard !feelings.isEmpty else { return 0 }
        
        // 感受转换为数值: better=1, same=0, worse=-1
        let scores = feelings.map { feeling -> Double in
            switch feeling {
            case .better: return 1.0
            case .same: return 0.0
            case .worse: return -1.0
            }
        }
        
        return analyzer.mean(scores)
    }
    
    /// 计算成分历史效果评分
    private func calculateIngredientHistoryScore(
        productId: String,
        historyStore: UserHistoryStore
    ) async -> Double {
        
        // 获取成分统计数据
        let ingredientStats = await historyStore.getAllIngredientStats()
        
        // 简化处理:假设我们能从productId提取关键成分
        // 实际应用中需要产品成分列表
        var totalScore: Double = 0
        var count: Int = 0
        
        for (_, stat) in ingredientStats {
            if productId.lowercased().contains(stat.ingredientName.lowercased()) {
                let effectScore = (Double(stat.betterCount) - Double(stat.worseCount)) / Double(stat.totalUses)
                totalScore += effectScore
                count += 1
            }
        }
        
        return count > 0 ? (totalScore / Double(count)) : 0
    }
    
    /// 计算效果置信度
    private func calculateEffectConfidence(
        usageCount: Int,
        scoreVariability: Double,
        avgInterval: Double
    ) -> ConfidenceScore {
        
        var confidenceValue: Double = 0
        
        // 使用次数贡献 (最多0.4)
        confidenceValue += min(0.4, Double(usageCount) / 5.0 * 0.4)
        
        // 稳定性贡献 (最多0.3)
        let stabilityScore = max(0, 1.0 - scoreVariability / 20.0)
        confidenceValue += stabilityScore * 0.3
        
        // 间隔一致性贡献 (最多0.3)
        // 理想间隔是1-3天,太短或太长都会降低置信度
        let intervalScore: Double
        if avgInterval >= 1 && avgInterval <= 3 {
            intervalScore = 1.0
        } else if avgInterval < 1 {
            intervalScore = 0.5
        } else {
            intervalScore = max(0, 1.0 - (avgInterval - 3) / 7.0)
        }
        confidenceValue += intervalScore * 0.3
        
        return ConfidenceScore(
            value: max(0, min(1, confidenceValue)),
            sampleCount: usageCount,
            method: "bayes-lite"
        )
    }
    
    /// 识别影响因素
    private func identifyContributingFactors(
        usageData: ProductUsageData,
        scoreChange: Double,
        feelingScore: Double
    ) -> [String] {
        
        var factors: [String] = []
        
        // 基于评分变化
        if scoreChange > 0.3 {
            factors.append("皮肤评分明显提升")
        } else if scoreChange < -0.3 {
            factors.append("皮肤评分下降")
        }
        
        // 基于用户感受
        if feelingScore > 0.5 {
            factors.append("用户感受普遍良好")
        } else if feelingScore < -0.5 {
            factors.append("用户感受欠佳")
        }
        
        // 基于使用频率
        if usageData.usageCount >= 5 {
            factors.append("使用次数充足")
        } else {
            factors.append("使用次数较少")
        }
        
        // 基于稳定性
        if usageData.scoreVariability < 5 {
            factors.append("效果稳定")
        } else if usageData.scoreVariability > 15 {
            factors.append("效果波动较大")
        }
        
        return factors.isEmpty ? ["数据不足"] : factors
    }
}

// MARK: - Supporting Types

/// 产品使用数据
private struct ProductUsageData {
    let productId: String
    let productName: String
    var days: [Int] = []
    var scores: [Int] = []
    var feelings: [CheckIn.Feeling] = []
    var checkInIndices: [Int] = []
    
    var usageCount: Int {
        days.count
    }
    
    var avgInterval: Double {
        guard days.count >= 2 else { return 0 }
        var intervals: [Double] = []
        for i in 1..<days.count {
            intervals.append(Double(days[i] - days[i - 1]))
        }
        return intervals.reduce(0, +) / Double(intervals.count)
    }
    
    var scoreVariability: Double {
        guard scores.count >= 2 else { return 0 }
        let doubleScores = scores.map { Double($0) }
        let mean = doubleScores.reduce(0, +) / Double(doubleScores.count)
        let variance = doubleScores.map { pow($0 - mean, 2) }.reduce(0, +) / Double(doubleScores.count)
        return sqrt(variance)
    }
    
    mutating func addUsage(day: Int, overallScore: Int, feeling: CheckIn.Feeling?, checkInIndex: Int) {
        days.append(day)
        scores.append(overallScore)
        if let feeling = feeling {
            feelings.append(feeling)
        }
        checkInIndices.append(checkInIndex)
    }
}
