// SkinLabTests/Tracking/AnomalyDetectorTests.swift
import XCTest
@testable import SkinLab

final class AnomalyDetectorTests: XCTestCase {

    var detector: AnomalyDetector!

    override func setUp() {
        super.setUp()
        detector = AnomalyDetector()
    }

    override func tearDown() {
        detector = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createDates(count: Int) -> [Date] {
        let baseDate = Date()
        return (0..<count).map { baseDate.addingTimeInterval(Double($0) * 86400) }
    }

    private func createDays(count: Int) -> [Int] {
        return Array(1...count)
    }

    // MARK: - Z-Score Detection Tests

    func testDetect_zscore_noAnomalies() {
        let values = [70.0, 72.0, 71.0, 73.0, 70.0, 72.0, 71.0]
        let days = createDays(count: values.count)
        let dates = createDates(count: values.count)

        let anomalies = detector.detect(
            values: values,
            days: days,
            dates: dates,
            metric: "score",
            method: .zscore
        )

        XCTAssertTrue(anomalies.isEmpty)
    }

    func testDetect_zscore_withAnomaly() {
        let values = [70.0, 72.0, 71.0, 73.0, 95.0, 72.0, 71.0] // 95 is anomaly
        let days = createDays(count: values.count)
        let dates = createDates(count: values.count)

        let anomalies = detector.detect(
            values: values,
            days: days,
            dates: dates,
            metric: "score",
            method: .zscore,
            threshold: 2.0
        )

        XCTAssertEqual(anomalies.count, 1)
        XCTAssertEqual(anomalies.first?.day, 5)
        XCTAssertEqual(anomalies.first?.value ?? 0, 95.0, accuracy: 0.001)
        XCTAssertGreaterThan(anomalies.first?.zScore ?? 0, 0) // Positive because above mean
    }

    func testDetect_zscore_lowAnomaly() {
        let values = [70.0, 72.0, 71.0, 73.0, 30.0, 72.0, 71.0] // 30 is low anomaly
        let days = createDays(count: values.count)
        let dates = createDates(count: values.count)

        let anomalies = detector.detect(
            values: values,
            days: days,
            dates: dates,
            metric: "score",
            method: .zscore,
            threshold: 2.0
        )

        XCTAssertEqual(anomalies.count, 1)
        XCTAssertLessThan(anomalies.first?.zScore ?? 0, 0) // Negative because below mean
    }

    // MARK: - MAD Detection Tests

    func testDetect_mad_noAnomalies() {
        let values = [70.0, 72.0, 71.0, 73.0, 70.0, 72.0, 71.0]
        let days = createDays(count: values.count)
        let dates = createDates(count: values.count)

        let anomalies = detector.detect(
            values: values,
            days: days,
            dates: dates,
            metric: "score",
            method: .mad
        )

        XCTAssertTrue(anomalies.isEmpty)
    }

    func testDetect_mad_withAnomaly() {
        let values = [70.0, 72.0, 71.0, 73.0, 120.0, 72.0, 71.0]
        let days = createDays(count: values.count)
        let dates = createDates(count: values.count)

        let anomalies = detector.detect(
            values: values,
            days: days,
            dates: dates,
            metric: "score",
            method: .mad,
            threshold: 2.5
        )

        XCTAssertGreaterThanOrEqual(anomalies.count, 1)
    }

    // MARK: - IQR Detection Tests

    func testDetect_iqr_noAnomalies() {
        let values = [70.0, 72.0, 71.0, 73.0, 70.0, 72.0, 71.0, 74.0]
        let days = createDays(count: values.count)
        let dates = createDates(count: values.count)

        let anomalies = detector.detect(
            values: values,
            days: days,
            dates: dates,
            metric: "score",
            method: .iqr
        )

        XCTAssertTrue(anomalies.isEmpty)
    }

    func testDetect_iqr_withAnomaly() {
        let values = [70.0, 72.0, 71.0, 73.0, 150.0, 72.0, 71.0, 74.0]
        let days = createDays(count: values.count)
        let dates = createDates(count: values.count)

        let anomalies = detector.detect(
            values: values,
            days: days,
            dates: dates,
            metric: "score",
            method: .iqr
        )

        XCTAssertGreaterThanOrEqual(anomalies.count, 1)
    }

    // MARK: - Edge Cases

    func testDetect_insufficientData() {
        let values = [70.0, 72.0] // Only 2 values
        let days = [1, 2]
        let dates = createDates(count: 2)

        let anomalies = detector.detect(
            values: values,
            days: days,
            dates: dates,
            metric: "score"
        )

        XCTAssertTrue(anomalies.isEmpty)
    }

    func testDetect_mismatchedArrays() {
        let values = [70.0, 72.0, 71.0]
        let days = [1, 2] // Mismatched count
        let dates = createDates(count: 3)

        let anomalies = detector.detect(
            values: values,
            days: days,
            dates: dates,
            metric: "score"
        )

        XCTAssertTrue(anomalies.isEmpty)
    }

    func testDetect_allIdenticalValues() {
        let values = [70.0, 70.0, 70.0, 70.0, 70.0]
        let days = createDays(count: values.count)
        let dates = createDates(count: values.count)

        let anomalies = detector.detect(
            values: values,
            days: days,
            dates: dates,
            metric: "score"
        )

        XCTAssertTrue(anomalies.isEmpty) // No deviation = no anomalies
    }

    // MARK: - Jump Detection Tests

    func testDetectJumps_noJumps() {
        let values = [70.0, 71.0, 72.0, 73.0, 74.0]
        let days = createDays(count: values.count)
        let dates = createDates(count: values.count)

        let jumps = detector.detectJumps(
            values: values,
            days: days,
            dates: dates,
            metric: "score"
        )

        XCTAssertTrue(jumps.isEmpty)
    }

    func testDetectJumps_withJump() {
        let values = [70.0, 71.0, 72.0, 100.0, 101.0] // Jump from 72 to 100
        let days = createDays(count: values.count)
        let dates = createDates(count: values.count)

        let jumps = detector.detectJumps(
            values: values,
            days: days,
            dates: dates,
            metric: "score",
            threshold: 2.0
        )

        XCTAssertGreaterThanOrEqual(jumps.count, 1)
    }

    func testDetectJumps_insufficientData() {
        let values = [70.0, 71.0]
        let days = [1, 2]
        let dates = createDates(count: 2)

        let jumps = detector.detectJumps(
            values: values,
            days: days,
            dates: dates,
            metric: "score"
        )

        XCTAssertTrue(jumps.isEmpty)
    }

    // MARK: - Data Quality Assessment Tests

    func testAssessDataQuality_excellent() {
        // Stable values with many samples
        let values = Array(repeating: 75.0, count: 25)
        let (score, description) = detector.assessDataQuality(values: values)

        XCTAssertGreaterThanOrEqual(score, 0.8)
        XCTAssertEqual(description, "数据质量优秀")
    }

    func testAssessDataQuality_good() {
        // Relatively stable with medium sample size
        let values = [70.0, 72.0, 71.0, 73.0, 70.0, 72.0, 71.0, 73.0, 70.0, 72.0]
        let (score, _) = detector.assessDataQuality(values: values)

        XCTAssertGreaterThanOrEqual(score, 0.4)
    }

    func testAssessDataQuality_insufficient() {
        let values = [70.0, 72.0]
        let (score, description) = detector.assessDataQuality(values: values)

        XCTAssertEqual(score, 0.0)
        XCTAssertEqual(description, "样本量不足")
    }

    // MARK: - Severity Tests

    func testAnomalySeverity_values() {
        XCTAssertNotNil(AnomalyDetectionResult.Severity.mild)
        XCTAssertNotNil(AnomalyDetectionResult.Severity.moderate)
        XCTAssertNotNil(AnomalyDetectionResult.Severity.severe)
    }
}

// MARK: - AnomalyDetectionResult Tests

final class AnomalyDetectionResultTests: XCTestCase {

    func testAnomalyDetectionResult_initialization() {
        let result = AnomalyDetectionResult(
            id: UUID(),
            metric: "overallScore",
            day: 5,
            date: Date(),
            value: 95.0,
            zScore: 3.5,
            severity: .severe,
            reason: "数值异常偏高"
        )

        XCTAssertEqual(result.metric, "overallScore")
        XCTAssertEqual(result.day, 5)
        XCTAssertEqual(result.value, 95.0, accuracy: 0.001)
        XCTAssertEqual(result.zScore, 3.5, accuracy: 0.001)
        XCTAssertEqual(result.severity, .severe)
    }

    func testAnomalyDetectionResult_severityCases() {
        XCTAssertNotNil(AnomalyDetectionResult.Severity.mild)
        XCTAssertNotNil(AnomalyDetectionResult.Severity.moderate)
        XCTAssertNotNil(AnomalyDetectionResult.Severity.severe)
    }
}
