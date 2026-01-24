import Foundation

// MARK: - Score Point for Timeline Charts
struct ScorePoint: Codable, Identifiable {
    let id: UUID
    let day: Int
    let date: Date
    let overallScore: Int
    let skinAge: Int
    let issueScores: IssueScores?
    let regionScores: RegionScores?
    let checkInId: UUID

    init(id: UUID = UUID(), day: Int, date: Date, overallScore: Int, skinAge: Int, issueScores: IssueScores? = nil, regionScores: RegionScores? = nil, checkInId: UUID = UUID()) {
        self.id = id
        self.day = day
        self.date = date
        self.overallScore = overallScore
        self.skinAge = skinAge
        self.issueScores = issueScores
        self.regionScores = regionScores
        self.checkInId = checkInId
    }
}

// MARK: - Trend Data
struct TrendData: Codable {
    let metric: String
    let slope: Double // Linear regression slope
    let movingAverage: [Double] // 7-day moving average
    let trend: TrendDirection

    enum TrendDirection: String, Codable {
        case improving = "改善"
        case stable = "稳定"
        case worsening = "恶化"
    }
}

// MARK: - Enhanced Tracking Report
struct EnhancedTrackingReport: Codable {
    let sessionId: UUID
    let duration: Int
    let checkInCount: Int
    let completionRate: Double

    // Images
    let beforePhotoPath: String?
    let afterPhotoPath: String?

    // Analysis IDs for detailed comparison
    let beforeAnalysisId: UUID?
    let afterAnalysisId: UUID?

    // Overall changes
    let overallImprovement: Double
    let scoreChange: Int
    let skinAgeChange: Int

    // Timeline data for charts
    let timeline: [ScorePoint]

    // Trend analysis
    let trendData: [TrendData]

    // Dimension changes
    let dimensionChanges: [TrackingReport.DimensionChange]
    let usedProducts: [TrackingReport.ProductUsage]
    let aiSummary: String?
    let recommendations: [String]
    
    // MARK: - AI-Enhanced Analytics Fields
    
    /// 异常检测结果
    let anomalies: [AnomalyDetectionResult]
    
    /// 趋势预测列表
    let forecasts: [TrendForecast]
    
    /// 热力图数据
    let heatmap: HeatmapData?
    
    /// 季节性模式分析
    let seasonalPatterns: [SeasonalPattern]
    
    /// 整体数据置信度
    let dataConfidence: ConfidenceScore
    
    /// 产品效果深度分析
    let productInsights: [ProductEffectInsight]
    
    /// 数据质量评估
    let dataQualityScore: Double?
    let dataQualityDescription: String?

    // MARK: - Photo Standardization & Reliability Fields

    /// 可靠性元数据映射（按 checkIn ID）
    let reliabilityMap: [UUID: ReliabilityMetadata]

    /// 可靠时间线（仅包含可靠数据点）
    let timelineReliable: [ScorePoint]

    /// 时间线显示策略
    let timelinePolicy: TimelineDisplayPolicy

    // MARK: - Lifestyle Correlation Fields

    /// 生活方式关联洞察
    let lifestyleInsights: [LifestyleCorrelationInsight]

    /// 生活方式数据完整度（有生活方式数据的打卡比例）
    let lifestyleDataCoverage: Double

    // Computed properties for UI
    var hasSignificantImprovement: Bool {
        overallImprovement > 10
    }

    var improvementLabel: String {
        if overallImprovement > 15 { return "显著改善" }
        if overallImprovement > 5 { return "有所改善" }
        if overallImprovement > -5 { return "基本稳定" }
        return "需要调整"
    }

    var topImprovements: [TrackingReport.DimensionChange] {
        dimensionChanges
            .filter { $0.improvement > 0 }
            .sorted { $0.improvement > $1.improvement }
            .prefix(3)
            .map { $0 }
    }

    var issuesNeedingAttention: [TrackingReport.DimensionChange] {
        dimensionChanges
            .filter { $0.improvement < 0 }
            .sorted { $0.improvement < $1.improvement }
            .prefix(3)
            .map { $0 }
    }
    
    /// 高风险预警列表
    var riskAlerts: [PredictiveAlert] {
        forecasts.compactMap { $0.riskAlert }
    }
    
    /// 是否有异常需要关注
    var hasAnomalies: Bool {
        !anomalies.isEmpty
    }
    
    /// 严重异常数量
    var severeAnomaliesCount: Int {
        anomalies.filter { $0.severity == .severe }.count
    }
}

// MARK: - Report Generator
@MainActor
final class TrackingReportGenerator {
    private let geminiService: GeminiService

    init(geminiService: GeminiService = GeminiService()) {
        self.geminiService = geminiService
    }

    func generateReport(
        session: TrackingSession,
        checkIns: [CheckIn],
        analyses: [UUID: SkinAnalysis],
        productDatabase: [String: Product] = [:],
        historyStore: UserHistoryStore? = nil
    ) async -> EnhancedTrackingReport? {
        guard checkIns.count >= 2 else { return nil }

        // Get first and last check-in
        let sortedCheckIns = checkIns.sorted { $0.day < $1.day }
        guard let firstCheckIn = sortedCheckIns.first,
              let lastCheckIn = sortedCheckIns.last,
              let beforeAnalysisId = firstCheckIn.analysisId,
              let afterAnalysisId = lastCheckIn.analysisId,
              let beforeAnalysis = analyses[beforeAnalysisId],
              let afterAnalysis = analyses[afterAnalysisId] else {
            return nil
        }

        // Build timeline
        let timeline = sortedCheckIns.compactMap { checkIn -> ScorePoint? in
            guard let analysisId = checkIn.analysisId,
                  let analysis = analyses[analysisId] else {
                return nil
            }

            return ScorePoint(
                day: checkIn.day,
                date: checkIn.captureDate,
                overallScore: analysis.overallScore,
                skinAge: analysis.skinAge,
                issueScores: analysis.issues,
                regionScores: analysis.regions,
                checkInId: checkIn.id
            )
        }

        // Calculate changes
        let scoreChange = afterAnalysis.overallScore - beforeAnalysis.overallScore
        let skinAgeChange = afterAnalysis.skinAge - beforeAnalysis.skinAge
        let overallImprovement = Double(scoreChange)

        // Advanced trend analysis
        let trendData = calculateTrendAnalysis(timeline: timeline)

        // Dimension changes
        let dimensionChanges = calculateDimensionChanges(before: beforeAnalysis, after: afterAnalysis)

        // Enhanced product usage with effectiveness
        let productUsage = await calculateProductEffectiveness(
            checkIns: sortedCheckIns,
            analyses: analyses,
            productDatabase: productDatabase
        )
        
        // MARK: - AI-Enhanced Analytics Integration
        
        // Initialize analyzers
        let tsAnalyzer = TimeSeriesAnalyzer()
        let anomalyDetector = AnomalyDetector()
        let forecastEngine = ForecastEngine()
        let seasonalityAnalyzer = SeasonalityAnalyzer()
        let productAnalyzer = ProductEffectAnalyzer()
        
        // 1. Anomaly Detection
        let anomalies = detectAnomalies(timeline: timeline, detector: anomalyDetector)
        
        // 2. Trend Forecasting
        let forecasts = generateForecasts(timeline: timeline, analyses: analyses, engine: forecastEngine)
        
        // 3. Heatmap Data
        let heatmap = generateHeatmap(timeline: timeline)
        
        // 4. Seasonal Analysis
        let seasonalPatterns = await analyzeSeasonality(
            analyses: analyses,
            checkIns: sortedCheckIns,
            analyzer: seasonalityAnalyzer,
            historyStore: historyStore
        )
        
        // 5. Data Quality Assessment
        let overallScores = timeline.map { Double($0.overallScore) }
        let dataQuality = anomalyDetector.assessDataQuality(values: overallScores)
        
        // 6. Enhanced Product Insights
        let productInsights = await productAnalyzer.evaluate(
            checkIns: sortedCheckIns,
            analyses: analyses,
            productDatabase: productDatabase,
            historyStore: historyStore
        )
        
        // 7. Overall Confidence Score
        let dataConfidence = calculateOverallConfidence(
            timeline: timeline,
            dataQuality: dataQuality,
            anomalyCount: anomalies.count,
            analyzer: tsAnalyzer
        )

        // MARK: - Photo Standardization & Reliability Analysis

        // 8. Build reliability map - prefer stored reliability, compute as fallback
        let reliabilityScorer = ReliabilityScorer()
        var reliabilityMap: [UUID: ReliabilityMetadata] = [:]

        for checkIn in sortedCheckIns {
            if let stored = checkIn.reliability {
                // Use stored reliability (computed at capture time)
                reliabilityMap[checkIn.id] = stored
            } else if let analysis = checkIn.analysisId.flatMap({ analyses[$0] }) {
                // Fallback: compute reliability for older check-ins
                let expectedDay = session.expectedDay(for: checkIn.day)
                reliabilityMap[checkIn.id] = reliabilityScorer.score(
                    checkIn: checkIn,
                    analysis: analysis,
                    session: session,
                    expectedDay: expectedDay
                )
            }
        }

        // 9. Build reliable timeline (filter by reliability score >= 0.5)
        // CRITICAL: Use checkInId for joins, never day (spec rule #1)
        let timelineReliable = timeline.filter { point in
            guard let reliability = reliabilityMap[point.checkInId] else {
                return false
            }
            return reliability.score >= 0.5
        }

        // 10. Timeline display policy
        let timelinePolicy = TimelineDisplayPolicy(
            allCount: timeline.count,
            reliableCount: timelineReliable.count
        )

        // MARK: - Lifestyle Correlation Analysis

        // 11. Calculate lifestyle data coverage
        let checkInsWithLifestyle = sortedCheckIns.filter { $0.lifestyle != nil }
        let lifestyleCoverage = Double(checkInsWithLifestyle.count) / Double(max(sortedCheckIns.count, 1))

        // 12. Run lifestyle correlation analysis
        let lifestyleAnalyzer = LifestyleCorrelationAnalyzer()
        let lifestyleInsights = lifestyleAnalyzer.analyze(
            checkIns: sortedCheckIns,
            timeline: timeline,
            reliability: reliabilityMap
        )

        // Generate AI summary (enhanced with new analytics)
        let aiSummary = await generateEnhancedAISummary(
            trendData: trendData,
            dimensionChanges: dimensionChanges,
            productUsage: productUsage,
            improvement: overallImprovement,
            anomalies: anomalies,
            forecasts: forecasts,
            productInsights: productInsights
        )

        return EnhancedTrackingReport(
            sessionId: session.id,
            duration: session.duration,
            checkInCount: checkIns.count,
            completionRate: Double(checkIns.count) / 5.0,
            beforePhotoPath: firstCheckIn.photoPath,
            afterPhotoPath: lastCheckIn.photoPath,
            beforeAnalysisId: beforeAnalysisId,
            afterAnalysisId: afterAnalysisId,
            overallImprovement: overallImprovement,
            scoreChange: scoreChange,
            skinAgeChange: skinAgeChange,
            timeline: timeline,
            trendData: trendData,
            dimensionChanges: dimensionChanges,
            usedProducts: productUsage,
            aiSummary: aiSummary,
            recommendations: generateRecommendations(
                changes: dimensionChanges,
                improvement: overallImprovement,
                trendData: trendData
            ),
            anomalies: anomalies,
            forecasts: forecasts,
            heatmap: heatmap,
            seasonalPatterns: seasonalPatterns,
            dataConfidence: dataConfidence,
            productInsights: productInsights,
            dataQualityScore: dataQuality.score,
            dataQualityDescription: dataQuality.description,
            reliabilityMap: reliabilityMap,
            timelineReliable: timelineReliable,
            timelinePolicy: timelinePolicy,
            lifestyleInsights: lifestyleInsights,
            lifestyleDataCoverage: lifestyleCoverage
        )
    }

    // MARK: - Advanced Trend Analysis
    private func calculateTrendAnalysis(timeline: [ScorePoint]) -> [TrendData] {
        guard timeline.count >= 3 else { return [] }

        var trends: [TrendData] = []

        // Overall score trend
        let overallScores = timeline.map { Double($0.overallScore) }
        if let overallTrend = calculateTrend(values: overallScores, metricName: "综合评分") {
            trends.append(overallTrend)
        }

        // Skin age trend
        let skinAges = timeline.map { Double($0.skinAge) }
        if let ageTrend = calculateTrend(values: skinAges, metricName: "皮肤年龄", invertDirection: true) {
            trends.append(ageTrend)
        }

        return trends
    }

    private func calculateTrend(
        values: [Double],
        metricName: String,
        invertDirection: Bool = false
    ) -> TrendData? {
        guard values.count >= 3 else { return nil }

        // Linear regression
        let n = Double(values.count)
        let xValues = Array(0..<values.count).map { Double($0) }
        let xMean = xValues.reduce(0, +) / n
        let yMean = values.reduce(0, +) / n

        var numerator = 0.0
        var denominator = 0.0

        for i in 0..<values.count {
            let xDiff = xValues[i] - xMean
            let yDiff = values[i] - yMean
            numerator += xDiff * yDiff
            denominator += xDiff * xDiff
        }

        let slope = denominator != 0 ? numerator / denominator : 0

        // Moving average (3-point for smoothing)
        var movingAverage: [Double] = []
        let window = min(3, values.count)

        for i in 0..<values.count {
            let start = max(0, i - window + 1)
            let range = start...i
            let avg = range.map { values[$0] }.reduce(0, +) / Double(range.count)
            movingAverage.append(avg)
        }

        // Determine trend direction
        let effectiveSlope = invertDirection ? -slope : slope
        let trend: TrendData.TrendDirection
        if effectiveSlope > 0.5 {
            trend = .improving
        } else if effectiveSlope < -0.5 {
            trend = .worsening
        } else {
            trend = .stable
        }

        return TrendData(
            metric: metricName,
            slope: slope,
            movingAverage: movingAverage,
            trend: trend
        )
    }

    // MARK: - Product Effectiveness Calculation
    private func calculateProductEffectiveness(
        checkIns: [CheckIn],
        analyses: [UUID: SkinAnalysis],
        productDatabase: [String: Product]
    ) async -> [TrackingReport.ProductUsage] {
        var productScores: [String: (totalScore: Double, count: Int, usageDays: Int)] = [:]

        // Calculate score changes for each product
        for i in 0..<(checkIns.count - 1) {
            let currentCheckIn = checkIns[i]
            let nextCheckIn = checkIns[i + 1]

            guard let currentAnalysisId = currentCheckIn.analysisId,
                  let nextAnalysisId = nextCheckIn.analysisId,
                  let currentAnalysis = analyses[currentAnalysisId],
                  let nextAnalysis = analyses[nextAnalysisId] else {
                continue
            }

            // Score change (positive = improvement)
            let scoreChange = Double(nextAnalysis.overallScore - currentAnalysis.overallScore)

            // Feeling score (better=+1, same=0, worse=-1)
            let feelingScore = nextCheckIn.feeling?.score ?? 0

            // Days between check-ins (weight: prefer 3-10 day intervals)
            let daysDiff = nextCheckIn.day - currentCheckIn.day
            let timeWeight = calculateTimeWeight(daysDiff: daysDiff)

            // Attribute score to products used in current check-in
            let combinedScore = (scoreChange + Double(feelingScore)) * timeWeight

            for productId in currentCheckIn.usedProducts {
                let current = productScores[productId] ?? (0, 0, 0)
                productScores[productId] = (
                    current.totalScore + combinedScore,
                    current.count + 1,
                    current.usageDays + 1
                )
            }
        }

        // Convert to ProductUsage with effectiveness rating
        return productScores.map { (productId, data) in
            let avgScore = data.totalScore / Double(data.count)
            let effectiveness = classifyEffectiveness(score: avgScore, sampleSize: data.count)
            let productName = productDatabase[productId]?.name ?? productId

            return TrackingReport.ProductUsage(
                productId: productId,
                productName: productName,
                usageDays: data.usageDays,
                effectiveness: effectiveness
            )
        }.sorted { ($0.effectiveness?.rawValue ?? "") > ($1.effectiveness?.rawValue ?? "") }
    }

    private func calculateTimeWeight(daysDiff: Int) -> Double {
        // Optimal: 3-10 days between check-ins
        if daysDiff < 3 {
            return 0.5 // Too soon, might not see effect
        } else if daysDiff <= 10 {
            return 1.0 // Ideal window
        } else {
            return 0.7 // Too long, other factors may interfere
        }
    }

    private func classifyEffectiveness(score: Double, sampleSize: Int) -> TrackingReport.ProductUsage.Effectiveness? {
        // Low confidence if sample size < 2
        guard sampleSize >= 2 else { return nil }

        if score > 1.5 {
            return .effective
        } else if score < -1.5 {
            return .ineffective
        } else {
            return .neutral
        }
    }

    // MARK: - AI Summary Generation
    private func generateAISummary(
        trendData: [TrendData],
        dimensionChanges: [TrackingReport.DimensionChange],
        productUsage: [TrackingReport.ProductUsage],
        improvement: Double
    ) async -> String? {
        // Build concise summary prompt
        var prompt = """
        根据以下追踪数据，生成3-5条简洁的bullet摘要（每条不超过20字）：

        总体改善：\(String(format: "%.1f", improvement))%

        """

        // Trend analysis
        if !trendData.isEmpty {
            prompt += "\n趋势分析：\n"
            for trend in trendData {
                prompt += "- \(trend.metric)：\(trend.trend.rawValue)（斜率\(String(format: "%.2f", trend.slope))）\n"
            }
        }

        // Top improvements and concerns
        let top3Improvements = dimensionChanges.filter { $0.improvement > 0 }.sorted { $0.improvement > $1.improvement }.prefix(3)
        let top3Concerns = dimensionChanges.filter { $0.improvement < 0 }.sorted { $0.improvement < $1.improvement }.prefix(3)

        if !top3Improvements.isEmpty {
            prompt += "\n改善：\n"
            for change in top3Improvements {
                prompt += "- \(change.dimension)从\(change.beforeScore)到\(change.afterScore)\n"
            }
        }

        if !top3Concerns.isEmpty {
            prompt += "\n需关注：\n"
            for change in top3Concerns {
                prompt += "- \(change.dimension)从\(change.beforeScore)到\(change.afterScore)\n"
            }
        }

        // Effective products
        let effectiveProducts = productUsage.filter { $0.effectiveness == .effective }.prefix(2)
        if !effectiveProducts.isEmpty {
            prompt += "\n有效产品：\(effectiveProducts.map { $0.productName }.joined(separator: "、"))\n"
        }

        prompt += """

        输出格式：仅返回3-5条bullet要点，每条以"·"开头，不要其他文字。
        例如：
        · 整体皮肤状况稳步改善
        · 痘痘问题显著减少
        · 需重点关注泛红问题
        """

        do {
            let response = try await geminiService.generateRoutine(prompt: prompt)
            // Clean up response
            let lines = response.split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.hasPrefix("·") || $0.hasPrefix("-") || $0.hasPrefix("•") }
                .map { line -> String in
                    var clean = line
                    if clean.hasPrefix("-") || clean.hasPrefix("•") {
                        clean = "·" + clean.dropFirst()
                    }
                    return clean.trimmingCharacters(in: .whitespaces)
                }
                .prefix(5)

            return lines.isEmpty ? nil : lines.joined(separator: "\n")
        } catch {
            print("Failed to generate AI summary: \(error)")
            return nil
        }
    }

    // MARK: - Dimension Changes
    private func calculateDimensionChanges(before: SkinAnalysis, after: SkinAnalysis) -> [TrackingReport.DimensionChange] {
        return [
            TrackingReport.DimensionChange(
                dimension: "斑点",
                beforeScore: before.issues.spots,
                afterScore: after.issues.spots,
                improvement: Double(before.issues.spots - after.issues.spots)
            ),
            TrackingReport.DimensionChange(
                dimension: "痘痘",
                beforeScore: before.issues.acne,
                afterScore: after.issues.acne,
                improvement: Double(before.issues.acne - after.issues.acne)
            ),
            TrackingReport.DimensionChange(
                dimension: "毛孔",
                beforeScore: before.issues.pores,
                afterScore: after.issues.pores,
                improvement: Double(before.issues.pores - after.issues.pores)
            ),
            TrackingReport.DimensionChange(
                dimension: "皱纹",
                beforeScore: before.issues.wrinkles,
                afterScore: after.issues.wrinkles,
                improvement: Double(before.issues.wrinkles - after.issues.wrinkles)
            ),
            TrackingReport.DimensionChange(
                dimension: "泛红",
                beforeScore: before.issues.redness,
                afterScore: after.issues.redness,
                improvement: Double(before.issues.redness - after.issues.redness)
            ),
            TrackingReport.DimensionChange(
                dimension: "均匀度",
                beforeScore: before.issues.evenness,
                afterScore: after.issues.evenness,
                improvement: Double(before.issues.evenness - after.issues.evenness)
            ),
            TrackingReport.DimensionChange(
                dimension: "质感",
                beforeScore: before.issues.texture,
                afterScore: after.issues.texture,
                improvement: Double(before.issues.texture - after.issues.texture)
            )
        ]
    }

    // MARK: - Recommendations
    private func generateRecommendations(
        changes: [TrackingReport.DimensionChange],
        improvement: Double,
        trendData: [TrendData]
    ) -> [String] {
        var recommendations: [String] = []

        // Overall trend-based recommendations
        let improvingTrends = trendData.filter { $0.trend == .improving }.count
        let worseningTrends = trendData.filter { $0.trend == .worsening }.count

        if improvingTrends > worseningTrends {
            recommendations.append("✨ 整体趋势向好，建议继续坚持当前护肤方案")
        } else if worseningTrends > improvingTrends {
            recommendations.append("⚠️ 整体趋势下滑，建议调整护肤方案")
        } else {
            recommendations.append("📊 皮肤状态基本稳定，可尝试针对性加强护理")
        }

        // Dimension-specific recommendations (focus on worst 2)
        let worstIssues = changes
            .filter { $0.improvement < -3 }
            .sorted { $0.improvement < $1.improvement }
            .prefix(2)

        for issue in worstIssues {
            recommendations.append("🎯 \(issue.dimension)恶化明显（\(issue.beforeScore)→\(issue.afterScore)），建议重点关注")
        }

        // Celebrate top improvement
        if let topImprovement = changes.first(where: { $0.improvement > 5 }) {
            recommendations.append("🎉 \(topImprovement.dimension)改善显著！继续保持")
        }

        return Array(recommendations.prefix(5))
    }
    
    // MARK: - AI-Enhanced Analytics Helper Methods
    
    /// 检测异常点
    private func detectAnomalies(
        timeline: [ScorePoint],
        detector: AnomalyDetector
    ) -> [AnomalyDetectionResult] {
        guard timeline.count >= 3 else { return [] }
        
        let values = timeline.map { Double($0.overallScore) }
        let days = timeline.map { $0.day }
        let dates = timeline.map { $0.date }
        
        var allAnomalies: [AnomalyDetectionResult] = []
        
        // 检测综合评分异常
        allAnomalies.append(contentsOf: detector.detect(
            values: values,
            days: days,
            dates: dates,
            metric: "综合评分",
            method: .mad
        ))
        
        // 检测痘痘异常
        let acneValues = timeline.compactMap { $0.issueScores?.acne }.map { Double($0) }
        if acneValues.count >= 3 {
            allAnomalies.append(contentsOf: detector.detect(
                values: acneValues,
                days: Array(days.prefix(acneValues.count)),
                dates: Array(dates.prefix(acneValues.count)),
                metric: "痘痘",
                method: .mad
            ))
        }
        
        // 检测泛红异常
        let rednessValues = timeline.compactMap { $0.issueScores?.redness }.map { Double($0) }
        if rednessValues.count >= 3 {
            allAnomalies.append(contentsOf: detector.detect(
                values: rednessValues,
                days: Array(days.prefix(rednessValues.count)),
                dates: Array(dates.prefix(rednessValues.count)),
                metric: "泛红",
                method: .mad
            ))
        }
        
        return allAnomalies.sorted { $0.severity.rawValue > $1.severity.rawValue }
    }
    
    /// 生成趋势预测
    private func generateForecasts(
        timeline: [ScorePoint],
        analyses: [UUID: SkinAnalysis],
        engine: ForecastEngine
    ) -> [TrendForecast] {
        guard timeline.count >= 3 else { return [] }
        
        var forecasts: [TrendForecast] = []
        
        // 综合评分预测
        let overallValues = timeline.map { Double($0.overallScore) }
        let days = timeline.map { $0.day }
        if let overallForecast = engine.forecast(
            values: overallValues,
            days: days,
            horizon: 7,
            metric: "综合评分"
        ) {
            forecasts.append(overallForecast)
        }
        
        // 痘痘趋势预测
        let acneValues = timeline.compactMap { $0.issueScores?.acne }.map { Double($0) }
        if acneValues.count >= 3 {
            let (acneForecast, riskLevel) = engine.predictAcneTrend(
                acneHistory: acneValues,
                days: Array(days.prefix(acneValues.count)),
                horizon: 7
            )
            if let forecast = acneForecast {
                forecasts.append(forecast)
            }
        }
        
        // 皮肤年龄预测
        let skinAgeValues = timeline.map { Double($0.skinAge) }
        if let ageForecast = engine.forecast(
            values: skinAgeValues,
            days: days,
            horizon: 14,
            metric: "皮肤年龄"
        ) {
            forecasts.append(ageForecast)
        }
        
        return forecasts
    }
    
    /// 生成热力图数据
    private func generateHeatmap(timeline: [ScorePoint]) -> HeatmapData? {
        guard timeline.count >= 3 else { return nil }
        
        var cells: [HeatmapCell] = []
        
        // 为每个时间点的各个维度生成热力图单元
        for point in timeline {
            guard let issues = point.issueScores else { continue }
            
            let dimensions: [(String, Int)] = [
                ("痘痘", issues.acne),
                ("斑点", issues.spots),
                ("毛孔", issues.pores),
                ("皱纹", issues.wrinkles),
                ("泛红", issues.redness),
                ("质感", issues.texture),
                ("均匀度", issues.evenness)
            ]
            
            for (dimension, value) in dimensions {
                cells.append(HeatmapCell(
                    day: point.day,
                    dimension: dimension,
                    value: Double(value) / 10.0  // 归一化到0-1
                ))
            }
        }
        
        return HeatmapData(
            title: "皮肤问题热力图",
            cells: cells,
            valueRange: 0...1
        )
    }
    
    /// 分析季节性模式
    private func analyzeSeasonality(
        analyses: [UUID: SkinAnalysis],
        checkIns: [CheckIn],
        analyzer: SeasonalityAnalyzer,
        historyStore: UserHistoryStore?
    ) async -> [SeasonalPattern] {
        
        // 将当前追踪的分析数据转换为带日期的格式
        let analysesWithDates = checkIns.compactMap { checkIn -> SkinAnalysisWithDate? in
            guard let analysisId = checkIn.analysisId,
                  let analysis = analyses[analysisId] else {
                return nil
            }
            return SkinAnalysisWithDate(analysis: analysis, date: checkIn.captureDate)
        }
        
        // 如果有历史数据,合并进来
        var allAnalyses = analysesWithDates
        if let historyStore = historyStore {
            let historyAnalyses = await historyStore.getRecentAnalyses(limit: 20)
            let historyWithDates = historyAnalyses.map {
                SkinAnalysisWithDate(analysis: $0, date: $0.analyzedAt)
            }
            allAnalyses.append(contentsOf: historyWithDates)
        }
        
        return analyzer.analyzeSeasonalPattern(analyses: allAnalyses)
    }
    
    /// 计算整体置信度
    private func calculateOverallConfidence(
        timeline: [ScorePoint],
        dataQuality: (score: Double, description: String),
        anomalyCount: Int,
        analyzer: TimeSeriesAnalyzer
    ) -> ConfidenceScore {
        
        let sampleCount = timeline.count
        let qualityScore = dataQuality.score
        
        // 异常点惩罚
        let anomalyPenalty = min(0.3, Double(anomalyCount) * 0.1)
        
        // 综合置信度
        var confidenceValue = qualityScore - anomalyPenalty
        confidenceValue = max(0, min(1, confidenceValue))
        
        return ConfidenceScore(
            value: confidenceValue,
            sampleCount: sampleCount,
            method: "综合评估"
        )
    }
    
    /// 生成增强版AI摘要
    private func generateEnhancedAISummary(
        trendData: [TrendData],
        dimensionChanges: [TrackingReport.DimensionChange],
        productUsage: [TrackingReport.ProductUsage],
        improvement: Double,
        anomalies: [AnomalyDetectionResult],
        forecasts: [TrendForecast],
        productInsights: [ProductEffectInsight]
    ) async -> String? {
        
        var prompt = """
        根据以下追踪数据，生成3-5条简洁的bullet摘要（每条不超过20字）：

        总体改善：\(String(format: "%.1f", improvement))%

        """

        // Trend analysis
        if !trendData.isEmpty {
            prompt += "\n趋势分析：\n"
            for trend in trendData {
                prompt += "- \(trend.metric)：\(trend.trend.rawValue)（斜率\(String(format: "%.2f", trend.slope))）\n"
            }
        }
        
        // Anomaly alerts
        if !anomalies.isEmpty {
            prompt += "\n异常检测：\n"
            let severeAnomalies = anomalies.filter { $0.severity == .severe }.prefix(2)
            for anomaly in severeAnomalies {
                prompt += "- \(anomaly.metric)在第\(anomaly.day)天出现\(anomaly.severity.rawValue)异常\n"
            }
        }
        
        // Forecast alerts
        let riskForecasts = forecasts.filter { $0.riskAlert != nil }
        if !riskForecasts.isEmpty {
            prompt += "\n趋势预警：\n"
            for forecast in riskForecasts {
                if let alert = forecast.riskAlert {
                    prompt += "- [\(alert.severity.rawValue)] \(alert.message): \(alert.actionSuggestion)\n"
                }
            }
        }

        // Top improvements and concerns
        let top3Improvements = dimensionChanges.filter { $0.improvement > 0 }.sorted { $0.improvement > $1.improvement }.prefix(3)
        let top3Concerns = dimensionChanges.filter { $0.improvement < 0 }.sorted { $0.improvement < $1.improvement }.prefix(3)

        if !top3Improvements.isEmpty {
            prompt += "\n改善：\n"
            for change in top3Improvements {
                prompt += "- \(change.dimension)从\(change.beforeScore)到\(change.afterScore)\n"
            }
        }

        if !top3Concerns.isEmpty {
            prompt += "\n需关注：\n"
            for change in top3Concerns {
                prompt += "- \(change.dimension)从\(change.beforeScore)到\(change.afterScore)\n"
            }
        }

        // Enhanced product insights
        let highlyEffective = productInsights.filter { $0.effectLevel == .highlyEffective }.prefix(2)
        if !highlyEffective.isEmpty {
            prompt += "\n高效产品：\(highlyEffective.map { $0.productName }.joined(separator: "、"))\n"
        }

        prompt += """

        输出格式：仅返回3-5条bullet要点，每条以·开头，不要其他文字。
        例如：
        · 整体皮肤状况稳步改善
        · 痘痘问题显著减少
        · 需重点关注泛红问题
        """

        do {
            let response = try await geminiService.generateRoutine(prompt: prompt)
            // Clean up response
            let lines = response.split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.hasPrefix("·") || $0.hasPrefix("-") || $0.hasPrefix("•") }
                .map { line -> String in
                    var clean = line
                    if clean.hasPrefix("-") || clean.hasPrefix("•") {
                        clean = "·" + clean.dropFirst()
                    }
                    return clean.trimmingCharacters(in: .whitespaces)
                }
                .prefix(5)

            return lines.isEmpty ? nil : lines.joined(separator: "\n")
        } catch {
            print("Failed to generate AI summary: \(error)")
            return nil
        }
    }
}
