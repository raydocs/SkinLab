// SkinLabTests/Tracking/TimeSeriesAnalyzerTests.swift
import XCTest
@testable import SkinLab

final class TimeSeriesAnalyzerTests: XCTestCase {

    var analyzer: TimeSeriesAnalyzer!

    override func setUp() {
        super.setUp()
        analyzer = TimeSeriesAnalyzer()
    }

    override func tearDown() {
        analyzer = nil
        super.tearDown()
    }

    // MARK: - Moving Average Tests

    func testMovingAverage_basicCase() {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0]
        let result = analyzer.movingAverage(values, window: 3)

        XCTAssertEqual(result.count, 5)
        XCTAssertEqual(result[0], 1.0, accuracy: 0.001) // Only one value
        XCTAssertEqual(result[1], 1.5, accuracy: 0.001) // (1+2)/2
        XCTAssertEqual(result[2], 2.0, accuracy: 0.001) // (1+2+3)/3
        XCTAssertEqual(result[3], 3.0, accuracy: 0.001) // (2+3+4)/3
        XCTAssertEqual(result[4], 4.0, accuracy: 0.001) // (3+4+5)/3
    }

    func testMovingAverage_windowLargerThanData() {
        let values = [1.0, 2.0]
        let result = analyzer.movingAverage(values, window: 5)

        XCTAssertEqual(result, values)
    }

    func testMovingAverage_emptyArray() {
        let values: [Double] = []
        let result = analyzer.movingAverage(values, window: 3)

        XCTAssertTrue(result.isEmpty)
    }

    func testMovingAverage_windowOfOne() {
        let values = [1.0, 2.0, 3.0]
        let result = analyzer.movingAverage(values, window: 1)

        XCTAssertEqual(result, values)
    }

    // MARK: - Exponential Moving Average Tests

    func testExponentialMovingAverage_basicCase() {
        let values = [10.0, 20.0, 30.0, 40.0]
        let result = analyzer.exponentialMovingAverage(values, alpha: 0.5)

        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[0], 10.0, accuracy: 0.001)
        XCTAssertEqual(result[1], 15.0, accuracy: 0.001) // 0.5*20 + 0.5*10
        XCTAssertEqual(result[2], 22.5, accuracy: 0.001) // 0.5*30 + 0.5*15
        XCTAssertEqual(result[3], 31.25, accuracy: 0.001) // 0.5*40 + 0.5*22.5
    }

    func testExponentialMovingAverage_alphaZero() {
        let values = [10.0, 20.0, 30.0]
        let result = analyzer.exponentialMovingAverage(values, alpha: 0.0)

        // All values should equal the first value
        XCTAssertEqual(result[0], 10.0, accuracy: 0.001)
        XCTAssertEqual(result[1], 10.0, accuracy: 0.001)
        XCTAssertEqual(result[2], 10.0, accuracy: 0.001)
    }

    func testExponentialMovingAverage_alphaOne() {
        let values = [10.0, 20.0, 30.0]
        let result = analyzer.exponentialMovingAverage(values, alpha: 1.0)

        // Should return original values
        XCTAssertEqual(result, values)
    }

    func testExponentialMovingAverage_emptyArray() {
        let values: [Double] = []
        let result = analyzer.exponentialMovingAverage(values)

        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Slope Tests

    func testSlope_increasingValues() {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0]
        let slope = analyzer.slope(values)

        XCTAssertEqual(slope, 1.0, accuracy: 0.001)
    }

    func testSlope_decreasingValues() {
        let values = [5.0, 4.0, 3.0, 2.0, 1.0]
        let slope = analyzer.slope(values)

        XCTAssertEqual(slope, -1.0, accuracy: 0.001)
    }

    func testSlope_flatValues() {
        let values = [5.0, 5.0, 5.0, 5.0]
        let slope = analyzer.slope(values)

        XCTAssertEqual(slope, 0.0, accuracy: 0.001)
    }

    func testSlope_singleValue() {
        let values = [5.0]
        let slope = analyzer.slope(values)

        XCTAssertEqual(slope, 0.0)
    }

    func testSlope_emptyArray() {
        let values: [Double] = []
        let slope = analyzer.slope(values)

        XCTAssertEqual(slope, 0.0)
    }

    // MARK: - R-Squared Tests

    func testRSquared_perfectFit() {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0] // Perfect linear relationship
        let rSquared = analyzer.rSquared(values)

        XCTAssertEqual(rSquared, 1.0, accuracy: 0.001)
    }

    func testRSquared_noFit() {
        let values = [1.0, 100.0, 2.0, 99.0, 3.0] // Very scattered
        let rSquared = analyzer.rSquared(values)

        XCTAssertLessThan(rSquared, 0.5)
    }

    func testRSquared_flatValues() {
        let values = [5.0, 5.0, 5.0, 5.0]
        let rSquared = analyzer.rSquared(values)

        XCTAssertEqual(rSquared, 0.0, accuracy: 0.001)
    }

    // MARK: - Volatility Tests

    func testVolatility_stableValues() {
        let values = [100.0, 101.0, 99.0, 100.0, 100.5]
        let volatility = analyzer.volatility(values)

        XCTAssertLessThan(volatility, 0.1)
    }

    func testVolatility_unstableValues() {
        let values = [10.0, 50.0, 5.0, 80.0, 20.0]
        let volatility = analyzer.volatility(values)

        XCTAssertGreaterThan(volatility, 0.5)
    }

    func testVolatility_singleValue() {
        let values = [100.0]
        let volatility = analyzer.volatility(values)

        XCTAssertEqual(volatility, 0.0)
    }

    // MARK: - Max Drawdown Tests

    func testMaxDrawdown_noDrawdown() {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0] // Always increasing
        let drawdown = analyzer.maxDrawdown(values)

        XCTAssertEqual(drawdown, 0.0, accuracy: 0.001)
    }

    func testMaxDrawdown_50percentDrawdown() {
        let values = [100.0, 80.0, 50.0, 70.0]
        let drawdown = analyzer.maxDrawdown(values)

        XCTAssertEqual(drawdown, 50.0, accuracy: 0.001) // 100 -> 50 = 50%
    }

    func testMaxDrawdown_multipleDrawdowns() {
        let values = [100.0, 90.0, 95.0, 60.0, 80.0]
        let drawdown = analyzer.maxDrawdown(values)

        // Peak at 100, trough at 60 = 40% drawdown
        // Or peak at 95, trough at 60 = 36.8% drawdown
        // Max is from 100 to 60 = 40%
        XCTAssertEqual(drawdown, 40.0, accuracy: 0.001)
    }

    // MARK: - Statistical Functions Tests

    func testMean_basicCase() {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0]
        let mean = analyzer.mean(values)

        XCTAssertEqual(mean, 3.0, accuracy: 0.001)
    }

    func testMean_emptyArray() {
        let values: [Double] = []
        let mean = analyzer.mean(values)

        XCTAssertEqual(mean, 0.0)
    }

    func testMedian_oddCount() {
        let values = [1.0, 3.0, 2.0, 5.0, 4.0]
        let median = analyzer.median(values)

        XCTAssertEqual(median, 3.0, accuracy: 0.001)
    }

    func testMedian_evenCount() {
        let values = [1.0, 2.0, 3.0, 4.0]
        let median = analyzer.median(values)

        XCTAssertEqual(median, 2.5, accuracy: 0.001)
    }

    func testMedian_emptyArray() {
        let values: [Double] = []
        let median = analyzer.median(values)

        XCTAssertEqual(median, 0.0)
    }

    func testStandardDeviation_basicCase() {
        let values = [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0]
        let std = analyzer.standardDeviation(values)

        // Sample std dev (n-1): mean=5, sumSqDiff=32, variance=32/7≈4.571, std≈2.138
        XCTAssertEqual(std, 2.138, accuracy: 0.01)
    }

    func testStandardDeviation_identicalValues() {
        let values = [5.0, 5.0, 5.0, 5.0]
        let std = analyzer.standardDeviation(values)

        XCTAssertEqual(std, 0.0, accuracy: 0.001)
    }

    func testMedianAbsoluteDeviation_basicCase() {
        let values = [1.0, 1.0, 2.0, 2.0, 4.0, 6.0, 9.0]
        let mad = analyzer.medianAbsoluteDeviation(values)

        // Median = 2.0
        // Deviations: |1-2|=1, |1-2|=1, |2-2|=0, |2-2|=0, |4-2|=2, |6-2|=4, |9-2|=7
        // Sorted deviations: 0, 0, 1, 1, 2, 4, 7
        // MAD = median of deviations = 1
        XCTAssertEqual(mad, 1.0, accuracy: 0.001)
    }

    // MARK: - Calculate Statistics Tests

    func testCalculateStatistics_basicCase() {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0]
        let stats = analyzer.calculateStatistics(values)

        XCTAssertEqual(stats.mean, 3.0, accuracy: 0.001)
        XCTAssertEqual(stats.median, 3.0, accuracy: 0.001)
        XCTAssertEqual(stats.min, 1.0, accuracy: 0.001)
        XCTAssertEqual(stats.max, 5.0, accuracy: 0.001)
        XCTAssertGreaterThan(stats.standardDeviation, 0)
    }

    func testCalculateStatistics_emptyArray() {
        let values: [Double] = []
        let stats = analyzer.calculateStatistics(values)

        XCTAssertEqual(stats.mean, 0.0)
        XCTAssertEqual(stats.standardDeviation, 0.0)
        XCTAssertEqual(stats.median, 0.0)
        XCTAssertEqual(stats.min, 0.0)
        XCTAssertEqual(stats.max, 0.0)
    }

    // MARK: - Interval Consistency Tests

    func testAnalyzeIntervalConsistency_regularIntervals() {
        let dates = [
            Date(),
            Date().addingTimeInterval(86400), // +1 day
            Date().addingTimeInterval(172800), // +2 days
            Date().addingTimeInterval(259200)  // +3 days
        ]
        let (avgInterval, stdInterval) = analyzer.analyzeIntervalConsistency(dates)

        XCTAssertEqual(avgInterval, 1.0, accuracy: 0.1) // 1 day average
        XCTAssertEqual(stdInterval, 0.0, accuracy: 0.1) // No variance
    }

    func testAnalyzeIntervalConsistency_irregularIntervals() {
        let dates = [
            Date(),
            Date().addingTimeInterval(86400),   // +1 day
            Date().addingTimeInterval(259200),  // +3 days (2 day gap)
            Date().addingTimeInterval(345600)   // +4 days (1 day gap)
        ]
        let (avgInterval, stdInterval) = analyzer.analyzeIntervalConsistency(dates)

        XCTAssertGreaterThan(avgInterval, 1.0)
        XCTAssertGreaterThan(stdInterval, 0.0)
    }

    func testAnalyzeIntervalConsistency_singleDate() {
        let dates = [Date()]
        let (avgInterval, stdInterval) = analyzer.analyzeIntervalConsistency(dates)

        XCTAssertEqual(avgInterval, 0.0)
        XCTAssertEqual(stdInterval, 0.0)
    }
}

// MARK: - StatisticalMetrics Tests

final class StatisticalMetricsTests: XCTestCase {

    func testCoefficientOfVariation() {
        let metrics = StatisticalMetrics(
            mean: 100.0,
            standardDeviation: 15.0,
            median: 100.0,
            min: 70.0,
            max: 130.0
        )

        XCTAssertEqual(metrics.coefficientOfVariation, 0.15, accuracy: 0.001)
    }

    func testCoefficientOfVariation_zeroMean() {
        let metrics = StatisticalMetrics(
            mean: 0.0,
            standardDeviation: 15.0,
            median: 0.0,
            min: -15.0,
            max: 15.0
        )

        XCTAssertEqual(metrics.coefficientOfVariation, 0.0)
    }

    func testStability_stable() {
        let metrics = StatisticalMetrics(
            mean: 100.0,
            standardDeviation: 5.0,
            median: 100.0,
            min: 90.0,
            max: 110.0
        )

        // CV = 5/100 = 0.05, < 0.1 → "非常稳定"
        XCTAssertEqual(metrics.stability, "非常稳定")
    }

    func testStability_moderatelyStable() {
        let metrics = StatisticalMetrics(
            mean: 100.0,
            standardDeviation: 15.0,
            median: 100.0,
            min: 70.0,
            max: 130.0
        )

        // CV = 15/100 = 0.15, < 0.2 → "稳定"
        XCTAssertEqual(metrics.stability, "稳定")
    }

    func testStability_unstable() {
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
