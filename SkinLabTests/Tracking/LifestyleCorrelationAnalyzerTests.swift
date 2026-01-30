// SkinLabTests/Tracking/LifestyleCorrelationAnalyzerTests.swift
@testable import SkinLab
import XCTest

final class LifestyleCorrelationAnalyzerTests: XCTestCase {
    var analyzer: LifestyleCorrelationAnalyzer!

    override func setUp() {
        super.setUp()
        analyzer = LifestyleCorrelationAnalyzer()
    }

    override func tearDown() {
        analyzer = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Create a CheckIn with lifestyle factors
    private func makeCheckIn(
        id: UUID = UUID(),
        sessionId: UUID = UUID(),
        day: Int,
        sleepHours: Double? = nil,
        stressLevel: Int? = nil,
        waterIntakeLevel: Int? = nil,
        alcoholConsumed: Bool? = nil,
        exerciseMinutes: Int? = nil,
        sunExposureLevel: Int? = nil
    ) -> CheckIn {
        let lifestyle = LifestyleFactors(
            sleepHours: sleepHours,
            stressLevel: stressLevel,
            waterIntakeLevel: waterIntakeLevel,
            alcoholConsumed: alcoholConsumed,
            exerciseMinutes: exerciseMinutes,
            sunExposureLevel: sunExposureLevel,
            dietNotes: nil,
            cyclePhase: nil
        )
        return CheckIn(
            id: id,
            sessionId: sessionId,
            day: day,
            captureDate: Date(),
            photoPath: nil,
            analysisId: nil,
            usedProducts: [],
            notes: nil,
            feeling: nil,
            photoStandardization: nil,
            lifestyle: lifestyle,
            reliability: nil
        )
    }

    /// Create a ScorePoint linked to a checkIn
    private func makeScorePoint(
        checkInId: UUID,
        day: Int,
        overallScore: Int
    ) -> ScorePoint {
        ScorePoint(
            id: UUID(),
            day: day,
            date: Date(),
            overallScore: overallScore,
            skinAge: 25,
            issueScores: nil,
            regionScores: nil,
            checkInId: checkInId
        )
    }

    /// Create ReliabilityMetadata with given score
    private func makeReliability(
        score: Double,
        level: ReliabilityMetadata.ReliabilityLevel = .medium
    ) -> ReliabilityMetadata {
        ReliabilityMetadata(
            score: score,
            level: level,
            reasons: [],
            computedAt: Date()
        )
    }

    // MARK: - Test Cases

    /// Test 1: Valid data with 3+ check-ins returns correct correlation
    /// Monotonic relationship: sleep hours [6, 7, 8, 9] -> deltas [+1, +2, +3]
    /// Expected: positive correlation close to +1.0
    func testAnalyzeWithValidData() {
        // Given: 4 check-ins with monotonic sleep hours
        let sessionId = UUID()
        let checkIn0Id = UUID()
        let checkIn1Id = UUID()
        let checkIn2Id = UUID()
        let checkIn3Id = UUID()

        let checkIns = [
            makeCheckIn(id: checkIn0Id, sessionId: sessionId, day: 0, sleepHours: 6.0),
            makeCheckIn(id: checkIn1Id, sessionId: sessionId, day: 7, sleepHours: 7.0),
            makeCheckIn(id: checkIn2Id, sessionId: sessionId, day: 14, sleepHours: 8.0),
            makeCheckIn(id: checkIn3Id, sessionId: sessionId, day: 21, sleepHours: 9.0)
        ]

        // Timeline scores: 60 -> 61 -> 63 -> 66
        // Deltas: +1, +2, +3 (monotonic increasing)
        let timeline = [
            makeScorePoint(checkInId: checkIn0Id, day: 0, overallScore: 60),
            makeScorePoint(checkInId: checkIn1Id, day: 7, overallScore: 61),
            makeScorePoint(checkInId: checkIn2Id, day: 14, overallScore: 63),
            makeScorePoint(checkInId: checkIn3Id, day: 21, overallScore: 66)
        ]

        // All points have reliability >= 0.5
        let reliability: [UUID: ReliabilityMetadata] = [
            checkIn0Id: makeReliability(score: 0.8, level: .high),
            checkIn1Id: makeReliability(score: 0.7, level: .medium),
            checkIn2Id: makeReliability(score: 0.6, level: .medium),
            checkIn3Id: makeReliability(score: 0.9, level: .high)
        ]

        // When
        let insights = analyzer.analyze(
            checkIns: checkIns,
            timeline: timeline,
            reliability: reliability
        )

        // Then: Should have sleep hours correlation
        let sleepInsight = insights.first { $0.factor == .sleepHours }
        XCTAssertNotNil(sleepInsight, "Should have sleep hours insight")

        if let insight = sleepInsight {
            // Check correlation is positive and significant (>= 0.3)
            XCTAssertGreaterThanOrEqual(abs(insight.correlation), 0.3, "Correlation should be significant")
            XCTAssertGreaterThan(insight.correlation, 0, "Correlation should be positive")
            XCTAssertEqual(insight.sampleCount, 3, "Should have 3 pairs (4 check-ins - 1)")
        }
    }

    /// Test 2: Empty timeline returns empty results
    func testAnalyzeWithEmptyTimeline() {
        // Given: Empty data
        let checkIns: [CheckIn] = []
        let timeline: [ScorePoint] = []
        let reliability: [UUID: ReliabilityMetadata] = [:]

        // When
        let insights = analyzer.analyze(
            checkIns: checkIns,
            timeline: timeline,
            reliability: reliability
        )

        // Then
        XCTAssertTrue(insights.isEmpty, "Empty timeline should return empty insights")
    }

    /// Test 3: Only 2 check-ins returns empty results (need 3+ for 2 pairs)
    func testAnalyzeWithTwoCheckIns() {
        // Given: Only 2 check-ins (produces only 1 pair, need 2+ for correlation)
        let sessionId = UUID()
        let checkIn0Id = UUID()
        let checkIn1Id = UUID()

        let checkIns = [
            makeCheckIn(id: checkIn0Id, sessionId: sessionId, day: 0, sleepHours: 7.0),
            makeCheckIn(id: checkIn1Id, sessionId: sessionId, day: 7, sleepHours: 8.0)
        ]

        let timeline = [
            makeScorePoint(checkInId: checkIn0Id, day: 0, overallScore: 60),
            makeScorePoint(checkInId: checkIn1Id, day: 7, overallScore: 65)
        ]

        let reliability: [UUID: ReliabilityMetadata] = [
            checkIn0Id: makeReliability(score: 0.8),
            checkIn1Id: makeReliability(score: 0.8)
        ]

        // When
        let insights = analyzer.analyze(
            checkIns: checkIns,
            timeline: timeline,
            reliability: reliability
        )

        // Then: Should return empty (need at least 2 factor-delta pairs for correlation)
        XCTAssertTrue(insights.isEmpty, "2 check-ins should return empty insights (only 1 pair)")
    }

    /// Test 4: Low reliability pairs (<0.5) are filtered out
    func testLowReliabilityFiltered() {
        // Given: 4 check-ins, but first 2 have low reliability
        let sessionId = UUID()
        let checkIn0Id = UUID()
        let checkIn1Id = UUID()
        let checkIn2Id = UUID()
        let checkIn3Id = UUID()

        let checkIns = [
            makeCheckIn(id: checkIn0Id, sessionId: sessionId, day: 0, sleepHours: 6.0),
            makeCheckIn(id: checkIn1Id, sessionId: sessionId, day: 7, sleepHours: 7.0),
            makeCheckIn(id: checkIn2Id, sessionId: sessionId, day: 14, sleepHours: 8.0),
            makeCheckIn(id: checkIn3Id, sessionId: sessionId, day: 21, sleepHours: 9.0)
        ]

        let timeline = [
            makeScorePoint(checkInId: checkIn0Id, day: 0, overallScore: 60),
            makeScorePoint(checkInId: checkIn1Id, day: 7, overallScore: 65),
            makeScorePoint(checkInId: checkIn2Id, day: 14, overallScore: 70),
            makeScorePoint(checkInId: checkIn3Id, day: 21, overallScore: 75)
        ]

        // First 2 check-ins have low reliability (<0.5), should be filtered
        let reliability: [UUID: ReliabilityMetadata] = [
            checkIn0Id: makeReliability(score: 0.3, level: .low), // < 0.5, filtered
            checkIn1Id: makeReliability(score: 0.4, level: .low), // < 0.5, filtered
            checkIn2Id: makeReliability(score: 0.8, level: .high),
            checkIn3Id: makeReliability(score: 0.9, level: .high)
        ]

        // When
        let insights = analyzer.analyze(
            checkIns: checkIns,
            timeline: timeline,
            reliability: reliability
        )

        // Then: Only 1 valid pair (checkIn2 -> checkIn3), not enough for correlation
        // With only 1 valid pair, correlation cannot be computed (need >= 2 pairs)
        // so insights should be empty for sleep factor
        let sleepInsight = insights.first { $0.factor == .sleepHours }
        XCTAssertNil(sleepInsight, "Should have no sleep insight with only 1 valid pair after filtering")
    }

    /// Test 5: Alcohol factor produces a deterministic insight
    /// Uses 5 check-ins to create 4 pairs with strong negative correlation
    func testAlcoholFactorProducesInsight() {
        // Given: 5 check-ins with alcohol data creating strong negative correlation
        let sessionId = UUID()
        let checkIn0Id = UUID()
        let checkIn1Id = UUID()
        let checkIn2Id = UUID()
        let checkIn3Id = UUID()
        let checkIn4Id = UUID()

        // Alcohol pattern from current check-in perspective:
        // Pairs: (0->1), (1->2), (2->3), (3->4)
        // Factor values (alcohol of current): [0, 1, 0, 1]
        // We design deltas to correlate negatively with alcohol
        let checkIns = [
            makeCheckIn(id: checkIn0Id, sessionId: sessionId, day: 0, alcoholConsumed: false), // factor=0
            makeCheckIn(id: checkIn1Id, sessionId: sessionId, day: 7, alcoholConsumed: true), // factor=1
            makeCheckIn(id: checkIn2Id, sessionId: sessionId, day: 14, alcoholConsumed: false), // factor=0
            makeCheckIn(id: checkIn3Id, sessionId: sessionId, day: 21, alcoholConsumed: true), // factor=1
            makeCheckIn(id: checkIn4Id, sessionId: sessionId, day: 28, alcoholConsumed: false) // not used in pairs
        ]

        // Scores: 70 -> 75 -> 68 -> 73 -> 66
        // Deltas: +5, -7, +5, -7
        // Factor values: [0, 1, 0, 1]
        // When alcohol=0 (false), delta is positive (+5)
        // When alcohol=1 (true), delta is negative (-7)
        // This creates a strong negative Spearman correlation (close to -1)
        let timeline = [
            makeScorePoint(checkInId: checkIn0Id, day: 0, overallScore: 70),
            makeScorePoint(checkInId: checkIn1Id, day: 7, overallScore: 75),
            makeScorePoint(checkInId: checkIn2Id, day: 14, overallScore: 68),
            makeScorePoint(checkInId: checkIn3Id, day: 21, overallScore: 73),
            makeScorePoint(checkInId: checkIn4Id, day: 28, overallScore: 66)
        ]

        let reliability: [UUID: ReliabilityMetadata] = [
            checkIn0Id: makeReliability(score: 0.8),
            checkIn1Id: makeReliability(score: 0.7),
            checkIn2Id: makeReliability(score: 0.8),
            checkIn3Id: makeReliability(score: 0.7),
            checkIn4Id: makeReliability(score: 0.8)
        ]

        // When
        let insights = analyzer.analyze(
            checkIns: checkIns,
            timeline: timeline,
            reliability: reliability
        )

        // Then: Alcohol insight MUST exist with significant negative correlation
        let alcoholInsight = insights.first { $0.factor == .alcohol }
        XCTAssertNotNil(alcoholInsight, "Alcohol insight must exist with this deterministic fixture")

        if let insight = alcoholInsight {
            XCTAssertEqual(insight.factor, .alcohol, "Factor should be alcohol")
            XCTAssertLessThan(insight.correlation, 0, "Alcohol correlation should be negative")
            XCTAssertGreaterThanOrEqual(abs(insight.correlation), 0.3, "Correlation should be significant")
            XCTAssertEqual(insight.sampleCount, 4, "Should have 4 pairs from 5 check-ins")
        }
    }

    /// Test 6: Delta calculation uses checkInId join (not day)
    /// This test proves the implementation uses checkInId for score lookup, NOT ScorePoint.day
    /// by intentionally making ScorePoint.day values DIFFERENT from CheckIn.day
    func testDeltaCalculationUsesCheckInIdNotDay() {
        // Given: Check-ins with specific IDs
        let sessionId = UUID()
        let checkIn0Id = UUID()
        let checkIn1Id = UUID()
        let checkIn2Id = UUID()
        let checkIn3Id = UUID()

        // Check-ins ordered by day: 0, 7, 14, 21
        // Monotonic stress: 1 -> 2 -> 3 -> 4
        let checkIns = [
            makeCheckIn(id: checkIn0Id, sessionId: sessionId, day: 0, stressLevel: 1),
            makeCheckIn(id: checkIn1Id, sessionId: sessionId, day: 7, stressLevel: 2),
            makeCheckIn(id: checkIn2Id, sessionId: sessionId, day: 14, stressLevel: 3),
            makeCheckIn(id: checkIn3Id, sessionId: sessionId, day: 21, stressLevel: 4)
        ]

        // CRITICAL: ScorePoint.day values are INTENTIONALLY WRONG (999, 888, 777, 666)
        // but checkInId is CORRECT. If implementation used day for join, it would fail.
        // The correct scores by checkInId: 80 -> 75 -> 68 -> 60
        // Deltas: -5, -7, -8 (negative correlation with stress)
        let timeline = [
            makeScorePoint(checkInId: checkIn0Id, day: 999, overallScore: 80), // day is wrong, checkInId is correct
            makeScorePoint(checkInId: checkIn1Id, day: 888, overallScore: 75),
            makeScorePoint(checkInId: checkIn2Id, day: 777, overallScore: 68),
            makeScorePoint(checkInId: checkIn3Id, day: 666, overallScore: 60)
        ]

        let reliability: [UUID: ReliabilityMetadata] = [
            checkIn0Id: makeReliability(score: 0.9),
            checkIn1Id: makeReliability(score: 0.8),
            checkIn2Id: makeReliability(score: 0.7),
            checkIn3Id: makeReliability(score: 0.9)
        ]

        // When
        let insights = analyzer.analyze(
            checkIns: checkIns,
            timeline: timeline,
            reliability: reliability
        )

        // Then: Stress level should show negative correlation
        // If the implementation incorrectly used ScorePoint.day for joins, this would fail
        // because the day values (999, 888, 777, 666) don't match CheckIn.day (0, 7, 14, 21)
        let stressInsight = insights.first { $0.factor == .stressLevel }
        XCTAssertNotNil(stressInsight, "Should have stress insight - proves checkInId join works")

        if let insight = stressInsight {
            // Check correlation is negative (higher stress -> worse scores)
            XCTAssertLessThan(insight.correlation, 0, "Stress correlation should be negative")
            XCTAssertGreaterThanOrEqual(abs(insight.correlation), 0.3, "Correlation should be significant")

            // Verify sample count matches expected pairs
            XCTAssertEqual(insight.sampleCount, 3, "Should have 3 pairs")
        }
    }

    /// Test 7: Single check-in returns empty results
    func testAnalyzeWithSingleCheckIn() {
        // Given: Only 1 check-in
        let sessionId = UUID()
        let checkIn0Id = UUID()

        let checkIns = [
            makeCheckIn(id: checkIn0Id, sessionId: sessionId, day: 0, sleepHours: 7.0)
        ]

        let timeline = [
            makeScorePoint(checkInId: checkIn0Id, day: 0, overallScore: 60)
        ]

        let reliability: [UUID: ReliabilityMetadata] = [
            checkIn0Id: makeReliability(score: 0.8)
        ]

        // When
        let insights = analyzer.analyze(
            checkIns: checkIns,
            timeline: timeline,
            reliability: reliability
        )

        // Then
        XCTAssertTrue(insights.isEmpty, "Single check-in should return empty insights")
    }

    /// Test 8: Check-ins without lifestyle data are handled gracefully
    func testCheckInsWithoutLifestyleData() {
        // Given: Check-ins with no lifestyle data
        let sessionId = UUID()
        let checkIn0Id = UUID()
        let checkIn1Id = UUID()
        let checkIn2Id = UUID()
        let checkIn3Id = UUID()

        // Create check-ins without lifestyle data
        let checkIns = [
            CheckIn(id: checkIn0Id, sessionId: sessionId, day: 0, captureDate: Date()),
            CheckIn(id: checkIn1Id, sessionId: sessionId, day: 7, captureDate: Date()),
            CheckIn(id: checkIn2Id, sessionId: sessionId, day: 14, captureDate: Date()),
            CheckIn(id: checkIn3Id, sessionId: sessionId, day: 21, captureDate: Date())
        ]

        let timeline = [
            makeScorePoint(checkInId: checkIn0Id, day: 0, overallScore: 60),
            makeScorePoint(checkInId: checkIn1Id, day: 7, overallScore: 65),
            makeScorePoint(checkInId: checkIn2Id, day: 14, overallScore: 70),
            makeScorePoint(checkInId: checkIn3Id, day: 21, overallScore: 75)
        ]

        let reliability: [UUID: ReliabilityMetadata] = [
            checkIn0Id: makeReliability(score: 0.8),
            checkIn1Id: makeReliability(score: 0.8),
            checkIn2Id: makeReliability(score: 0.8),
            checkIn3Id: makeReliability(score: 0.8)
        ]

        // When
        let insights = analyzer.analyze(
            checkIns: checkIns,
            timeline: timeline,
            reliability: reliability
        )

        // Then: Should return empty (no lifestyle data to analyze)
        XCTAssertTrue(insights.isEmpty, "Check-ins without lifestyle data should return empty insights")
    }

    /// Test 9: Exercise minutes factor works correctly
    func testExerciseMinutesFactor() {
        // Given: 4 check-ins with monotonic exercise data
        let sessionId = UUID()
        let checkIn0Id = UUID()
        let checkIn1Id = UUID()
        let checkIn2Id = UUID()
        let checkIn3Id = UUID()

        // Exercise minutes: 0 -> 15 -> 30 -> 45
        let checkIns = [
            makeCheckIn(id: checkIn0Id, sessionId: sessionId, day: 0, exerciseMinutes: 0),
            makeCheckIn(id: checkIn1Id, sessionId: sessionId, day: 7, exerciseMinutes: 15),
            makeCheckIn(id: checkIn2Id, sessionId: sessionId, day: 14, exerciseMinutes: 30),
            makeCheckIn(id: checkIn3Id, sessionId: sessionId, day: 21, exerciseMinutes: 45)
        ]

        // Scores improve with exercise: 55 -> 60 -> 66 -> 73
        // Deltas: +5, +6, +7 (positive correlation expected)
        let timeline = [
            makeScorePoint(checkInId: checkIn0Id, day: 0, overallScore: 55),
            makeScorePoint(checkInId: checkIn1Id, day: 7, overallScore: 60),
            makeScorePoint(checkInId: checkIn2Id, day: 14, overallScore: 66),
            makeScorePoint(checkInId: checkIn3Id, day: 21, overallScore: 73)
        ]

        let reliability: [UUID: ReliabilityMetadata] = [
            checkIn0Id: makeReliability(score: 0.7),
            checkIn1Id: makeReliability(score: 0.7),
            checkIn2Id: makeReliability(score: 0.7),
            checkIn3Id: makeReliability(score: 0.7)
        ]

        // When
        let insights = analyzer.analyze(
            checkIns: checkIns,
            timeline: timeline,
            reliability: reliability
        )

        // Then
        let exerciseInsight = insights.first { $0.factor == .exerciseMinutes }
        XCTAssertNotNil(exerciseInsight, "Should have exercise minutes insight")

        if let insight = exerciseInsight {
            XCTAssertGreaterThan(insight.correlation, 0, "Exercise correlation should be positive")
            XCTAssertGreaterThanOrEqual(abs(insight.correlation), 0.3, "Correlation should be significant")
        }
    }

    /// Test 10: Water intake and sun exposure factors
    /// Uses monotonic fixture to ensure both insights MUST exist
    func testWaterAndSunExposureFactors() throws {
        // Given: Check-ins with water intake and sun exposure data
        let sessionId = UUID()
        let checkIn0Id = UUID()
        let checkIn1Id = UUID()
        let checkIn2Id = UUID()
        let checkIn3Id = UUID()

        // Water: 1 -> 2 -> 3 -> 4 (increasing, monotonic)
        // Sun: 4 -> 3 -> 2 -> 1 (decreasing, monotonic)
        let checkIns = [
            makeCheckIn(id: checkIn0Id, sessionId: sessionId, day: 0, waterIntakeLevel: 1, sunExposureLevel: 4),
            makeCheckIn(id: checkIn1Id, sessionId: sessionId, day: 7, waterIntakeLevel: 2, sunExposureLevel: 3),
            makeCheckIn(id: checkIn2Id, sessionId: sessionId, day: 14, waterIntakeLevel: 3, sunExposureLevel: 2),
            makeCheckIn(id: checkIn3Id, sessionId: sessionId, day: 21, waterIntakeLevel: 4, sunExposureLevel: 1)
        ]

        // Scores improve monotonically: 50 -> 55 -> 62 -> 70
        // Deltas: +5, +7, +8 (all positive, monotonic increasing)
        // Factor values for water (from current checkIn): [1, 2, 3]
        // Factor values for sun (from current checkIn): [4, 3, 2]
        // Water -> positive correlation (more water, better delta)
        // Sun -> negative correlation (more sun, worse delta in this fixture)
        let timeline = [
            makeScorePoint(checkInId: checkIn0Id, day: 0, overallScore: 50),
            makeScorePoint(checkInId: checkIn1Id, day: 7, overallScore: 55),
            makeScorePoint(checkInId: checkIn2Id, day: 14, overallScore: 62),
            makeScorePoint(checkInId: checkIn3Id, day: 21, overallScore: 70)
        ]

        let reliability: [UUID: ReliabilityMetadata] = [
            checkIn0Id: makeReliability(score: 0.8),
            checkIn1Id: makeReliability(score: 0.8),
            checkIn2Id: makeReliability(score: 0.8),
            checkIn3Id: makeReliability(score: 0.8)
        ]

        // When
        let insights = analyzer.analyze(
            checkIns: checkIns,
            timeline: timeline,
            reliability: reliability
        )

        // Then: Both insights MUST exist with deterministic correlations
        let waterInsight = insights.first { $0.factor == .waterIntakeLevel }
        let sunInsight = insights.first { $0.factor == .sunExposureLevel }

        // Water insight must exist and show positive correlation
        XCTAssertNotNil(waterInsight, "Fixture should produce water intake insight")
        XCTAssertNotNil(sunInsight, "Fixture should produce sun exposure insight")

        // Force unwrap is safe due to above assertions
        XCTAssertGreaterThan(try XCTUnwrap(waterInsight?.correlation), 0, "Water correlation should be positive")
        XCTAssertGreaterThanOrEqual(
            try abs(XCTUnwrap(waterInsight?.correlation)),
            0.3,
            "Water correlation should be significant"
        )
        XCTAssertEqual(try XCTUnwrap(waterInsight?.sampleCount), 3, "Should have 3 pairs")

        // Sun should show negative correlation (less sun -> better scores)
        XCTAssertLessThan(try XCTUnwrap(sunInsight?.correlation), 0, "Sun correlation should be negative")
        XCTAssertGreaterThanOrEqual(
            try abs(XCTUnwrap(sunInsight?.correlation)),
            0.3,
            "Sun correlation should be significant"
        )
        XCTAssertEqual(try XCTUnwrap(sunInsight?.sampleCount), 3, "Should have 3 pairs")
    }
}
