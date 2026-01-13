import Foundation
import SwiftData

/// Analyzes correlations between lifestyle factors and skin condition changes
struct LifestyleCorrelationAnalyzer {

    private let analyzer = TimeSeriesAnalyzer()

    /// Analyze lifestyle factors vs skin metrics using lagged correlation
    /// - Parameters:
    ///   - checkIns: All check-ins in the session
    ///   - timeline: Timeline of score points
    ///   - reliability: Reliability metadata by check-in ID
    /// - Returns: Array of correlation insights
    func analyze(
        checkIns: [CheckIn],
        timeline: [ScorePoint],
        reliability: [UUID: ReliabilityMetadata]
    ) -> [LifestyleCorrelationInsight] {
        guard checkIns.count >= 2 else { return [] }

        var insights: [LifestyleCorrelationInsight] = []

        // Build consecutive check-in pairs for lagged correlation
        let pairs = buildConsecutivePairs(checkIns: checkIns, analyses: [:])

        // Analyze each lifestyle factor
        let factors: [LifestyleCorrelationInsight.LifestyleFactorKey] = [
            .sleepHours, .stressLevel, .waterIntakeLevel,
            .exerciseMinutes, .sunExposureLevel
        ]

        for factor in factors {
            if let insight = analyzeFactor(
                factor: factor,
                pairs: pairs,
                timeline: timeline,
                reliability: reliability
            ) {
                insights.append(insight)
            }
        }

        // Sort by absolute correlation (strongest first)
        insights.sort { abs($0.correlation) > abs($1.correlation) }

        return insights
    }

    // MARK: - Private Methods

    /// Build consecutive pairs (day D -> day D+1) for lagged correlation
    private func buildConsecutivePairs(
        checkIns: [CheckIn],
        analyses: [UUID: SkinAnalysis]
    ) -> [(checkIn: CheckIn, nextCheckIn: CheckIn, delta: Double)] {
        let sorted = checkIns.sorted { $0.day < $1.day }
        var pairs: [(CheckIn, CheckIn, Double)] = []

        for i in 0..<(sorted.count - 1) {
            let current = sorted[i]
            let next = sorted[i + 1]

            // Calculate score change (delta)
            // For now, use overallScore from timeline if available
            // In real implementation, this would come from SkinAnalysis
            let delta = 0.0  // Placeholder

            pairs.append((current, next, delta))
        }

        return pairs
    }

    /// Analyze a single lifestyle factor
    private func analyzeFactor(
        factor: LifestyleCorrelationInsight.LifestyleFactorKey,
        pairs: [(checkIn: CheckIn, nextCheckIn: CheckIn, delta: Double)],
        timeline: [ScorePoint],
        reliability: [UUID: ReliabilityMetadata]
    ) -> LifestyleCorrelationInsight? {
        // Extract factor values and deltas
        var factorValues: [Double] = []
        var deltas: [Double] = []
        var reliabilityScores: [Double] = []

        for pair in pairs {
            guard let value = extractFactorValue(factor, from: pair.checkIn) else { continue }

            factorValues.append(value)
            deltas.append(pair.delta)

            if let rel = reliability[pair.checkIn.id] {
                reliabilityScores.append(rel.score)
            }
        }

        guard factorValues.count >= 2 else { return nil }

        // Calculate Spearman correlation (robust for small samples)
        let correlation = analyzer.spearmanCorrelation(factorValues, deltas)

        // Skip weak correlations
        guard abs(correlation) >= 0.3 else { return nil }

        // Calculate confidence
        let confidence = calculateConfidence(
            sampleCount: factorValues.count,
            reliabilityScores: reliabilityScores
        )

        // Generate interpretation (non-causal wording)
        let interpretation = generateInterpretation(
            factor: factor,
            correlation: correlation,
            confidence: confidence
        )

        // Determine target metric (simplified for now)
        let targetMetric = "皮肤状态"

        return LifestyleCorrelationInsight(
            factor: factor,
            targetMetric: targetMetric,
            correlation: correlation,
            sampleCount: factorValues.count,
            confidence: confidence,
            interpretation: interpretation
        )
    }

    /// Extract numeric value from lifestyle factors
    private func extractFactorValue(
        _ factor: LifestyleCorrelationInsight.LifestyleFactorKey,
        from checkIn: CheckIn
    ) -> Double? {
        guard let lifestyle = checkIn.lifestyle else { return nil }

        switch factor {
        case .sleepHours:
            return lifestyle.sleepHours
        case .stressLevel:
            return lifestyle.stressLevel.map(Double.init)
        case .waterIntakeLevel:
            return lifestyle.waterIntakeLevel.map(Double.init)
        case .alcohol:
            return lifestyle.alcoholConsumed.map { $0 ? 1.0 : 0.0 }
        case .exerciseMinutes:
            return lifestyle.exerciseMinutes.map(Double.init)
        case .sunExposureLevel:
            return lifestyle.sunExposureLevel.map(Double.init)
        }
    }

    /// Calculate confidence score for correlation
    private func calculateConfidence(
        sampleCount: Int,
        reliabilityScores: [Double]
    ) -> ConfidenceScore {
        // Sample size contribution (dominant)
        let sampleContribution = min(0.7, Double(sampleCount) / 8.0 * 0.7)

        // Reliability contribution
        let avgReliability = reliabilityScores.isEmpty ? 0.5 : reliabilityScores.reduce(0, +) / Double(reliabilityScores.count)
        let reliabilityContribution = avgReliability * 0.3

        let value = sampleContribution + reliabilityContribution

        return ConfidenceScore(
            value: value,
            sampleCount: sampleCount,
            method: "lifestyle_correlation"
        )
    }

    /// Generate non-causal interpretation text
    private func generateInterpretation(
        factor: LifestyleCorrelationInsight.LifestyleFactorKey,
        correlation: Double,
        confidence: ConfidenceScore
    ) -> String {
        let factorName: String
        switch factor {
        case .sleepHours: factorName = "睡眠时间"
        case .stressLevel: factorName = "压力水平"
        case .waterIntakeLevel: factorName = "饮水量"
        case .alcohol: factorName = "饮酒"
        case .exerciseMinutes: factorName = "运动"
        case .sunExposureLevel: factorName = "日晒"
        }

        let direction: String
        if correlation > 0.5 {
            direction = "可能与改善相关"
        } else if correlation > 0.3 {
            direction = "可能略有相关"
        } else if correlation < -0.5 {
            direction = "可能与恶化相关"
        } else {
            direction = "可能略有负面影响"
        }

        return "\(factorName)\(direction)，但需更多数据验证。仅供参考，不表示因果关系。"
    }
}
