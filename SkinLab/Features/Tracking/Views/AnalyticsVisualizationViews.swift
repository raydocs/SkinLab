//
//  AnalyticsVisualizationViews.swift
//  SkinLab
//
//  AI增强分析可视化组件
//  包含预测图表、异常检测、热力图、置信度徽章和季节性分析等可视化
//

import SwiftUI
import Charts

// MARK: - Forecast Chart View

/// 趋势预测图表
struct ForecastChartView: View {
    let forecast: TrendForecast
    let historicalData: [ScorePoint]
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题和风险预警
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("(forecast.metric)预测")
                        .font(.skinLabHeadline)
                    Text("未来(forecast.horizonDays)天趋势：(forecast.trendDirection)")
                        .font(.skinLabCaption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ConfidenceBadgeView(confidence: forecast.confidence)
            }
            
            // 风险预警
            if let alert = forecast.riskAlert {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: alert.icon)
                            .foregroundColor(Color(alert.colorName))
                        Text("[\(alert.severity.rawValue)] \(alert.message)")
                            .font(.skinLabCaption)
                            .foregroundColor(Color(alert.colorName))
                    }
                    Text(alert.actionSuggestion)
                        .font(.skinLabCaption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color(alert.colorName).opacity(0.1))
                .cornerRadius(8)
            }
            
            // 图表
            Chart {
                // 历史数据
                ForEach(Array(historicalData.suffix(10))) { point in
                    LineMark(
                        x: .value("天数", point.day),
                        y: .value("数值", point.overallScore)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    PointMark(
                        x: .value("天数", point.day),
                        y: .value("数值", point.overallScore)
                    )
                    .foregroundStyle(Color.blue)
                }
                
                // 预测数据
                ForEach(forecast.points) { point in
                    LineMark(
                        x: .value("天数", point.day),
                        y: .value("数值", point.predictedValue)
                    )
                    .foregroundStyle(Color.purple.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 3]))
                    
                    // 置信区间
                    AreaMark(
                        x: .value("天数", point.day),
                        yStart: .value("下界", point.lowerBound),
                        yEnd: .value("上界", point.upperBound)
                    )
                    .foregroundStyle(Color.purple.opacity(0.15))
                }
            }
            .frame(height: 200)
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(position: .bottom)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            
            // 图例
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Text("历史数据")
                        .font(.skinLabCaption)
                }
                
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.purple)
                        .frame(width: 12, height: 2)
                    Text("预测趋势")
                        .font(.skinLabCaption)
                }
                
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.purple.opacity(0.3))
                        .frame(width: 12, height: 8)
                    Text("置信区间")
                        .font(.skinLabCaption)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(16)
        .skinLabSoftShadow()
    }
}

// MARK: - Anomaly List View

/// 异常检测列表
struct AnomalyListView: View {
    let anomalies: [AnomalyDetectionResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.octagon.fill")
                    .foregroundColor(.orange)
                Text("异常检测")
                    .font(.skinLabHeadline)
                Spacer()
                Text("\(anomalies.count)个异常")
                    .font(.skinLabCaption)
                    .foregroundColor(.secondary)
            }
            
            if anomalies.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("未检测到异常,数据质量良好")
                        .font(.skinLabSubheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else {
                ForEach(anomalies.prefix(5)) { anomaly in
                    AnomalyRow(anomaly: anomaly)
                }
            }
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(16)
        .skinLabSoftShadow()
    }
}

struct AnomalyRow: View {
    let anomaly: AnomalyDetectionResult
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 严重程度图标
            Image(systemName: severityIcon)
                .foregroundColor(severityColor)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(anomaly.metric)
                        .font(.skinLabSubheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("第\(anomaly.day)天")
                        .font(.skinLabCaption)
                        .foregroundColor(.secondary)
                }
                
                Text(anomaly.reason)
                    .font(.skinLabCaption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text("\(anomaly.severity.rawValue)")
                        .font(.skinLabCaption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(severityColor.opacity(0.2))
                        .foregroundColor(severityColor)
                        .cornerRadius(4)
                    
                    Text("Z-score: \(String(format: "%.2f", anomaly.zScore))")
                        .font(.skinLabCaption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var severityIcon: String {
        switch anomaly.severity {
        case .severe: return "exclamationmark.triangle.fill"
        case .moderate: return "exclamationmark.circle.fill"
        case .mild: return "info.circle.fill"
        }
    }
    
    private var severityColor: Color {
        switch anomaly.severity {
        case .severe: return .red
        case .moderate: return .orange
        case .mild: return .yellow
        }
    }
}

// MARK: - Heatmap Grid View

/// 多维热力图
struct HeatmapGridView: View {
    let heatmap: HeatmapData
    
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(heatmap.title)
                .font(.skinLabHeadline)
            
            // 热力图网格
            LazyVGrid(columns: columns, spacing: 4) {
                // 表头(维度名称)
                ForEach(heatmap.dimensions, id: \.self) { dimension in
                    Text(dimension)
                        .font(.skinLabCaption)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
                
                // 数据行(按天)
                ForEach(heatmap.days, id: \.self) { day in
                    ForEach(heatmap.dimensions, id: \.self) { dimension in
                        if let cell = heatmap.cells.first(where: { $0.day == day && $0.dimension == dimension }) {
                            HeatmapCellView(value: cell.value)
                        } else {
                            Color.gray.opacity(0.1)
                                .frame(height: 30)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            // 颜色图例
            HStack {
                Text("低")
                    .font(.skinLabCaption)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.green, .yellow, .orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 16)
                    .cornerRadius(8)
                Text("高")
                    .font(.skinLabCaption)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(16)
        .skinLabSoftShadow()
    }
}

struct HeatmapCellView: View {
    let value: Double
    
    var body: some View {
        Rectangle()
            .fill(heatColor)
            .frame(height: 30)
            .cornerRadius(4)
            .overlay(
                Text(String(format: "%.1f", value * 10))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.8))
            )
    }
    
    private var heatColor: Color {
        if value < 0.3 { return .green }
        if value < 0.5 { return .yellow }
        if value < 0.7 { return .orange }
        return .red
    }
}

// MARK: - Confidence Badge View

/// 置信度徽章
struct ConfidenceBadgeView: View {
    let confidence: ConfidenceScore
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.skinLabCaption)
            Text(confidence.level.rawValue)
                .font(.skinLabCaption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(levelColor.opacity(0.2))
        .foregroundColor(levelColor)
        .cornerRadius(8)
    }
    
    private var levelColor: Color {
        switch confidence.level {
        case .high: return .green
        case .medium: return .blue
        case .low: return .orange
        case .veryLow: return .red
        }
    }
}

// MARK: - Seasonality Summary View

/// 季节性分析总结
struct SeasonalitySummaryView: View {
    let patterns: [SeasonalPattern]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                Text("季节性分析")
                    .font(.skinLabHeadline)
            }
            
            if patterns.isEmpty {
                Text("样本量不足,暂无季节性分析")
                    .font(.skinLabSubheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(patterns, id: \.season) { pattern in
                    SeasonalPatternRow(pattern: pattern)
                }
            }
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(16)
        .skinLabSoftShadow()
    }
}

struct SeasonalPatternRow: View {
    let pattern: SeasonalPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("(pattern.season)季")
                    .font(.skinLabSubheadline)
                    .fontWeight(.medium)
                Spacer()
                ConfidenceBadgeView(confidence: pattern.confidence)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("泛红指数")
                        .font(.skinLabCaption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        ProgressBar(value: pattern.avgRedness / 10, color: .red)
                        Text(String(format: "%.1f", pattern.avgRedness))
                            .font(.skinLabCaption)
                            .fontWeight(.medium)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("敏感度")
                        .font(.skinLabCaption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        ProgressBar(value: pattern.avgSensitivity / 10, color: .orange)
                        Text(String(format: "%.1f", pattern.avgSensitivity))
                            .font(.skinLabCaption)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Text(pattern.recommendation)
                .font(.skinLabCaption)
                .foregroundColor(.secondary)
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ProgressBar: View {
    let value: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * min(1, max(0, value)), height: 4)
            }
            .cornerRadius(2)
        }
        .frame(width: 60, height: 4)
    }
}

// MARK: - Product Effect Detail View

/// 产品效果详细分析
struct ProductEffectDetailView: View {
    let insights: [ProductEffectInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("产品效果深度分析")
                    .font(.skinLabHeadline)
            }
            
            if insights.isEmpty {
                Text("暂无产品使用数据")
                    .font(.skinLabSubheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(insights.prefix(5), id: \.productId) { insight in
                    ProductInsightRow(insight: insight)
                }
            }
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(16)
        .skinLabSoftShadow()
    }
}

struct ProductInsightRow: View {
    let insight: ProductEffectInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row: product name + badges
            HStack {
                Text(insight.productName)
                    .font(.skinLabSubheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                // Primary contributor badge
                if insight.isPrimaryContributor {
                    PrimaryContributorBadge()
                }

                Spacer()
                ConfidenceBadgeView(confidence: insight.confidence)
            }

            // Effect level and usage count row
            HStack {
                Text(insight.effectLevel.rawValue)
                    .font(.skinLabCaption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(effectColor.opacity(0.2))
                    .foregroundColor(effectColor)
                    .cornerRadius(6)

                Text("使用\(insight.usageCount)次")
                    .font(.skinLabCaption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(String(format: "%.1f%%", insight.effectivenessScore * 100))
                    .font(.skinLabCaption)
                    .fontWeight(.medium)
                    .foregroundColor(effectColor)
            }

            // Contributing factors
            Text("影响因素: \(insight.contributingFactors.prefix(2).joined(separator: ", "))")
                .font(.skinLabCaption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            // Attribution suggestion (if needs solo usage validation)
            if let suggestion = insight.attributionSuggestion {
                AttributionSuggestionView(suggestion: suggestion)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var effectColor: Color {
        switch insight.effectLevel {
        case .highlyEffective: return .green
        case .effective: return .blue
        case .neutral: return .gray
        case .ineffective: return .orange
        case .harmful: return .red
        }
    }
}

// MARK: - Primary Contributor Badge

/// 主要贡献者徽章
struct PrimaryContributorBadge: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.system(size: 8))
            Text("主要贡献者")
                .font(.system(size: 10, weight: .medium))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.purple.opacity(0.2))
        .foregroundColor(.purple)
        .cornerRadius(6)
    }
}

// MARK: - Attribution Suggestion View

/// 归因建议视图
struct AttributionSuggestionView: View {
    let suggestion: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "lightbulb.fill")
                .font(.skinLabCaption)
                .foregroundColor(.orange)
            Text(suggestion)
                .font(.skinLabCaption)
                .foregroundColor(.orange)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Multi-Product Usage Tip

/// 多产品使用提示卡片
struct MultiProductUsageTip: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("提升分析精度")
                    .font(.skinLabSubheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }

            Text("尝试单独使用某款产品5-7天，可帮助验证其真实效果并提高归因准确度。")
                .font(.skinLabCaption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Product Combination Synergy View

/// 产品组合协同效果视图
struct ProductCombinationSynergyView: View {
    let insight: ProductCombinationInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: synergyIcon)
                    .foregroundColor(synergyColor)
                Text("产品组合效果")
                    .font(.skinLabSubheadline)
                    .fontWeight(.medium)
                Spacer()
                ConfidenceBadgeView(confidence: insight.confidence)
            }

            // Product combination display
            HStack(spacing: 4) {
                ForEach(Array(insight.productIds.prefix(3)), id: \.self) { productId in
                    Text(productId)
                        .font(.skinLabCaption)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(6)
                }
                if insight.productIds.count > 3 {
                    Text("+\(insight.productIds.count - 3)")
                        .font(.skinLabCaption)
                        .foregroundColor(.secondary)
                }
            }

            // Synergy indicator
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("协同效果")
                        .font(.skinLabCaption)
                        .foregroundColor(.secondary)
                    Text(insight.synergyLevel.rawValue)
                        .font(.skinLabSubheadline)
                        .fontWeight(.medium)
                        .foregroundColor(synergyColor)
                }

                Spacer()

                // Synergy score bar
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f%%", insight.synergyScore * 100))
                        .font(.skinLabCaption)
                        .fontWeight(.medium)
                        .foregroundColor(synergyColor)
                    SynergyBar(score: insight.synergyScore)
                }
            }

            // Usage count
            Text("组合使用 \(insight.usageCount) 次")
                .font(.skinLabCaption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var synergyIcon: String {
        switch insight.synergyLevel {
        case .highSynergy: return "arrow.up.right.circle.fill"
        case .mildSynergy: return "arrow.up.right"
        case .neutral: return "minus.circle"
        case .mildAntagonism: return "arrow.down.right"
        case .highAntagonism: return "arrow.down.right.circle.fill"
        }
    }

    private var synergyColor: Color {
        switch insight.synergyLevel {
        case .highSynergy: return .green
        case .mildSynergy: return .blue
        case .neutral: return .gray
        case .mildAntagonism: return .orange
        case .highAntagonism: return .red
        }
    }
}

// MARK: - Synergy Bar

/// 协同效果指示条
struct SynergyBar: View {
    let score: Double  // -1 to 1

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 6)

                // Indicator
                let normalizedScore = (score + 1) / 2  // Convert -1..1 to 0..1
                let width = geometry.size.width * normalizedScore
                Rectangle()
                    .fill(barColor)
                    .frame(width: max(4, width), height: 6)
            }
            .cornerRadius(3)
        }
        .frame(width: 80, height: 6)
    }

    private var barColor: Color {
        if score > 0.1 { return .green }
        if score < -0.1 { return .red }
        return .gray
    }
}
