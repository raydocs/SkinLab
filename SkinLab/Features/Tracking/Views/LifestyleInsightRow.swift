import SwiftUI

// MARK: - Lifestyle Insight Row

/// Displays a single lifestyle correlation insight
struct LifestyleInsightRow: View {
    let insight: LifestyleCorrelationInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with factor and correlation direction
            HStack {
                factorIcon
                Text(factorLabel)
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabText)

                Spacer()

                // Correlation badge
                HStack(spacing: 4) {
                    Image(systemName: directionIcon)
                        .font(.caption)
                    Text(correlationLabel)
                        .font(.skinLabCaption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(correlationColor.opacity(0.15))
                .foregroundColor(correlationColor)
                .cornerRadius(6)
            }

            // Interpretation (non-causal wording)
            Text(insight.interpretation)
                .font(.skinLabCaption)
                .foregroundColor(.skinLabSubtext)
                .fixedSize(horizontal: false, vertical: true)

            // Metadata
            HStack(spacing: 16) {
                // Sample count
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar")
                        .font(.caption)
                        .foregroundColor(.skinLabSubtext)
                    Text("样本: \(insight.sampleCount)")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }

                // Confidence
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(confidenceColor)
                    Text(confidenceLabel)
                        .font(.skinLabCaption)
                        .foregroundColor(confidenceColor)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    private var factorIcon: some View {
        Image(systemName: iconName)
            .font(.body)
            .foregroundColor(.white)
            .frame(width: 32, height: 32)
            .background(iconColor)
            .cornerRadius(8)
    }

    private var iconName: String {
        // Use the icon property from LifestyleFactorKey
        insight.factor.icon
    }

    private var iconColor: Color {
        switch insight.factor {
        case .sleepHours: .blue
        case .stressLevel: .purple
        case .waterIntakeLevel: .cyan
        case .alcohol: .red
        case .exerciseMinutes: .green
        case .sunExposureLevel: .orange
        // Weather factors
        case .humidity: .teal
        case .uvIndex: .orange
        case .airQuality: .gray
        }
    }

    private var factorLabel: String {
        // Use the label property from LifestyleFactorKey
        insight.factor.label
    }

    private var directionIcon: String {
        switch insight.direction {
        case .positive: "arrow.up.right"
        case .negative: "arrow.down.right"
        case .none: "minus"
        }
    }

    private var correlationColor: Color {
        switch insight.direction {
        case .positive: .green
        case .negative: .red
        case .none: .gray
        }
    }

    private var correlationLabel: String {
        let percentage = Int(abs(insight.correlation) * 100)
        switch insight.direction {
        case .positive: return "+\(percentage)%"
        case .negative: return "-\(percentage)%"
        case .none: return "无关联"
        }
    }

    private var confidenceColor: Color {
        let score = insight.confidence.value
        if score >= 0.7 { return .green }
        if score >= 0.4 { return .orange }
        return .red
    }

    private var confidenceLabel: String {
        let score = insight.confidence.value
        if score >= 0.7 { return "高可信度" }
        if score >= 0.4 { return "中等" }
        return "低可信度"
    }
}

// MARK: - Lifestyle Insights Card

/// Card displaying multiple lifestyle insights
struct LifestyleInsightsCard: View {
    let insights: [LifestyleCorrelationInsight]
    let dataCoverage: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(.freshPrimary)
                Text("生活方式关联")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)

                Spacer()

                // Coverage indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(coverageColor)
                        .frame(width: 6, height: 6)
                    Text("\(Int(dataCoverage * 100))%覆盖")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }
            }

            // Insights or empty state
            if insights.isEmpty {
                emptyStateView
            } else {
                insightsList
            }

            // Disclaimer
            Text("💡 关联不等于因果关系。仅供参考，不作为医疗建议。")
                .font(.skinLabCaption)
                .foregroundColor(.skinLabSubtext)
        }
        .padding()
        .freshGlassCard()
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.largeTitle)
                .foregroundColor(.gray)

            Text("暂无足够数据")
                .font(.skinLabSubheadline)
                .foregroundColor(.skinLabSubtext)

            Text("持续记录生活方式以发现关联模式")
                .font(.skinLabCaption)
                .foregroundColor(.skinLabSubtext)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var insightsList: some View {
        VStack(spacing: 12) {
            ForEach(insights.prefix(5)) { insight in
                LifestyleInsightRow(insight: insight)
            }
        }
    }

    private var coverageColor: Color {
        if dataCoverage >= 0.7 { return .green }
        if dataCoverage >= 0.4 { return .orange }
        return .red
    }
}

// MARK: - Preview

#Preview {
    LifestyleInsightsCard(
        insights: [
            LifestyleCorrelationInsight(
                factor: .sleepHours,
                targetMetric: "综合评分",
                correlation: 0.65,
                sampleCount: 5,
                confidence: ConfidenceScore(
                    value: 0.6,
                    sampleCount: 5,
                    method: "spearman"
                ),
                interpretation: "睡眠时间可能与改善相关，但需更多数据验证。仅供参考，不表示因果关系。"
            ),
            LifestyleCorrelationInsight(
                factor: .stressLevel,
                targetMetric: "泛红",
                correlation: -0.55,
                sampleCount: 4,
                confidence: ConfidenceScore(
                    value: 0.5,
                    sampleCount: 4,
                    method: "spearman"
                ),
                interpretation: "压力水平可能与恶化相关，但需更多数据验证。仅供参考，不表示因果关系。"
            ),
            LifestyleCorrelationInsight(
                factor: .exerciseMinutes,
                targetMetric: "皮肤年龄",
                correlation: 0.35,
                sampleCount: 3,
                confidence: ConfidenceScore(
                    value: 0.3,
                    sampleCount: 3,
                    method: "spearman"
                ),
                interpretation: "运动可能与改善相关，但需更多数据验证。仅供参考，不表示因果关系。"
            )
        ],
        dataCoverage: 0.6
    )
}
