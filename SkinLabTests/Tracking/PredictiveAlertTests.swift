// SkinLabTests/Tracking/PredictiveAlertTests.swift
import XCTest

@testable import SkinLab

final class PredictiveAlertTests: XCTestCase {

    // MARK: - AlertSeverity Tests

    func testAlertSeverity_rawValues() {
        XCTAssertEqual(AlertSeverity.low.rawValue, "提醒")
        XCTAssertEqual(AlertSeverity.medium.rawValue, "注意")
        XCTAssertEqual(AlertSeverity.high.rawValue, "警告")
    }

    func testAlertSeverity_icon() {
        XCTAssertEqual(AlertSeverity.low.icon, "info.circle.fill")
        XCTAssertEqual(AlertSeverity.medium.icon, "exclamationmark.triangle.fill")
        XCTAssertEqual(AlertSeverity.high.icon, "exclamationmark.octagon.fill")
    }

    func testAlertSeverity_colorName() {
        XCTAssertEqual(AlertSeverity.low.colorName, "blue")
        XCTAssertEqual(AlertSeverity.medium.colorName, "orange")
        XCTAssertEqual(AlertSeverity.high.colorName, "red")
    }

    // MARK: - PredictiveAlert Computed Properties Tests

    func testPredictiveAlert_daysFromNow_future() {
        // Use start of day to ensure consistent day counting
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let futureDate = calendar.date(byAdding: .day, value: 5, to: today)!
        let alert = createTestAlert(predictedDate: futureDate)

        // daysFromNow should be around 5 (may vary by 1 due to timing)
        XCTAssertTrue(alert.daysFromNow >= 4 && alert.daysFromNow <= 5)
    }

    func testPredictiveAlert_daysFromNow_past() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let pastDate = calendar.date(byAdding: .day, value: -3, to: today)!
        let alert = createTestAlert(predictedDate: pastDate)

        // daysFromNow should be around -3 (may vary by 1 due to timing)
        XCTAssertTrue(alert.daysFromNow >= -4 && alert.daysFromNow <= -3)
    }

    func testPredictiveAlert_daysFromNow_today() {
        let alert = createTestAlert(predictedDate: Date())

        XCTAssertEqual(alert.daysFromNow, 0)
    }

    func testPredictiveAlert_label() {
        let alert = PredictiveAlert(
            metric: "痘痘",
            severity: .high,
            message: "痘痘问题可能显著加重",
            actionSuggestion: "建议立即加强清洁",
            predictedDate: Date(),
            confidence: createTestConfidence()
        )

        XCTAssertEqual(alert.label, "[警告] 痘痘: 痘痘问题可能显著加重")
    }

    func testPredictiveAlert_label_lowSeverity() {
        let alert = PredictiveAlert(
            metric: "泛红",
            severity: .low,
            message: "泛红状况需要关注",
            actionSuggestion: "注意皮肤保湿",
            predictedDate: Date(),
            confidence: createTestConfidence()
        )

        XCTAssertEqual(alert.label, "[提醒] 泛红: 泛红状况需要关注")
    }

    func testPredictiveAlert_label_mediumSeverity() {
        let alert = PredictiveAlert(
            metric: "综合评分",
            severity: .medium,
            message: "皮肤状态呈下降趋势",
            actionSuggestion: "回顾近期护肤习惯",
            predictedDate: Date(),
            confidence: createTestConfidence()
        )

        XCTAssertEqual(alert.label, "[注意] 综合评分: 皮肤状态呈下降趋势")
    }

    func testPredictiveAlert_predictedDateText_today() {
        let alert = createTestAlert(predictedDate: Date())

        XCTAssertEqual(alert.predictedDateText, "今天")
    }

    func testPredictiveAlert_predictedDateText_tomorrow() {
        // Create a date that is definitely 1 calendar day from now
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        // Add 12 hours to be in the middle of the day
        let tomorrowNoon = calendar.date(byAdding: .hour, value: 12, to: tomorrow)!
        let alert = createTestAlert(predictedDate: tomorrowNoon)

        // The result depends on when the test runs, accept either
        XCTAssertTrue(alert.predictedDateText == "明天" || alert.predictedDateText == "今天")
    }

    func testPredictiveAlert_predictedDateText_future() {
        let calendar = Calendar.current
        let futureStart = calendar.date(byAdding: .day, value: 5, to: calendar.startOfDay(for: Date()))!
        let futureNoon = calendar.date(byAdding: .hour, value: 12, to: futureStart)!
        let alert = createTestAlert(predictedDate: futureNoon)

        // Allow for day boundary timing (4 or 5 days)
        XCTAssertTrue(alert.predictedDateText == "5天后" || alert.predictedDateText == "4天后")
    }

    func testPredictiveAlert_predictedDateText_past() {
        let past = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let alert = createTestAlert(predictedDate: past)

        XCTAssertEqual(alert.predictedDateText, "已过期")
    }

    func testPredictiveAlert_icon() {
        let lowAlert = createTestAlert(severity: .low)
        let mediumAlert = createTestAlert(severity: .medium)
        let highAlert = createTestAlert(severity: .high)

        XCTAssertEqual(lowAlert.icon, "info.circle.fill")
        XCTAssertEqual(mediumAlert.icon, "exclamationmark.triangle.fill")
        XCTAssertEqual(highAlert.icon, "exclamationmark.octagon.fill")
    }

    func testPredictiveAlert_colorName() {
        let lowAlert = createTestAlert(severity: .low)
        let mediumAlert = createTestAlert(severity: .medium)
        let highAlert = createTestAlert(severity: .high)

        XCTAssertEqual(lowAlert.colorName, "blue")
        XCTAssertEqual(mediumAlert.colorName, "orange")
        XCTAssertEqual(highAlert.colorName, "red")
    }

    // MARK: - TrendForecast.riskAlert Tests - Acne

    func testRiskAlert_acne_highRisk() {
        // High risk: predictedValue >= 7 && change >= 2
        let forecast = createAcneForecast(firstValue: 5, lastValue: 8)

        let alert = forecast.riskAlert
        XCTAssertNotNil(alert)
        XCTAssertEqual(alert?.metric, "痘痘")
        XCTAssertEqual(alert?.severity, .high)
        XCTAssertTrue(alert?.message.contains("显著加重") ?? false)
    }

    func testRiskAlert_acne_mediumRisk() {
        // Medium risk: predictedValue >= 5 && change >= 1
        let forecast = createAcneForecast(firstValue: 4, lastValue: 5.5)

        let alert = forecast.riskAlert
        XCTAssertNotNil(alert)
        XCTAssertEqual(alert?.metric, "痘痘")
        XCTAssertEqual(alert?.severity, .medium)
        XCTAssertTrue(alert?.message.contains("加重趋势") ?? false)
    }

    func testRiskAlert_acne_lowRisk() {
        // Low risk: predictedValue >= 4 && change > 0
        let forecast = createAcneForecast(firstValue: 3.5, lastValue: 4.2)

        let alert = forecast.riskAlert
        XCTAssertNotNil(alert)
        XCTAssertEqual(alert?.metric, "痘痘")
        XCTAssertEqual(alert?.severity, .low)
        XCTAssertTrue(alert?.message.contains("需要关注") ?? false)
    }

    func testRiskAlert_acne_noRisk() {
        // No risk: low values or decreasing
        let forecast = createAcneForecast(firstValue: 3, lastValue: 2)

        let alert = forecast.riskAlert
        XCTAssertNil(alert)
    }

    // MARK: - TrendForecast.riskAlert Tests - Redness

    func testRiskAlert_redness_highRisk() {
        // High risk: predictedValue >= 7 && change >= 2
        let forecast = createRednessForecast(firstValue: 5, lastValue: 7.5)

        let alert = forecast.riskAlert
        XCTAssertNotNil(alert)
        XCTAssertEqual(alert?.metric, "泛红")
        XCTAssertEqual(alert?.severity, .high)
        XCTAssertTrue(alert?.message.contains("显著加重") ?? false)
    }

    func testRiskAlert_redness_mediumRisk() {
        // Medium risk: predictedValue >= 5 && change >= 1
        let forecast = createRednessForecast(firstValue: 4, lastValue: 5.5)

        let alert = forecast.riskAlert
        XCTAssertNotNil(alert)
        XCTAssertEqual(alert?.metric, "泛红")
        XCTAssertEqual(alert?.severity, .medium)
        XCTAssertTrue(alert?.message.contains("加重趋势") ?? false)
    }

    func testRiskAlert_redness_lowRisk() {
        // Low risk: predictedValue >= 4 && change > 0
        let forecast = createRednessForecast(firstValue: 3.5, lastValue: 4.2)

        let alert = forecast.riskAlert
        XCTAssertNotNil(alert)
        XCTAssertEqual(alert?.metric, "泛红")
        XCTAssertEqual(alert?.severity, .low)
        XCTAssertTrue(alert?.message.contains("需要关注") ?? false)
    }

    func testRiskAlert_redness_noRisk() {
        // No risk: low values or decreasing
        let forecast = createRednessForecast(firstValue: 3, lastValue: 2)

        let alert = forecast.riskAlert
        XCTAssertNil(alert)
    }

    // MARK: - TrendForecast.riskAlert Tests - Overall Score

    func testRiskAlert_overallScore_highRisk() {
        // High risk: predictedValue < 40 && change <= -15
        let forecast = createOverallScoreForecast(firstValue: 55, lastValue: 35)

        let alert = forecast.riskAlert
        XCTAssertNotNil(alert)
        XCTAssertEqual(alert?.metric, "综合评分")
        XCTAssertEqual(alert?.severity, .high)
        XCTAssertTrue(alert?.message.contains("明显恶化") ?? false)
    }

    func testRiskAlert_overallScore_mediumRisk() {
        // Medium risk: predictedValue < 50 && change <= -10
        let forecast = createOverallScoreForecast(firstValue: 58, lastValue: 45)

        let alert = forecast.riskAlert
        XCTAssertNotNil(alert)
        XCTAssertEqual(alert?.metric, "综合评分")
        XCTAssertEqual(alert?.severity, .medium)
        XCTAssertTrue(alert?.message.contains("下降趋势") ?? false)
    }

    func testRiskAlert_overallScore_lowRisk() {
        // Low risk: predictedValue < 60 && change <= -5
        let forecast = createOverallScoreForecast(firstValue: 63, lastValue: 55)

        let alert = forecast.riskAlert
        XCTAssertNotNil(alert)
        XCTAssertEqual(alert?.metric, "综合评分")
        XCTAssertEqual(alert?.severity, .low)
        XCTAssertTrue(alert?.message.contains("略有下降") ?? false)
    }

    func testRiskAlert_overallScore_noRisk() {
        // No risk: high score or improving
        let forecast = createOverallScoreForecast(firstValue: 70, lastValue: 80)

        let alert = forecast.riskAlert
        XCTAssertNil(alert)
    }

    // MARK: - TrendForecast.riskAlert Tests - Sensitivity

    func testRiskAlert_sensitivity_highRisk() {
        // High risk: predictedValue >= 7 && change >= 2
        let forecast = createSensitivityForecast(firstValue: 5, lastValue: 7.5)

        let alert = forecast.riskAlert
        XCTAssertNotNil(alert)
        XCTAssertEqual(alert?.metric, "敏感度")
        XCTAssertEqual(alert?.severity, .high)
        XCTAssertTrue(alert?.message.contains("显著增加") ?? false)
    }

    func testRiskAlert_sensitivity_mediumRisk() {
        // Medium risk: predictedValue >= 5 && change >= 1
        let forecast = createSensitivityForecast(firstValue: 4, lastValue: 5.5)

        let alert = forecast.riskAlert
        XCTAssertNotNil(alert)
        XCTAssertEqual(alert?.metric, "敏感度")
        XCTAssertEqual(alert?.severity, .medium)
        XCTAssertTrue(alert?.message.contains("上升趋势") ?? false)
    }

    func testRiskAlert_sensitivity_lowRisk() {
        // Low risk: predictedValue >= 4 && change > 0
        let forecast = createSensitivityForecast(firstValue: 3.5, lastValue: 4.2)

        let alert = forecast.riskAlert
        XCTAssertNotNil(alert)
        XCTAssertEqual(alert?.metric, "敏感度")
        XCTAssertEqual(alert?.severity, .low)
        XCTAssertTrue(alert?.message.contains("需要关注") ?? false)
    }

    func testRiskAlert_sensitivity_noRisk() {
        // No risk: low values or decreasing
        let forecast = createSensitivityForecast(firstValue: 3, lastValue: 2)

        let alert = forecast.riskAlert
        XCTAssertNil(alert)
    }

    // MARK: - TrendForecast.riskAlert Tests - Unknown Metric

    func testRiskAlert_unknownMetric_returnsNil() {
        let forecast = createForecast(metric: "unknown_metric", firstValue: 5, lastValue: 8)

        let alert = forecast.riskAlert
        XCTAssertNil(alert)
    }

    // MARK: - TrendForecast.riskAlert Tests - Empty Points

    func testRiskAlert_emptyPoints_returnsNil() {
        let forecast = TrendForecast(
            metric: "痘痘",
            horizonDays: 7,
            points: [],
            confidence: createTestConfidence()
        )

        let alert = forecast.riskAlert
        XCTAssertNil(alert)
    }

    // MARK: - Helpers

    private func createTestAlert(
        severity: AlertSeverity = .medium,
        predictedDate: Date = Date()
    ) -> PredictiveAlert {
        PredictiveAlert(
            metric: "测试指标",
            severity: severity,
            message: "测试消息",
            actionSuggestion: "测试建议",
            predictedDate: predictedDate,
            confidence: createTestConfidence()
        )
    }

    private func createTestConfidence() -> ConfidenceScore {
        ConfidenceScore(value: 0.8, sampleCount: 10, method: "regression")
    }

    private func createAcneForecast(firstValue: Double, lastValue: Double) -> TrendForecast {
        createForecast(metric: "痘痘", firstValue: firstValue, lastValue: lastValue)
    }

    private func createRednessForecast(firstValue: Double, lastValue: Double) -> TrendForecast {
        createForecast(metric: "泛红", firstValue: firstValue, lastValue: lastValue)
    }

    private func createOverallScoreForecast(firstValue: Double, lastValue: Double) -> TrendForecast {
        createForecast(metric: "综合评分", firstValue: firstValue, lastValue: lastValue)
    }

    private func createSensitivityForecast(firstValue: Double, lastValue: Double) -> TrendForecast {
        createForecast(metric: "敏感度", firstValue: firstValue, lastValue: lastValue)
    }

    private func createForecast(
        metric: String,
        firstValue: Double,
        lastValue: Double
    ) -> TrendForecast {
        let today = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: today)!

        let points = [
            ForecastPoint(
                day: 0,
                date: today,
                predictedValue: firstValue,
                lowerBound: firstValue - 1,
                upperBound: firstValue + 1
            ),
            ForecastPoint(
                day: 7,
                date: futureDate,
                predictedValue: lastValue,
                lowerBound: lastValue - 1,
                upperBound: lastValue + 1
            ),
        ]

        return TrendForecast(
            metric: metric,
            horizonDays: 7,
            points: points,
            confidence: createTestConfidence()
        )
    }
}
