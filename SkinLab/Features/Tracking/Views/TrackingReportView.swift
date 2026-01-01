import SwiftUI
import Charts

struct TrackingReportView: View {
    let report: EnhancedTrackingReport
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMetric: MetricType = .overallScore
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

    @State private var showComparison = false
    @State private var showComparisonViewer = false
    @State private var showProductEffectiveness = false
    @State private var showDimensionChanges = false
    @State private var showRecommendations = false
    
    enum MetricType: String, CaseIterable {
        case overallScore = "综合评分"
        case skinAge = "皮肤年龄"
        
        var yAxisLabel: String {
            switch self {
            case .overallScore: return "评分"
            case .skinAge: return "年龄"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Stats
                headerStatsSection
                
                // Trend Chart (core - always visible)
                trendChartSection

                // AI Summary (core - always visible)
                if let aiSummary = report.aiSummary {
                    aiSummarySection(aiSummary)
                }
                
                // Before/After Comparison (collapsed by default)
                if report.beforePhotoPath != nil || report.afterPhotoPath != nil {
                    disclosureCard(
                        title: "对比效果",
                        systemImage: "photo.on.rectangle.angled",
                        isExpanded: $showComparison
                    ) {
                        comparisonSection
                    }
                }

                // Product Effectiveness (collapsed by default)
                if !report.usedProducts.isEmpty {
                    disclosureCard(
                        title: "产品效果评估",
                        systemImage: "chart.bar.fill",
                        isExpanded: $showProductEffectiveness
                    ) {
                        productEffectivenessSection
                    }
                }

                // Dimension Changes (collapsed by default)
                disclosureCard(
                    title: "详细变化",
                    systemImage: "list.bullet.rectangle",
                    isExpanded: $showDimensionChanges
                ) {
                    dimensionChangesSection
                }
                
                // Recommendations (collapsed by default)
                disclosureCard(
                    title: "建议",
                    systemImage: "lightbulb",
                    isExpanded: $showRecommendations
                ) {
                    recommendationsSection
                }
                
                // Share Button
                shareButton
            }
            .padding()
        }
        .background(Color.skinLabBackground)
        .navigationTitle("追踪报告")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
        .sheet(isPresented: $showComparisonViewer) {
            NavigationStack {
                TrackingComparisonView(
                    beforePath: report.beforePhotoPath,
                    afterPath: report.afterPhotoPath,
                    beforeAnalysisId: report.beforeAnalysisId,
                    afterAnalysisId: report.afterAnalysisId
                )
            }
        }
    }
    
    // MARK: - Disclosure Style
    private func disclosureCard<Content: View>(
        title: String,
        systemImage: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        DisclosureGroup(isExpanded: isExpanded) {
            content()
                .padding(.top, 8)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                Text(title)
                    .font(.skinLabTitle3)
                    .foregroundColor(.skinLabText)
                Spacer()
            }
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }

    // MARK: - Header Stats
    private var headerStatsSection: some View {
        VStack(spacing: 16) {
            // Duration Badge
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(LinearGradient.skinLabRoseGradient)
                Text("追踪 \(report.duration) 天")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
            }
            
            // Main Stats
            HStack(spacing: 16) {
                ReportStatCard(
                    value: report.scoreChange > 0 ? "+\(report.scoreChange)" : "\(report.scoreChange)",
                    label: "评分变化",
                    icon: "chart.line.uptrend.xyaxis"
                )

                ReportStatCard(
                    value: report.skinAgeChange > 0 ? "+\(report.skinAgeChange)" : "\(report.skinAgeChange)",
                    label: "皮肤年龄",
                    icon: "sparkles"
                )

                ReportStatCard(
                    value: "\(Int(report.completionRate * 100))%",
                    label: "完成度",
                    icon: "checkmark.circle"
                )
            }
            
            // Improvement Label
            Text(report.improvementLabel)
                .font(.skinLabTitle3)
                .foregroundStyle(LinearGradient.skinLabRoseGradient)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.skinLabPrimary.opacity(0.1))
                .cornerRadius(20)
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }
    
    // MARK: - Comparison Section
    private var comparisonSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                if let beforePath = report.beforePhotoPath,
                   let beforeImage = loadImage(from: beforePath) {
                    Image(uiImage: beforeImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundStyle(LinearGradient.skinLabPrimaryGradient)

                if let afterPath = report.afterPhotoPath,
                   let afterImage = loadImage(from: afterPath) {
                    Image(uiImage: afterImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer()
            }

            Button {
                showComparisonViewer = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait")
                    Text("查看详细对比")
                }
                .font(.skinLabSubheadline)
                .foregroundColor(.skinLabPrimary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Trend Chart
    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("变化趋势")
                    .font(.skinLabTitle3)
                    .foregroundColor(.skinLabText)
                
                Spacer()
                
                // Metric Selector
                Picker("", selection: $selectedMetric) {
                    ForEach(MetricType.allCases, id: \.self) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            // Chart
            if !report.timeline.isEmpty {
                Chart(report.timeline) { point in
                    LineMark(
                        x: .value("天数", point.day),
                        y: .value(selectedMetric.yAxisLabel, getMetricValue(for: point))
                    )
                    .foregroundStyle(LinearGradient.skinLabRoseGradient)
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("天数", point.day),
                        y: .value(selectedMetric.yAxisLabel, getMetricValue(for: point))
                    )
                    .foregroundStyle(LinearGradient.skinLabRoseGradient)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let day = value.as(Int.self) {
                                Text("Day \(day)")
                                    .font(.skinLabCaption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 200)
                .padding()
            } else {
                Text("暂无数据")
                    .font(.skinLabBody)
                    .foregroundColor(.skinLabSubtext)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }
    
    // MARK: - Dimension Changes
    private var dimensionChangesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Improvements
            if !report.topImprovements.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("改善最多", systemImage: "arrow.up.circle.fill")
                        .font(.skinLabSubheadline)
                        .foregroundColor(.skinLabSuccess)
                    
                    ForEach(report.topImprovements, id: \.dimension) { change in
                        DimensionChangeRow(change: change, isPositive: true)
                    }
                }
            }
            
            // Issues Needing Attention
            if !report.issuesNeedingAttention.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("需要关注", systemImage: "exclamationmark.triangle.fill")
                        .font(.skinLabSubheadline)
                        .foregroundColor(.skinLabWarning)
                    
                    ForEach(report.issuesNeedingAttention, id: \.dimension) { change in
                        DimensionChangeRow(change: change, isPositive: false)
                    }
                }
                .padding(.top, 8)
            }
            
            // All Dimensions Chart
            Chart(report.dimensionChanges, id: \.dimension) { change in
                BarMark(
                    x: .value("改善度", change.improvement),
                    y: .value("维度", change.dimension)
                )
                .foregroundStyle(change.improvement > 0 ? Color.skinLabSuccess.gradient : Color.skinLabError.gradient)
            }
            .frame(height: 250)
            .padding(.top, 12)
        }
        .padding(.top, 4)
    }
    
    // MARK: - AI Summary
    private func aiSummarySection(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(LinearGradient.skinLabAccentGradient)
                Text("AI 分析总结")
                    .font(.skinLabTitle3)
                    .foregroundColor(.skinLabText)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(parseBulletPoints(summary), id: \.self) { point in
                    HStack(alignment: .top, spacing: 8) {
                        Text("·")
                            .font(.skinLabBody)
                            .foregroundColor(.skinLabAccent)
                        Text(point)
                            .font(.skinLabBody)
                            .foregroundColor(.skinLabText)
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.skinLabAccent.opacity(0.1), Color.skinLabPrimary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .skinLabSoftShadow()
    }

    // MARK: - Product Effectiveness
    private var productEffectivenessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(report.usedProducts, id: \.productId) { product in
                ProductEffectivenessRow(product: product)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Recommendations
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(report.recommendations, id: \.self) { recommendation in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.skinLabAccent)
                    Text(recommendation)
                        .font(.skinLabBody)
                        .foregroundColor(.skinLabText)
                }
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - Share Button
    private var shareButton: some View {
        Button {
            generateShareCard()
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("分享报告")
                    .font(.skinLabHeadline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(LinearGradient.skinLabRoseGradient)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Helper Methods
    private func getMetricValue(for point: ScorePoint) -> Int {
        switch selectedMetric {
        case .overallScore: return point.overallScore
        case .skinAge: return point.skinAge
        }
    }
    
    private func loadImage(from path: String) -> UIImage? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagePath = documentsPath.appendingPathComponent(path)
        return UIImage(contentsOfFile: imagePath.path)
    }
    
    private func generateShareCard() {
        let renderer = ShareCardRenderer()
        let card = ShareCardView(report: report)
        shareImage = renderer.render(card)
        showShareSheet = true
    }

    private func parseBulletPoints(_ text: String) -> [String] {
        // Split by newlines and filter bullet points
        let lines = text.components(separatedBy: .newlines)
        return lines
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { line in
                // Remove bullet prefixes like "·", "•", "-", or "* "
                var cleaned = line
                if cleaned.hasPrefix("·") || cleaned.hasPrefix("•") || cleaned.hasPrefix("-") {
                    cleaned = String(cleaned.dropFirst()).trimmingCharacters(in: .whitespaces)
                }
                return cleaned
            }
    }
}

// MARK: - Report Stat Card
struct ReportStatCard: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(LinearGradient.skinLabPrimaryGradient)

            Text(value)
                .font(.skinLabTitle2)
                .fontWeight(.bold)
                .foregroundColor(.skinLabText)

            Text(label)
                .font(.skinLabCaption)
                .foregroundColor(.skinLabSubtext)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.skinLabPrimary.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Dimension Change Row
struct DimensionChangeRow: View {
    let change: TrackingReport.DimensionChange
    let isPositive: Bool
    
    var body: some View {
        HStack {
            Text(change.dimension)
                .font(.skinLabSubheadline)
                .foregroundColor(.skinLabText)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("\(change.beforeScore)")
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
                
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundColor(.skinLabSubtext)
                
                Text("\(change.afterScore)")
                    .font(.skinLabCaption)
                    .fontWeight(.semibold)
                    .foregroundColor(isPositive ? .skinLabSuccess : .skinLabError)
                
                Text("(\(change.improvement > 0 ? "+" : "")\(Int(change.improvement)))")
                    .font(.skinLabCaption)
                    .foregroundColor(isPositive ? .skinLabSuccess : .skinLabError)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Product Effectiveness Row
struct ProductEffectivenessRow: View {
    let product: TrackingReport.ProductUsage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.productName)
                        .font(.skinLabSubheadline)
                        .foregroundColor(.skinLabText)

                    Text("使用 \(product.usageDays) 天")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }

                Spacer()

                if let effectiveness = product.effectiveness {
                    effectivenessBadge(effectiveness)
                } else {
                    Text("样本不足")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.skinLabSubtext.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            Divider()
        }
    }

    @ViewBuilder
    private func effectivenessBadge(_ effectiveness: TrackingReport.ProductUsage.Effectiveness) -> some View {
        let config = effectivenessConfig(effectiveness)

        HStack(spacing: 4) {
            Image(systemName: config.icon)
                .font(.caption)
            Text(config.label)
                .font(.skinLabCaption)
                .fontWeight(.medium)
        }
        .foregroundColor(config.color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(config.color.opacity(0.15))
        .cornerRadius(8)
    }

    private func effectivenessConfig(_ effectiveness: TrackingReport.ProductUsage.Effectiveness) -> (label: String, icon: String, color: Color) {
        switch effectiveness {
        case .effective:
            return ("有效", "checkmark.circle.fill", .skinLabSuccess)
        case .neutral:
            return ("一般", "minus.circle.fill", .skinLabWarning)
        case .ineffective:
            return ("无效", "xmark.circle.fill", .skinLabError)
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
