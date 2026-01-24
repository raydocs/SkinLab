import SwiftUI
import Charts
import SwiftData

struct TrackingReportView: View {
    let report: EnhancedTrackingReport
    @Environment(\.dismiss) private var dismiss
    @Query private var engagementMetrics: [UserEngagementMetrics]
    @State private var selectedMetric: MetricType = .overallScore
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

    @State private var showComparisonViewer = false

    // Timeline mode: all data vs reliable only
    @State private var timelineMode: TimelineDisplayPolicy.TimelineMode = .all

    // Collapsible section manager with persistence
    @StateObject private var sectionManager = CollapsibleSectionManager()

    // Section IDs for expand/collapse all functionality
    private var availableSectionIds: [String] {
        var ids: [String] = []
        if !report.forecasts.isEmpty { ids.append("forecast") }
        if report.beforePhotoPath != nil || report.afterPhotoPath != nil { ids.append("comparison") }
        if !report.usedProducts.isEmpty { ids.append("productEffectiveness") }
        if !report.productInsights.isEmpty { ids.append("productInsights") }
        ids.append("dimensionChanges")
        ids.append("recommendations")
        if !report.lifestyleInsights.isEmpty { ids.append("lifestyleInsights") }
        if !report.reliabilityMap.isEmpty { ids.append("dataQuality") }
        return ids
    }
    
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
            LazyVStack(spacing: 24) {
                // Header Stats (always visible - key summary)
                headerStatsSection

                // Trend Chart (core - always visible)
                trendChartSection

                // AI Summary (core - always visible as key insight)
                if let aiSummary = report.aiSummary {
                    aiSummarySection(aiSummary)
                }

                // Expand/Collapse All Control
                HStack {
                    Text("详细分析")
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)
                    Spacer()
                    ExpandCollapseAllButton(manager: sectionManager, sectionIds: availableSectionIds)
                }
                .padding(.top, 8)

                // Skin Forecast (collapsed by default, show if forecasts available)
                if !report.forecasts.isEmpty {
                    CollapsibleSection(
                        sectionId: "forecast",
                        title: "皮肤预测",
                        systemImage: "chart.line.uptrend.xyaxis",
                        badge: report.riskAlerts.isEmpty ? nil : "\(report.riskAlerts.count)个预警",
                        manager: sectionManager
                    ) {
                        forecastSection
                    }
                }

                // Before/After Comparison (collapsed by default)
                if report.beforePhotoPath != nil || report.afterPhotoPath != nil {
                    CollapsibleSection(
                        sectionId: "comparison",
                        title: "对比效果",
                        systemImage: "photo.on.rectangle.angled",
                        manager: sectionManager
                    ) {
                        comparisonSection
                    }
                }

                // Product Effectiveness (collapsed by default)
                if !report.usedProducts.isEmpty {
                    CollapsibleSection(
                        sectionId: "productEffectiveness",
                        title: "产品效果评估",
                        systemImage: "chart.bar.fill",
                        badge: "\(report.usedProducts.count)款产品",
                        manager: sectionManager
                    ) {
                        productEffectivenessSection
                    }
                }

                // Enhanced Product Insights with Attribution (collapsed by default)
                if !report.productInsights.isEmpty {
                    CollapsibleSection(
                        sectionId: "productInsights",
                        title: "产品归因分析",
                        systemImage: "sparkles.rectangle.stack.fill",
                        manager: sectionManager
                    ) {
                        productInsightsSection
                    }
                }

                // Dimension Changes (collapsed by default)
                CollapsibleSection(
                    sectionId: "dimensionChanges",
                    title: "详细变化",
                    systemImage: "list.bullet.rectangle",
                    badge: dimensionChangesSummary,
                    manager: sectionManager
                ) {
                    dimensionChangesSection
                }

                // Recommendations (collapsed by default)
                CollapsibleSection(
                    sectionId: "recommendations",
                    title: "建议",
                    systemImage: "lightbulb",
                    badge: "\(report.recommendations.count)条",
                    manager: sectionManager
                ) {
                    recommendationsSection
                }

                // Lifestyle Insights (collapsed by default)
                if !report.lifestyleInsights.isEmpty {
                    CollapsibleSection(
                        sectionId: "lifestyleInsights",
                        title: "生活方式关联",
                        systemImage: "chart.xyaxis.line",
                        badge: "\(report.lifestyleInsights.count)项关联",
                        manager: sectionManager
                    ) {
                        LifestyleInsightsCard(
                            insights: report.lifestyleInsights,
                            dataCoverage: report.lifestyleDataCoverage
                        )
                    }
                }

                // Data Quality (collapsed by default)
                if !report.reliabilityMap.isEmpty {
                    CollapsibleSection(
                        sectionId: "dataQuality",
                        title: "数据质量",
                        systemImage: "checkmark.shield",
                        badge: dataQualitySummary,
                        manager: sectionManager
                    ) {
                        dataQualitySection
                    }
                }

                // Share & Export Button
                shareAndExportSection
            }
            .padding()
        }
        .background(Color.skinLabBackground)
        .navigationTitle("追踪报告")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            timelineMode = report.timelinePolicy.defaultMode
        }
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
    
    // MARK: - Section Summary Helpers

    /// Summary badge for dimension changes section
    private var dimensionChangesSummary: String? {
        let improvements = report.topImprovements.count
        let issues = report.issuesNeedingAttention.count
        if improvements > 0 || issues > 0 {
            var parts: [String] = []
            if improvements > 0 { parts.append("\(improvements)项改善") }
            if issues > 0 { parts.append("\(issues)项关注") }
            return parts.joined(separator: " ")
        }
        return nil
    }

    /// Summary badge for data quality section
    private var dataQualitySummary: String? {
        let reliableCount = report.reliabilityMap.values.filter { $0.score >= 0.5 }.count
        let totalCount = report.reliabilityMap.count
        guard totalCount > 0 else { return nil }
        let percentage = Int(Double(reliableCount) / Double(totalCount) * 100)
        return "\(percentage)%可靠"
    }

    // MARK: - Header Stats
    private var headerStatsSection: some View {
        VStack(spacing: 20) {
            // Duration Badge - auxiliary info (small, subtle)
            AuxiliaryInfoText("追踪 \(report.duration) 天", icon: "calendar")

            // Primary Key Metrics - Large and prominent
            HStack(spacing: 12) {
                KeyMetricCard(
                    value: report.scoreChange > 0 ? "+\(report.scoreChange)" : "\(report.scoreChange)",
                    label: "评分变化",
                    icon: "chart.line.uptrend.xyaxis",
                    trend: scoreTrend,
                    trendLabel: scoreTrendLabel,
                    gradient: .skinLabRoseGradient
                )

                KeyMetricCard(
                    value: report.skinAgeChange > 0 ? "+\(report.skinAgeChange)" : "\(report.skinAgeChange)",
                    label: "皮肤年龄",
                    icon: "sparkles",
                    trend: skinAgeTrend,
                    trendLabel: skinAgeTrendLabel,
                    gradient: .skinLabLavenderGradient
                )
            }

            // Secondary metric - completion rate (smaller, less prominent)
            HStack(spacing: 16) {
                SummaryStatRow(
                    icon: "checkmark.circle",
                    label: "完成度",
                    value: "\(Int(report.completionRate * 100))%",
                    iconColor: completionColor
                )
            }
            .padding()
            .background(Color.skinLabCardBackground)
            .cornerRadius(16)
            .skinLabSoftShadow()

            // Streak indicator
            if let metrics = engagementMetrics.first, metrics.streakCount > 0 {
                streakIndicator(metrics)
            }

            // Improvement Label - key insight summary
            Text(report.improvementLabel)
                .font(.skinLabTitle3)
                .foregroundStyle(LinearGradient.skinLabRoseGradient)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.skinLabPrimary.opacity(0.1))
                .cornerRadius(20)
                .accessibilityLabel("总体趋势: \(report.improvementLabel)")
        }
        .padding(.vertical, 8)
    }

    // MARK: - Trend Helpers

    private var scoreTrend: KeyMetricCard.TrendDirection {
        if report.scoreChange > 0 { return .up }
        else if report.scoreChange < 0 { return .down }
        return .neutral
    }

    private var scoreTrendLabel: String {
        if report.scoreChange > 0 { return "提升" }
        else if report.scoreChange < 0 { return "下降" }
        return "持平"
    }

    private var skinAgeTrend: KeyMetricCard.TrendDirection {
        // For skin age, lower is better
        if report.skinAgeChange < 0 { return .up }
        else if report.skinAgeChange > 0 { return .down }
        return .neutral
    }

    private var skinAgeTrendLabel: String {
        if report.skinAgeChange < 0 { return "年轻化" }
        else if report.skinAgeChange > 0 { return "老化" }
        return "稳定"
    }

    private var completionColor: Color {
        let rate = report.completionRate
        if rate >= 0.8 { return .skinLabSuccess }
        else if rate >= 0.5 { return .skinLabWarning }
        return .skinLabSubtext
    }

    // MARK: - Streak Indicator

    @ViewBuilder
    private func streakIndicator(_ metrics: UserEngagementMetrics) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
            Text("连续打卡 \(metrics.streakCount) 天")
                .font(.skinLabHeadline)
                .foregroundColor(.skinLabText)
            if metrics.longestStreak > metrics.streakCount {
                Text("· 最长 \(metrics.longestStreak) 天")
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
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

            // Timeline mode toggle (if reliable data available)
            if report.timelinePolicy.hasReliableAlternative {
                TimelineModeToggle(mode: $timelineMode, policy: report.timelinePolicy)
                    .padding(.top, 4)
            }

            // Chart
            let currentTimeline = timelineMode == .reliable ? report.timelineReliable : report.timeline
            if !currentTimeline.isEmpty {
                Chart(currentTimeline) { point in
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
                                Text("第\(day)天")
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

    // MARK: - Product Insights (Attribution Analysis)
    private var productInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section description
            Text("多产品使用时，分析各产品对皮肤变化的贡献")
                .font(.skinLabCaption)
                .foregroundColor(.skinLabSubtext)

            // Product insights with attribution
            ForEach(report.productInsights.prefix(5), id: \.productId) { insight in
                ProductInsightRow(insight: insight)
            }

            // Multi-product usage tip (if any product needs solo validation)
            let needsValidation = report.productInsights.contains { $0.needsSoloUsageValidation }
            if needsValidation {
                MultiProductUsageTip()
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

    // MARK: - Data Quality
    private var dataQualitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Overall statistics
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.shield")
                        .foregroundColor(.skinLabAccent)
                    Text("数据可靠性")
                        .font(.skinLabSubheadline)
                        .foregroundColor(.skinLabText)

                    Spacer()

                    // Coverage percentage
                    let reliableCount = report.reliabilityMap.values.filter { $0.score >= 0.5 }.count
                    let totalCount = report.reliabilityMap.count
                    let percentage = totalCount > 0 ? Int(Double(reliableCount) / Double(totalCount) * 100) : 0

                    Text("\(reliableCount)/\(totalCount) 可靠 (\(percentage)%)")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }

                // Timeline mode toggle (always visible here)
                TimelineModeToggle(mode: $timelineMode, policy: report.timelinePolicy)
            }

            // Reliability breakdown by check-in
            VStack(alignment: .leading, spacing: 12) {
                Text("各次打卡可靠性")
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)

                // Get check-in IDs sorted by day (use full timeline to show all check-ins including low reliability)
                let sortedCheckInIds = report.timeline
                    .sorted { $0.day < $1.day }
                    .map { $0.checkInId }

                ForEach(sortedCheckInIds, id: \.self) { checkInId in
                    if let reliability = report.reliabilityMap[checkInId] {
                        reliabilityRow(for: checkInId, reliability: reliability)
                    }
                }
            }

            // Low reliability reasons (if any)
            let lowReliabilityItems = report.reliabilityMap.filter { $0.value.level == .low }
            if !lowReliabilityItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("低可靠性原因")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)

                    ForEach(Array(lowReliabilityItems.keys.prefix(3)), id: \.self) { checkInId in
                        if let reliability = lowReliabilityItems[checkInId] {
                            ReliabilityReasonsView(reliability: reliability)
                        }
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    private func reliabilityRow(for checkInId: UUID, reliability: ReliabilityMetadata) -> some View {
        HStack {
            // Find day number
            if let point = report.timeline.first(where: { $0.checkInId == checkInId }) {
                Text("第\(point.day)天")
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
                    .frame(width: 60, alignment: .leading)
            } else {
                Spacer()
                    .frame(width: 60)
            }

            ReliabilityBadgeView(reliability: reliability, size: .small)

            Spacer()

            if reliability.level == .low && !reliability.reasons.isEmpty {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Forecast Section
    private var forecastSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Risk Alerts (prominently displayed if present)
            if !report.riskAlerts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("风险预警")
                            .font(.skinLabSubheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.skinLabText)
                    }

                    ForEach(report.riskAlerts) { alert in
                        PredictiveAlertCard(alert: alert)
                    }
                }
            }

            // Forecast Charts
            ForEach(report.forecasts.indices, id: \.self) { index in
                let forecast = report.forecasts[index]
                ForecastChartView(
                    forecast: forecast,
                    historicalData: report.timeline
                )
            }

            // Overall Data Confidence
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(confidenceColor(report.dataConfidence))
                Text("数据置信度")
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
                Spacer()
                ConfidenceBadgeView(confidence: report.dataConfidence)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding(.top, 4)
    }

    private func confidenceColor(_ confidence: ConfidenceScore) -> Color {
        switch confidence.level {
        case .high: return .green
        case .medium: return .blue
        case .low: return .orange
        case .veryLow: return .red
        }
    }

    // MARK: - Share & Export
    private var shareAndExportSection: some View {
        VStack(spacing: 12) {
            // Image share button
            Button {
                generateShareCard()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("分享报告图片")
                        .font(.skinLabHeadline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient.skinLabRoseGradient)
                .cornerRadius(16)
            }

            // Export buttons
            HStack(spacing: 12) {
                // CSV export
                Button {
                    exportCSV()
                } label: {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("导出 CSV")
                            .font(.skinLabSubheadline)
                    }
                    .foregroundColor(.skinLabPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.skinLabPrimary.opacity(0.1))
                    .cornerRadius(12)
                }

                // JSON export
                Button {
                    exportJSON()
                } label: {
                    HStack {
                        Image(systemName: "doc.text.fill")
                        Text("导出 JSON")
                            .font(.skinLabSubheadline)
                    }
                    .foregroundColor(.skinLabPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.skinLabPrimary.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Export Methods
    private func exportCSV() {
        // Generate CSV content
        var csvLines: [String] = []

        // Header
        csvLines.append("Day,Overall Score,Skin Age,Reliability,Lighting,Angle,Distance,Sleep Hours,Stress Level,Water Intake,Exercise Minutes,Sun Exposure")

        // Data rows
        for point in report.timeline {
            let reliability = report.reliabilityMap[point.checkInId]
            let reliabilityScore = reliability?.score ?? 0

            // Find check-in for lifestyle data
            var sleepHours = ""
            var stressLevel = ""
            var waterIntake = ""
            var exerciseMinutes = ""
            var sunExposure = ""

            // Access check-in through session if available
            // Note: You may need to pass session or checkIns to get this data
            // For now, placeholder values
            csvLines.append("\(point.day),\(point.overallScore),\(point.skinAge),\(Int(reliabilityScore * 100)),,\(sleepHours),\(stressLevel),\(waterIntake),\(exerciseMinutes),\(sunExposure)")
        }

        let csvContent = csvLines.joined(separator: "\n")

        // Save to temp file and share
        if let url = saveToTempFile(content: csvContent, fileExtension: "csv") {
            shareFile(url)
        }
    }

    private func exportJSON() {
        // Create exportable JSON structure
        let exportData: [String: Any] = [
            "report": [
                "duration": report.duration,
                "scoreChange": report.scoreChange,
                "skinAgeChange": report.skinAgeChange,
                "completionRate": report.completionRate,
                "improvementLabel": report.improvementLabel
            ],
            "timeline": report.timeline.map { point in
                [
                    "day": point.day,
                    "overallScore": point.overallScore,
                    "skinAge": point.skinAge,
                    "checkInId": point.checkInId.uuidString
                ]
            },
            "reliability": report.reliabilityMap.mapValues { metadata in
                [
                    "score": metadata.score,
                    "level": metadata.level.rawValue,
                    "reasons": metadata.reasons.map { $0.rawValue }
                ]
            },
            "lifestyleInsights": report.lifestyleInsights.map { insight in
                [
                    "factor": insight.factor.rawValue,
                    "targetMetric": insight.targetMetric,
                    "correlation": insight.correlation,
                    "sampleCount": insight.sampleCount,
                    "confidence": insight.confidence.value,
                    "interpretation": insight.interpretation
                ]
            }
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8),
               let url = saveToTempFile(content: jsonString, fileExtension: "json") {
                shareFile(url)
            }
        } catch {
            AppLogger.error("Failed to generate JSON for export", error: error)
        }
    }

    private func saveToTempFile(content: String, fileExtension: String) -> URL? {
        let fileName = "SkinLab_Report_\(Date().timeIntervalSince1970).\(fileExtension)"
        if let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let fileURL = url.appendingPathComponent(fileName)
            do {
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
                return fileURL
            } catch {
                AppLogger.error("Failed to save temporary file", error: error)
            }
        }
        return nil
    }

    private func shareFile(_ url: URL) {
        // Show share sheet with file
        // You'll need to add @State var showFileShareSheet and fileToShare
        // For now, placeholder
        AppLogger.debug("Sharing file: \(url)")
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

// MARK: - Predictive Alert Card
struct PredictiveAlertCard: View {
    let alert: PredictiveAlert

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with severity icon and metric
            HStack {
                Image(systemName: alert.icon)
                    .foregroundColor(alertColor)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(alert.severity.rawValue)
                            .font(.skinLabCaption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(alertColor.opacity(0.2))
                            .foregroundColor(alertColor)
                            .cornerRadius(4)

                        Text(alert.metric)
                            .font(.skinLabSubheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.skinLabText)
                    }

                    Text(alert.message)
                        .font(.skinLabBody)
                        .foregroundColor(.skinLabText)
                }

                Spacer()

                // Predicted date badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text(alert.predictedDateText)
                        .font(.skinLabCaption)
                        .fontWeight(.medium)
                        .foregroundColor(.skinLabSubtext)
                    ConfidenceBadgeView(confidence: alert.confidence)
                }
            }

            // Action suggestion
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text(alert.actionSuggestion)
                    .font(.skinLabCaption)
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(alertColor.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(alertColor.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private var alertColor: Color {
        switch alert.severity {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}
