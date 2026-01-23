// SkinLabTests/Tracking/TrackingModelsTests.swift
import XCTest

@testable import SkinLab

final class TrackingSessionTests: XCTestCase {

    // MARK: - TrackingStatus Tests

    func testTrackingStatus_rawValues() {
        XCTAssertNotNil(TrackingStatus(rawValue: "active"))
        XCTAssertNotNil(TrackingStatus(rawValue: "completed"))
        XCTAssertNotNil(TrackingStatus(rawValue: "abandoned"))
    }

    // MARK: - CheckIn Tests

    func testCheckIn_initialization() {
        let sessionId = UUID()
        let checkIn = CheckIn(
            sessionId: sessionId,
            day: 1,
            captureDate: Date(),
            photoPath: "/path/to/photo.jpg",
            analysisId: UUID(),
            usedProducts: ["Product1", "Product2"],
            notes: "Feeling good",
            feeling: .better
        )

        XCTAssertEqual(checkIn.sessionId, sessionId)
        XCTAssertEqual(checkIn.day, 1)
        XCTAssertEqual(checkIn.photoPath, "/path/to/photo.jpg")
        XCTAssertEqual(checkIn.usedProducts.count, 2)
        XCTAssertEqual(checkIn.notes, "Feeling good")
        XCTAssertEqual(checkIn.feeling, .better)
    }

    func testCheckIn_minimalInitialization() {
        let checkIn = CheckIn(
            sessionId: UUID(),
            day: 1,
            captureDate: Date(),
            photoPath: nil,
            analysisId: nil,
            usedProducts: [],
            notes: nil,
            feeling: nil
        )

        XCTAssertNil(checkIn.photoPath)
        XCTAssertNil(checkIn.analysisId)
        XCTAssertTrue(checkIn.usedProducts.isEmpty)
        XCTAssertNil(checkIn.notes)
        XCTAssertNil(checkIn.feeling)
    }

    func testCheckIn_feeling_cases() {
        XCTAssertEqual(CheckIn.Feeling.better.rawValue, "better")
        XCTAssertEqual(CheckIn.Feeling.same.rawValue, "same")
        XCTAssertEqual(CheckIn.Feeling.worse.rawValue, "worse")
    }

    // MARK: - TrackingReport Tests

    func testTrackingReport_initialization() {
        let report = TrackingReport(
            sessionId: UUID(),
            duration: 28,
            checkInCount: 14,
            completionRate: 0.5,
            beforePhotoPath: "/before.jpg",
            afterPhotoPath: "/after.jpg",
            overallImprovement: 0.15,
            scoreChange: 10,
            skinAgeChange: -2,
            dimensionChanges: [],
            usedProducts: [],
            aiSummary: "Good progress",
            recommendations: ["Keep it up"]
        )

        XCTAssertEqual(report.duration, 28)
        XCTAssertEqual(report.checkInCount, 14)
        XCTAssertEqual(report.completionRate, 0.5, accuracy: 0.001)
        XCTAssertEqual(report.overallImprovement, 0.15, accuracy: 0.001)
        XCTAssertEqual(report.scoreChange, 10)
        XCTAssertEqual(report.skinAgeChange, -2)
    }

    // MARK: - DimensionChange Tests

    func testDimensionChange_trend_improved() {
        let change = TrackingReport.DimensionChange(
            dimension: "痘痘",
            beforeScore: 6,
            afterScore: 3,
            improvement: -50.0
        )

        XCTAssertEqual(change.trend, "↓")
    }

    func testDimensionChange_trend_worsened() {
        let change = TrackingReport.DimensionChange(
            dimension: "痘痘",
            beforeScore: 3,
            afterScore: 6,
            improvement: 50.0
        )

        XCTAssertEqual(change.trend, "↑")
    }

    func testDimensionChange_trend_noChange() {
        let change = TrackingReport.DimensionChange(
            dimension: "痘痘",
            beforeScore: 5,
            afterScore: 5,
            improvement: 0.0
        )

        XCTAssertEqual(change.trend, "→")
    }

    // MARK: - ProductUsage Tests

    func testProductUsage_initialization() {
        let usage = TrackingReport.ProductUsage(
            productId: "1",
            productName: "Product A",
            usageDays: 20,
            effectiveness: .effective
        )

        XCTAssertEqual(usage.productId, "1")
        XCTAssertEqual(usage.productName, "Product A")
        XCTAssertEqual(usage.usageDays, 20)
        XCTAssertEqual(usage.effectiveness, .effective)
    }

    func testProductUsage_withNilEffectiveness() {
        let usage = TrackingReport.ProductUsage(
            productId: "2",
            productName: "Product B",
            usageDays: 5,
            effectiveness: nil
        )

        XCTAssertNil(usage.effectiveness)
    }

    func testProductUsage_effectivenessValues() {
        XCTAssertEqual(TrackingReport.ProductUsage.Effectiveness.effective.rawValue, "effective")
        XCTAssertEqual(TrackingReport.ProductUsage.Effectiveness.neutral.rawValue, "neutral")
        XCTAssertEqual(
            TrackingReport.ProductUsage.Effectiveness.ineffective.rawValue, "ineffective")
    }
}

// MARK: - TrendAnalyticsModels Tests

final class TrendAnalyticsModelsTests: XCTestCase {

    // MARK: - ConfidenceScore Tests

    func testConfidenceScore_level_high() {
        let score = ConfidenceScore(value: 0.9, sampleCount: 20, method: "zscore")
        XCTAssertEqual(score.level, .high)
    }

    func testConfidenceScore_level_medium() {
        let score = ConfidenceScore(value: 0.7, sampleCount: 10, method: "mad")
        XCTAssertEqual(score.level, .medium)
    }

    func testConfidenceScore_level_low() {
        let score = ConfidenceScore(value: 0.5, sampleCount: 5, method: "iqr")
        XCTAssertEqual(score.level, .low)
    }

    func testConfidenceScore_level_veryLow() {
        let score = ConfidenceScore(value: 0.2, sampleCount: 2, method: "iqr")
        XCTAssertEqual(score.level, .veryLow)
    }

    // MARK: - ForecastPoint Tests

    func testForecastPoint_initialization() {
        let point = ForecastPoint(
            day: 30,
            date: Date(),
            predictedValue: 80.0,
            lowerBound: 75.0,
            upperBound: 85.0
        )

        XCTAssertEqual(point.day, 30)
        XCTAssertEqual(point.predictedValue, 80.0, accuracy: 0.001)
        XCTAssertEqual(point.lowerBound, 75.0, accuracy: 0.001)
        XCTAssertEqual(point.upperBound, 85.0, accuracy: 0.001)
        XCTAssertNotNil(point.id)
    }

    // MARK: - TrendForecast Tests

    func testTrendForecast_trendDirection_rising() {
        let points = [
            ForecastPoint(day: 1, date: Date(), predictedValue: 70, lowerBound: 65, upperBound: 75),
            ForecastPoint(day: 2, date: Date(), predictedValue: 75, lowerBound: 70, upperBound: 80),
        ]
        let forecast = TrendForecast(
            metric: "overallScore",
            horizonDays: 7,
            points: points,
            confidence: ConfidenceScore(value: 0.8, sampleCount: 10, method: "regression")
        )

        XCTAssertEqual(forecast.trendDirection, "上升")
    }

    func testTrendForecast_trendDirection_falling() {
        let points = [
            ForecastPoint(day: 1, date: Date(), predictedValue: 80, lowerBound: 75, upperBound: 85),
            ForecastPoint(day: 2, date: Date(), predictedValue: 70, lowerBound: 65, upperBound: 75),
        ]
        let forecast = TrendForecast(
            metric: "overallScore",
            horizonDays: 7,
            points: points,
            confidence: ConfidenceScore(value: 0.8, sampleCount: 10, method: "regression")
        )

        XCTAssertEqual(forecast.trendDirection, "下降")
    }

    func testTrendForecast_trendDirection_stable() {
        let points = [
            ForecastPoint(day: 1, date: Date(), predictedValue: 75, lowerBound: 70, upperBound: 80),
            ForecastPoint(
                day: 2, date: Date(), predictedValue: 75.3, lowerBound: 70, upperBound: 80),
        ]
        let forecast = TrendForecast(
            metric: "overallScore",
            horizonDays: 7,
            points: points,
            confidence: ConfidenceScore(value: 0.8, sampleCount: 10, method: "regression")
        )

        XCTAssertEqual(forecast.trendDirection, "稳定")
    }

    // MARK: - HeatmapData Tests

    func testHeatmapData_dimensions() {
        let cells = [
            HeatmapCell(day: 1, dimension: "痘痘", value: 0.5),
            HeatmapCell(day: 1, dimension: "毛孔", value: 0.3),
            HeatmapCell(day: 2, dimension: "痘痘", value: 0.4),
        ]
        let heatmap = HeatmapData(
            title: "Test Heatmap",
            cells: cells,
            valueRange: 0.0...1.0
        )

        let dimensions = heatmap.dimensions
        XCTAssertTrue(dimensions.contains("痘痘"))
        XCTAssertTrue(dimensions.contains("毛孔"))
    }

    func testHeatmapData_days() {
        let cells = [
            HeatmapCell(day: 1, dimension: "痘痘", value: 0.5),
            HeatmapCell(day: 3, dimension: "痘痘", value: 0.4),
            HeatmapCell(day: 7, dimension: "痘痘", value: 0.3),
        ]
        let heatmap = HeatmapData(
            title: "Test Heatmap",
            cells: cells,
            valueRange: 0.0...1.0
        )

        let days = heatmap.days
        XCTAssertEqual(days, [1, 3, 7])
    }

    func testHeatmapCell_initialization() {
        let cell = HeatmapCell(day: 5, dimension: "泛红", value: 0.6)

        XCTAssertEqual(cell.day, 5)
        XCTAssertEqual(cell.dimension, "泛红")
        XCTAssertEqual(cell.value, 0.6, accuracy: 0.001)
        XCTAssertNotNil(cell.id)
    }

    // MARK: - SeasonalPattern Tests

    func testSeasonalPattern_recommendation() {
        let spring = SeasonalPattern(
            season: "春季",
            avgRedness: 6.0,
            avgSensitivity: 7.0,
            sampleCount: 10,
            confidence: ConfidenceScore(value: 0.8, sampleCount: 10, method: "seasonal")
        )

        XCTAssertFalse(spring.recommendation.isEmpty)
        XCTAssertTrue(spring.recommendation.contains("春季"))
    }

    // MARK: - ProductEffectInsight Tests

    func testProductEffectInsight_effectLevel_highlyEffective() {
        let insight = ProductEffectInsight(
            productId: "1",
            productName: "Amazing Product",
            effectivenessScore: 0.7,
            confidence: ConfidenceScore(value: 0.8, sampleCount: 15, method: "analysis"),
            contributingFactors: ["高保湿"],
            usageCount: 20,
            avgDayInterval: 1.5
        )

        XCTAssertEqual(insight.effectLevel, .highlyEffective)
    }

    func testProductEffectInsight_effectLevel_effective() {
        let insight = ProductEffectInsight(
            productId: "2",
            productName: "Good Product",
            effectivenessScore: 0.3,
            confidence: ConfidenceScore(value: 0.7, sampleCount: 10, method: "analysis"),
            contributingFactors: [],
            usageCount: 15,
            avgDayInterval: 2.0
        )

        XCTAssertEqual(insight.effectLevel, .effective)
    }

    func testProductEffectInsight_effectLevel_neutral() {
        let insight = ProductEffectInsight(
            productId: "3",
            productName: "OK Product",
            effectivenessScore: 0.0,
            confidence: ConfidenceScore(value: 0.6, sampleCount: 8, method: "analysis"),
            contributingFactors: [],
            usageCount: 10,
            avgDayInterval: 3.0
        )

        XCTAssertEqual(insight.effectLevel, .neutral)
    }

    func testProductEffectInsight_effectLevel_ineffective() {
        let insight = ProductEffectInsight(
            productId: "4",
            productName: "Bad Product",
            effectivenessScore: -0.3,
            confidence: ConfidenceScore(value: 0.5, sampleCount: 5, method: "analysis"),
            contributingFactors: [],
            usageCount: 5,
            avgDayInterval: 5.0
        )

        XCTAssertEqual(insight.effectLevel, .ineffective)
    }

    func testProductEffectInsight_effectLevel_harmful() {
        let insight = ProductEffectInsight(
            productId: "5",
            productName: "Harmful Product",
            effectivenessScore: -0.7,
            confidence: ConfidenceScore(value: 0.5, sampleCount: 5, method: "analysis"),
            contributingFactors: [],
            usageCount: 5,
            avgDayInterval: 5.0
        )

        XCTAssertEqual(insight.effectLevel, .harmful)
    }

    // MARK: - StatisticalMetrics Tests

    func testStatisticalMetrics_coefficientOfVariation() {
        let metrics = StatisticalMetrics(
            mean: 100.0,
            standardDeviation: 15.0,
            median: 100.0,
            min: 70.0,
            max: 130.0
        )

        XCTAssertEqual(metrics.coefficientOfVariation, 0.15, accuracy: 0.001)
    }

    func testStatisticalMetrics_stability_veryStable() {
        let metrics = StatisticalMetrics(
            mean: 100.0,
            standardDeviation: 5.0,
            median: 100.0,
            min: 90.0,
            max: 110.0
        )

        XCTAssertEqual(metrics.stability, "非常稳定")
    }

    func testStatisticalMetrics_stability_stable() {
        let metrics = StatisticalMetrics(
            mean: 100.0,
            standardDeviation: 15.0,
            median: 100.0,
            min: 70.0,
            max: 130.0
        )

        XCTAssertEqual(metrics.stability, "稳定")
    }

    func testStatisticalMetrics_stability_unstable() {
        let metrics = StatisticalMetrics(
            mean: 100.0,
            standardDeviation: 35.0,
            median: 100.0,
            min: 30.0,
            max: 170.0
        )

        XCTAssertEqual(metrics.stability, "波动较大")
    }
}

// MARK: - IngredientExposureRecord Tests

final class IngredientExposureRecordTests: XCTestCase {

    func testFeelingType_rawValues() {
        XCTAssertEqual(FeelingType.better.rawValue, "变好")
        XCTAssertEqual(FeelingType.same.rawValue, "相同")
        XCTAssertEqual(FeelingType.worse.rawValue, "变差")
    }

    func testEffectivenessRating_rawValues() {
        XCTAssertNotNil(EffectivenessRating.positive)
        XCTAssertNotNil(EffectivenessRating.neutral)
        XCTAssertNotNil(EffectivenessRating.negative)
        XCTAssertNotNil(EffectivenessRating.insufficient)
    }

    func testIngredientEffectStats_avgEffectiveness() {
        let stats = IngredientEffectStats(
            ingredientName: "Niacinamide",
            totalUses: 10,
            betterCount: 7,
            sameCount: 2,
            worseCount: 1,
            lastUsedAt: Date()
        )

        // (7*1 + 2*0 + 1*-1) / 10 = 0.6
        XCTAssertEqual(stats.avgEffectiveness, 0.6, accuracy: 0.001)
    }

    func testIngredientEffectStats_avgEffectiveness_noUses() {
        let stats = IngredientEffectStats(
            ingredientName: "Test",
            totalUses: 0,
            betterCount: 0,
            sameCount: 0,
            worseCount: 0,
            lastUsedAt: Date()
        )

        XCTAssertEqual(stats.avgEffectiveness, 0.0)
    }

    func testIngredientEffectStats_effectivenessRating_positive() {
        let stats = IngredientEffectStats(
            ingredientName: "Good",
            totalUses: 10,
            betterCount: 8,
            sameCount: 1,
            worseCount: 1,
            lastUsedAt: Date()
        )

        XCTAssertEqual(stats.effectivenessRating, .positive)
    }

    func testIngredientEffectStats_effectivenessRating_negative() {
        let stats = IngredientEffectStats(
            ingredientName: "Bad",
            totalUses: 10,
            betterCount: 1,
            sameCount: 1,
            worseCount: 8,
            lastUsedAt: Date()
        )

        XCTAssertEqual(stats.effectivenessRating, .negative)
    }

    func testIngredientEffectStats_effectivenessRating_insufficient() {
        // Implementation returns .insufficient only when totalUses < 2
        let stats = IngredientEffectStats(
            ingredientName: "New",
            totalUses: 1,
            betterCount: 1,
            sameCount: 0,
            worseCount: 0,
            lastUsedAt: Date()
        )

        XCTAssertEqual(stats.effectivenessRating, .insufficient)
    }

    func testIngredientEffectStats_confidenceLevel() {
        // Implementation: < 2 = low, < 5 = medium, >= 5 = high
        let highConfidence = IngredientEffectStats(
            ingredientName: "Test",
            totalUses: 5,  // >= 5 = high
            betterCount: 3,
            sameCount: 1,
            worseCount: 1,
            lastUsedAt: Date()
        )
        XCTAssertEqual(highConfidence.confidenceLevel, .high)

        let mediumConfidence = IngredientEffectStats(
            ingredientName: "Test",
            totalUses: 3,  // >= 2 and < 5 = medium
            betterCount: 2,
            sameCount: 1,
            worseCount: 0,
            lastUsedAt: Date()
        )
        XCTAssertEqual(mediumConfidence.confidenceLevel, .medium)

        let lowConfidence = IngredientEffectStats(
            ingredientName: "Test",
            totalUses: 1,  // < 2 = low
            betterCount: 1,
            sameCount: 0,
            worseCount: 0,
            lastUsedAt: Date()
        )
        XCTAssertEqual(lowConfidence.confidenceLevel, .low)
    }
}
