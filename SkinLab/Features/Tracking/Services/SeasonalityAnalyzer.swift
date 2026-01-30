import Foundation

/// 季节性分析器
struct SeasonalityAnalyzer {
    private let analyzer = TimeSeriesAnalyzer()

    // MARK: - Seasonal Pattern Analysis

    /// 分析季节性模式
    /// - Parameters:
    ///   - analyses: 皮肤分析历史记录
    ///   - minSamplesPerSeason: 每个季节最少样本数
    /// - Returns: 季节性模式列表
    func analyzeSeasonalPattern(
        analyses: [SkinAnalysisWithDate],
        minSamplesPerSeason: Int = 2
    ) -> [SeasonalPattern] {
        guard !analyses.isEmpty else { return [] }

        // 按季节分组
        let seasonalGroups = groupBySeason(analyses)

        var patterns: [SeasonalPattern] = []

        for (season, seasonAnalyses) in seasonalGroups {
            guard seasonAnalyses.count >= minSamplesPerSeason else { continue }

            // 计算该季节的平均泛红和敏感度
            let rednessValues = seasonAnalyses.map { Double($0.analysis.issues.redness) }
            let avgRedness = analyzer.mean(rednessValues)

            // 敏感度评估 (基于肤质和泛红)
            let sensitivityScores = seasonAnalyses.map { analysis -> Double in
                var score = Double(analysis.analysis.issues.redness)
                if analysis.analysis.skinType == .sensitive {
                    score += 2.0
                }
                return min(10, score)
            }
            let avgSensitivity = analyzer.mean(sensitivityScores)

            // 计算置信度
            let confidence = calculateSeasonalConfidence(
                sampleCount: seasonAnalyses.count,
                values: rednessValues
            )

            patterns.append(SeasonalPattern(
                season: season,
                avgRedness: avgRedness,
                avgSensitivity: avgSensitivity,
                sampleCount: seasonAnalyses.count,
                confidence: confidence
            ))
        }

        return patterns.sorted { $0.season < $1.season }
    }

    /// 按季节分组
    private func groupBySeason(_ analyses: [SkinAnalysisWithDate]) -> [String: [SkinAnalysisWithDate]] {
        var groups: [String: [SkinAnalysisWithDate]] = [:]

        for analysis in analyses {
            let season = getSeason(for: analysis.date)
            if groups[season] == nil {
                groups[season] = []
            }
            groups[season]?.append(analysis)
        }

        return groups
    }

    /// 获取日期对应的季节
    private func getSeason(for date: Date) -> String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)

        switch month {
        case 3, 4, 5: return "春"
        case 6, 7, 8: return "夏"
        case 9, 10, 11: return "秋"
        default: return "冬"
        }
    }

    /// 计算季节性分析置信度
    private func calculateSeasonalConfidence(
        sampleCount: Int,
        values: [Double]
    ) -> ConfidenceScore {
        let volatility = analyzer.volatility(values)

        var confidenceValue: Double = 0

        // 样本量贡献
        confidenceValue += min(0.6, Double(sampleCount) / 5.0 * 0.6)

        // 稳定性贡献
        confidenceValue += (1.0 - volatility) * 0.4

        return ConfidenceScore(
            value: max(0, min(1, confidenceValue)),
            sampleCount: sampleCount,
            method: "seasonal"
        )
    }

    // MARK: - Seasonal Comparison

    /// 对比不同季节的皮肤状况
    /// - Parameter patterns: 季节性模式列表
    /// - Returns: 季节对比报告
    func compareSeasons(_ patterns: [SeasonalPattern]) -> SeasonalComparisonReport? {
        guard patterns.count >= 2 else { return nil }

        // 找出最敏感的季节
        let mostSensitive = patterns.max { $0.avgSensitivity < $1.avgSensitivity }
        let leastSensitive = patterns.min { $0.avgSensitivity < $1.avgSensitivity }

        // 找出泛红最严重的季节
        let mostRedness = patterns.max { $0.avgRedness < $1.avgRedness }

        return SeasonalComparisonReport(
            patterns: patterns,
            mostSensitiveSeason: mostSensitive,
            leastSensitiveSeason: leastSensitive,
            mostRednessSeason: mostRedness,
            overallConfidence: averageConfidence(patterns)
        )
    }

    /// 计算平均置信度
    private func averageConfidence(_ patterns: [SeasonalPattern]) -> ConfidenceScore {
        let avgValue = patterns.map(\.confidence.value).reduce(0, +) / Double(patterns.count)
        let totalSamples = patterns.map(\.sampleCount).reduce(0, +)

        return ConfidenceScore(
            value: avgValue,
            sampleCount: totalSamples,
            method: "seasonal"
        )
    }

    // MARK: - Recommendations

    /// 生成季节性护理建议
    /// - Parameters:
    ///   - currentSeason: 当前季节
    ///   - patterns: 季节性模式列表
    /// - Returns: 护理建议列表
    func generateSeasonalRecommendations(
        currentSeason: String,
        patterns: [SeasonalPattern]
    ) -> [String] {
        guard let currentPattern = patterns.first(where: { $0.season == currentSeason }) else {
            return ["暂无该季节的历史数据,建议保持常规护肤"]
        }

        var recommendations: [String] = []

        // 基于泛红程度的建议
        if currentPattern.avgRedness >= 6 {
            recommendations.append("该季节泛红较严重,建议加强舒缓和抗炎护理")
            recommendations.append("避免使用刺激性成分,选择温和的护肤品")
        } else if currentPattern.avgRedness >= 4 {
            recommendations.append("该季节泛红中等,注意保湿和屏障修复")
        }

        // 基于敏感度的建议
        if currentPattern.avgSensitivity >= 6 {
            recommendations.append("该季节皮肤较敏感,建议简化护肤流程")
            recommendations.append("避免频繁更换护肤品,使用温和配方")
        }

        // 季节特定建议
        switch currentSeason {
        case "春":
            recommendations.append("春季注意防晒和抗过敏,花粉季节特别注意清洁")
        case "夏":
            recommendations.append("夏季加强防晒和控油,保持皮肤清爽")
        case "秋":
            recommendations.append("秋季注重保湿和修复,准备应对季节转换")
        case "冬":
            recommendations.append("冬季强化保湿,使用更滋润的护肤品")
        default:
            break
        }

        return recommendations
    }
}

// MARK: - Supporting Types

/// 带日期的皮肤分析记录
struct SkinAnalysisWithDate {
    let analysis: SkinAnalysis
    let date: Date
}

/// 季节对比报告
struct SeasonalComparisonReport: Codable {
    let patterns: [SeasonalPattern]
    let mostSensitiveSeason: SeasonalPattern?
    let leastSensitiveSeason: SeasonalPattern?
    let mostRednessSeason: SeasonalPattern?
    let overallConfidence: ConfidenceScore

    /// 生成对比总结
    var summary: String {
        var text = ""

        if let most = mostSensitiveSeason, let least = leastSensitiveSeason {
            let diff = most.avgSensitivity - least.avgSensitivity
            text += "\(most.season)季最敏感,\(least.season)季最稳定,差异\(String(format: "%.1f", diff))分。"
        }

        if let redness = mostRednessSeason {
            text += "\(redness.season)季泛红最明显。"
        }

        return text
    }
}
