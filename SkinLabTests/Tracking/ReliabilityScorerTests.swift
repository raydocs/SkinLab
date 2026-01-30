// SkinLabTests/Tracking/ReliabilityScorerTests.swift
@testable import SkinLab
import XCTest

final class ReliabilityScorerTests: XCTestCase {
    var scorer: ReliabilityScorer!

    override func setUp() {
        super.setUp()
        scorer = ReliabilityScorer()
    }

    override func tearDown() {
        scorer = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Create a PhotoStandardizationMetadata with customizable parameters
    private func makePhotoMeta(
        lighting: PhotoStandardizationMetadata.LightingRating = .optimal,
        faceDetected: Bool = true,
        yawDegrees: Double = 0,
        pitchDegrees: Double = 0,
        rollDegrees: Double = 0,
        distance: PhotoStandardizationMetadata.DistanceRating = .optimal,
        captureSource: PhotoStandardizationMetadata.CaptureSource = .camera,
        userOverride: PhotoStandardizationMetadata.UserOverride? = nil
    ) -> PhotoStandardizationMetadata {
        PhotoStandardizationMetadata(
            capturedAt: Date(),
            cameraPosition: .front,
            captureSource: captureSource,
            lighting: lighting,
            faceDetected: faceDetected,
            yawDegrees: yawDegrees,
            pitchDegrees: pitchDegrees,
            rollDegrees: rollDegrees,
            distance: distance,
            isReady: true,
            suggestions: [],
            userOverride: userOverride
        )
    }

    /// Create a CheckIn with customizable parameters
    private func makeCheckIn(
        id: UUID = UUID(),
        sessionId: UUID = UUID(),
        day: Int,
        captureDate: Date = Date(),
        analysisId: UUID? = nil,
        photoStandardization: PhotoStandardizationMetadata? = nil
    ) -> CheckIn {
        CheckIn(
            id: id,
            sessionId: sessionId,
            day: day,
            captureDate: captureDate,
            photoPath: nil,
            analysisId: analysisId,
            usedProducts: [],
            notes: nil,
            feeling: nil,
            photoStandardization: photoStandardization,
            lifestyle: nil,
            reliability: nil
        )
    }

    /// Create a TrackingSession with customizable start date
    private func makeSession(
        id: UUID = UUID(),
        startDate: Date = Date()
    ) -> TrackingSession {
        let session = TrackingSession(id: id, targetProducts: [])
        session.startDate = startDate
        return session
    }

    /// Create a SkinAnalysis with customizable confidence score
    private func makeAnalysis(
        id: UUID = UUID(),
        confidenceScore: Int = 85
    ) -> SkinAnalysis {
        SkinAnalysis(
            id: id,
            skinType: .combination,
            skinAge: 25,
            overallScore: 75,
            issues: IssueScores(
                spots: 3, acne: 2, pores: 3, wrinkles: 2,
                redness: 2, evenness: 4, texture: 3
            ),
            regions: RegionScores(
                tZone: 70, leftCheek: 75, rightCheek: 74, eyeArea: 72, chin: 73
            ),
            recommendations: [],
            analyzedAt: Date(),
            confidenceScore: confidenceScore,
            imageQuality: nil
        )
    }

    // MARK: - Test Cases

    /// Test 1: Perfect photo with optimal conditions should get high score (close to 1.0)
    func testScoreWithPerfectPhoto() {
        // Given: A check-in with perfect photo conditions
        let sessionId = UUID()
        let session = makeSession(id: sessionId, startDate: Date())

        let photoMeta = makePhotoMeta(
            lighting: .optimal,
            faceDetected: true,
            yawDegrees: 0,
            pitchDegrees: 0,
            rollDegrees: 0,
            distance: .optimal,
            captureSource: .camera,
            userOverride: nil
        )

        let analysisId = UUID()
        let checkIn = makeCheckIn(
            sessionId: sessionId,
            day: 0,
            captureDate: session.startDate, // Same day as expected
            analysisId: analysisId,
            photoStandardization: photoMeta
        )

        let analysis = makeAnalysis(id: analysisId, confidenceScore: 90)

        // When
        let result = scorer.score(
            checkIn: checkIn,
            analysis: analysis,
            session: session,
            expectedDay: 0,
            cameraPositionConsistency: true
        )

        // Then: Score should be 1.0 (no deductions)
        XCTAssertEqual(result.score, 1.0, accuracy: 0.001, "Perfect photo should have score of 1.0")
        XCTAssertEqual(result.level, .high, "Perfect photo should have high reliability level")
        XCTAssertTrue(result.reasons.isEmpty, "Perfect photo should have no negative reasons")
    }

    /// Test 2: Low light (tooDark) should reduce score and add .lowLight reason
    func testScoreWithLowLight() {
        // Given: A check-in with low light
        let sessionId = UUID()
        let session = makeSession(id: sessionId, startDate: Date())

        let photoMeta = makePhotoMeta(
            lighting: .tooDark,
            faceDetected: true,
            yawDegrees: 0,
            pitchDegrees: 0,
            rollDegrees: 0,
            distance: .optimal
        )

        let checkIn = makeCheckIn(
            sessionId: sessionId,
            day: 0,
            captureDate: session.startDate,
            photoStandardization: photoMeta
        )

        // When
        let result = scorer.score(
            checkIn: checkIn,
            analysis: nil,
            session: session,
            expectedDay: 0,
            cameraPositionConsistency: true
        )

        // Then: Score should be reduced by 0.25 (from 1.0 to 0.75)
        XCTAssertEqual(result.score, 0.75, accuracy: 0.001, "Low light should reduce score by 0.25")
        XCTAssertTrue(result.reasons.contains(.lowLight), "Should contain lowLight reason")
        XCTAssertEqual(result.level, .high, "Score of 0.75 should still be high level (>= 0.7)")
    }

    /// Test 3: High light (tooBright) should reduce score and add .highLight reason
    /// This verifies the fix from fn-3.3 where tooBright was incorrectly mapped to .lowLight
    func testScoreWithHighLight() {
        // Given: A check-in with high light (tooBright)
        let sessionId = UUID()
        let session = makeSession(id: sessionId, startDate: Date())

        let photoMeta = makePhotoMeta(
            lighting: .tooBright, // CRITICAL: Test the tooBright -> highLight mapping
            faceDetected: true,
            yawDegrees: 0,
            pitchDegrees: 0,
            rollDegrees: 0,
            distance: .optimal
        )

        let checkIn = makeCheckIn(
            sessionId: sessionId,
            day: 0,
            captureDate: session.startDate,
            photoStandardization: photoMeta
        )

        // When
        let result = scorer.score(
            checkIn: checkIn,
            analysis: nil,
            session: session,
            expectedDay: 0,
            cameraPositionConsistency: true
        )

        // Then: Score should be reduced by 0.25
        XCTAssertEqual(result.score, 0.75, accuracy: 0.001, "High light should reduce score by 0.25")
        // CRITICAL: Verify tooBright maps to .highLight, NOT .lowLight
        XCTAssertTrue(result.reasons.contains(.highLight), "tooBright should map to .highLight reason (fn-3.3 fix)")
        XCTAssertFalse(result.reasons.contains(.lowLight), "tooBright should NOT map to .lowLight")
        XCTAssertEqual(result.level, .high, "Score of 0.75 should still be high level (>= 0.7)")
    }

    /// Test 4: Bad face angle (yaw/pitch/roll > thresholds) should reduce score
    func testScoreWithBadFaceAngle() {
        // Given: A check-in with bad face angle (yaw > 20)
        let sessionId = UUID()
        let session = makeSession(id: sessionId, startDate: Date())

        let photoMeta = makePhotoMeta(
            lighting: .optimal,
            faceDetected: true,
            yawDegrees: 25, // > 20 threshold
            pitchDegrees: 0,
            rollDegrees: 0,
            distance: .optimal
        )

        let checkIn = makeCheckIn(
            sessionId: sessionId,
            day: 0,
            captureDate: session.startDate,
            photoStandardization: photoMeta
        )

        // When
        let result = scorer.score(
            checkIn: checkIn,
            analysis: nil,
            session: session,
            expectedDay: 0,
            cameraPositionConsistency: true
        )

        // Then: Score should be reduced by 0.20 (from 1.0 to 0.80)
        XCTAssertEqual(result.score, 0.80, accuracy: 0.001, "Bad face angle should reduce score by 0.20")
        XCTAssertTrue(result.reasons.contains(.angleOff), "Should contain angleOff reason")
    }

    /// Test 5: Photo from library (captureSource == .library) should reduce score
    func testScoreFromLibrary() {
        // Given: A check-in from library
        let sessionId = UUID()
        let session = makeSession(id: sessionId, startDate: Date())

        let photoMeta = makePhotoMeta(
            lighting: .optimal,
            faceDetected: true,
            yawDegrees: 0,
            pitchDegrees: 0,
            rollDegrees: 0,
            distance: .optimal,
            captureSource: .library // From photo library, not live camera
        )

        let checkIn = makeCheckIn(
            sessionId: sessionId,
            day: 0,
            captureDate: session.startDate,
            photoStandardization: photoMeta
        )

        // When
        let result = scorer.score(
            checkIn: checkIn,
            analysis: nil,
            session: session,
            expectedDay: 0,
            cameraPositionConsistency: true
        )

        // Then: Score should be reduced by 0.15 (from 1.0 to 0.85)
        XCTAssertEqual(result.score, 0.85, accuracy: 0.001, "Library photo should reduce score by 0.15")
        XCTAssertTrue(result.reasons.contains(.missingLiveConditions), "Should contain missingLiveConditions reason")
        XCTAssertEqual(result.level, .high, "Score of 0.85 should be high level")
    }

    /// Test 6: User flagged issue (userOverride == .userFlaggedIssue) should reduce score
    func testScoreWithUserFlaggedIssue() {
        // Given: A check-in where user flagged an issue
        let sessionId = UUID()
        let session = makeSession(id: sessionId, startDate: Date())

        let photoMeta = makePhotoMeta(
            lighting: .optimal,
            faceDetected: true,
            yawDegrees: 0,
            pitchDegrees: 0,
            rollDegrees: 0,
            distance: .optimal,
            captureSource: .camera,
            userOverride: .userFlaggedIssue
        )

        let checkIn = makeCheckIn(
            sessionId: sessionId,
            day: 0,
            captureDate: session.startDate,
            photoStandardization: photoMeta
        )

        // When
        let result = scorer.score(
            checkIn: checkIn,
            analysis: nil,
            session: session,
            expectedDay: 0,
            cameraPositionConsistency: true
        )

        // Then: Score should be reduced by 0.10 (from 1.0 to 0.90)
        XCTAssertEqual(result.score, 0.90, accuracy: 0.001, "User flagged issue should reduce score by 0.10")
        XCTAssertTrue(result.reasons.contains(.userFlaggedIssue), "Should contain userFlaggedIssue reason")
        XCTAssertEqual(result.level, .high, "Score of 0.90 should be high level")
    }

    /// Test 7: Timing penalty for late check-in (captureDate > 3 days after expected)
    func testTimingPenalty() throws {
        // Given: A check-in captured 5 days after expected
        let sessionId = UUID()
        let sessionStartDate = Date()
        let session = makeSession(id: sessionId, startDate: sessionStartDate)

        // Expected day 7 would be sessionStartDate + 7 days
        // Capture 5 days late (12 days from start)
        let expectedDay = 7
        let captureDate = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 12, to: sessionStartDate))

        let photoMeta = makePhotoMeta(
            lighting: .optimal,
            faceDetected: true,
            yawDegrees: 0,
            pitchDegrees: 0,
            rollDegrees: 0,
            distance: .optimal
        )

        let checkIn = makeCheckIn(
            sessionId: sessionId,
            day: 7,
            captureDate: captureDate, // 5 days late
            photoStandardization: photoMeta
        )

        // When
        let result = scorer.score(
            checkIn: checkIn,
            analysis: nil,
            session: session,
            expectedDay: expectedDay,
            cameraPositionConsistency: true
        )

        // Then: Score should be reduced by 0.10 for > 3 days off target
        XCTAssertEqual(result.score, 0.90, accuracy: 0.001, "Late check-in (> 3 days) should reduce score by 0.10")
        XCTAssertTrue(result.reasons.contains(.longInterval), "Should contain longInterval reason")
    }

    /// Test 8: No face detected should reduce score significantly
    func testScoreWithNoFaceDetected() {
        // Given: A check-in with no face detected
        let sessionId = UUID()
        let session = makeSession(id: sessionId, startDate: Date())

        let photoMeta = makePhotoMeta(
            lighting: .optimal,
            faceDetected: false, // No face detected
            yawDegrees: 0,
            pitchDegrees: 0,
            rollDegrees: 0,
            distance: .optimal
        )

        let checkIn = makeCheckIn(
            sessionId: sessionId,
            day: 0,
            captureDate: session.startDate,
            photoStandardization: photoMeta
        )

        // When
        let result = scorer.score(
            checkIn: checkIn,
            analysis: nil,
            session: session,
            expectedDay: 0,
            cameraPositionConsistency: true
        )

        // Then: Score should be reduced by 0.20 (from 1.0 to 0.80)
        XCTAssertEqual(result.score, 0.80, accuracy: 0.001, "No face detected should reduce score by 0.20")
        XCTAssertTrue(result.reasons.contains(.noFaceDetected), "Should contain noFaceDetected reason")
    }

    /// Test 9: Distance off (too far/too close) should reduce score
    func testScoreWithDistanceOff() {
        // Given: A check-in with distance too far
        let sessionId = UUID()
        let session = makeSession(id: sessionId, startDate: Date())

        let photoMeta = makePhotoMeta(
            lighting: .optimal,
            faceDetected: true,
            yawDegrees: 0,
            pitchDegrees: 0,
            rollDegrees: 0,
            distance: .tooFar // Distance off
        )

        let checkIn = makeCheckIn(
            sessionId: sessionId,
            day: 0,
            captureDate: session.startDate,
            photoStandardization: photoMeta
        )

        // When
        let result = scorer.score(
            checkIn: checkIn,
            analysis: nil,
            session: session,
            expectedDay: 0,
            cameraPositionConsistency: true
        )

        // Then: Score should be reduced by 0.15 (from 1.0 to 0.85)
        XCTAssertEqual(result.score, 0.85, accuracy: 0.001, "Distance too far should reduce score by 0.15")
        XCTAssertTrue(result.reasons.contains(.distanceOff), "Should contain distanceOff reason")
    }

    /// Test 10: Low analysis confidence should reduce score
    func testScoreWithLowAnalysisConfidence() {
        // Given: A check-in with low confidence analysis
        let sessionId = UUID()
        let session = makeSession(id: sessionId, startDate: Date())

        let photoMeta = makePhotoMeta()

        let analysisId = UUID()
        let checkIn = makeCheckIn(
            sessionId: sessionId,
            day: 0,
            captureDate: session.startDate,
            analysisId: analysisId,
            photoStandardization: photoMeta
        )

        let analysis = makeAnalysis(id: analysisId, confidenceScore: 40) // < 50 threshold

        // When
        let result = scorer.score(
            checkIn: checkIn,
            analysis: analysis,
            session: session,
            expectedDay: 0,
            cameraPositionConsistency: true
        )

        // Then: Score should be reduced by 0.20 for confidence < 50
        XCTAssertEqual(
            result.score,
            0.80,
            accuracy: 0.001,
            "Low analysis confidence (< 50) should reduce score by 0.20"
        )
        XCTAssertTrue(result.reasons.contains(.lowAnalysisConfidence), "Should contain lowAnalysisConfidence reason")
    }

    /// Test 11: Missing photo standardization metadata should reduce score significantly
    func testScoreWithMissingPhotoMeta() {
        // Given: A check-in without photo standardization metadata
        let sessionId = UUID()
        let session = makeSession(id: sessionId, startDate: Date())

        let checkIn = makeCheckIn(
            sessionId: sessionId,
            day: 0,
            captureDate: session.startDate,
            photoStandardization: nil // No photo metadata
        )

        // When
        let result = scorer.score(
            checkIn: checkIn,
            analysis: nil,
            session: session,
            expectedDay: 0,
            cameraPositionConsistency: true
        )

        // Then: Score should be reduced by 0.30 (from 1.0 to 0.70)
        XCTAssertEqual(result.score, 0.70, accuracy: 0.001, "Missing photo metadata should reduce score by 0.30")
        XCTAssertTrue(result.reasons.contains(.missingLiveConditions), "Should contain missingLiveConditions reason")
        XCTAssertEqual(result.level, .high, "Score of 0.70 should still be high level (>= 0.7)")
    }

    /// Test 12: Multiple issues should accumulate penalties
    func testScoreWithMultipleIssues() {
        // Given: A check-in with multiple issues
        let sessionId = UUID()
        let session = makeSession(id: sessionId, startDate: Date())

        let photoMeta = makePhotoMeta(
            lighting: .tooDark, // -0.25
            faceDetected: true,
            yawDegrees: 25, // -0.20 (> 20 threshold)
            pitchDegrees: 0,
            rollDegrees: 0,
            distance: .tooFar // -0.15
        )

        let checkIn = makeCheckIn(
            sessionId: sessionId,
            day: 0,
            captureDate: session.startDate,
            photoStandardization: photoMeta
        )

        // When
        let result = scorer.score(
            checkIn: checkIn,
            analysis: nil,
            session: session,
            expectedDay: 0,
            cameraPositionConsistency: true
        )

        // Then: Score should be 1.0 - 0.25 - 0.20 - 0.15 = 0.40
        XCTAssertEqual(
            result.score,
            0.40,
            accuracy: 0.001,
            "Multiple issues should accumulate: 1.0 - 0.25 - 0.20 - 0.15 = 0.40"
        )
        XCTAssertEqual(result.level, .medium, "Score of 0.40 should be medium level (>= 0.4, < 0.7)")
        XCTAssertTrue(result.reasons.contains(.lowLight), "Should contain lowLight reason")
        XCTAssertTrue(result.reasons.contains(.angleOff), "Should contain angleOff reason")
        XCTAssertTrue(result.reasons.contains(.distanceOff), "Should contain distanceOff reason")
    }

    /// Test 13: Extreme penalties should floor at 0
    func testScoreFloorAtZero() throws {
        // Given: A check-in with many issues that would result in negative score
        let sessionId = UUID()
        let sessionStartDate = Date()
        let session = makeSession(id: sessionId, startDate: sessionStartDate)

        // Calculate capture date 10 days late (> 3 days threshold)
        let captureDate = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 17, to: sessionStartDate))

        let photoMeta = makePhotoMeta(
            lighting: .tooDark, // -0.25
            faceDetected: false, // -0.20
            yawDegrees: 25, // -0.20
            pitchDegrees: 0,
            rollDegrees: 0,
            distance: .tooFar, // -0.15
            captureSource: .library, // -0.15
            userOverride: .userFlaggedIssue // -0.10
        )

        let analysisId = UUID()
        let checkIn = makeCheckIn(
            sessionId: sessionId,
            day: 7,
            captureDate: captureDate, // -0.10 (> 3 days off)
            analysisId: analysisId,
            photoStandardization: photoMeta
        )

        let analysis = makeAnalysis(id: analysisId, confidenceScore: 30) // -0.20 (< 50)

        // When
        let result = scorer.score(
            checkIn: checkIn,
            analysis: analysis,
            session: session,
            expectedDay: 7,
            cameraPositionConsistency: false // -0.10
        )

        // Then: Score should floor at 0
        // Total penalties: 0.25 + 0.20 + 0.20 + 0.15 + 0.15 + 0.10 + 0.10 + 0.20 + 0.10 = 1.45
        // 1.0 - 1.45 = -0.45, but should floor at 0
        XCTAssertEqual(result.score, 0.0, accuracy: 0.001, "Score should floor at 0 with extreme penalties")
        XCTAssertEqual(result.level, .low, "Score of 0 should be low level")
    }

    /// Test 14: Reliability level boundaries
    func testReliabilityLevelBoundaries() {
        // Given: A session
        let sessionId = UUID()
        let session = makeSession(id: sessionId, startDate: Date())

        // Test high level boundary (>= 0.7)
        let highPhotoMeta = makePhotoMeta(lighting: .optimal)
        let highCheckIn = makeCheckIn(
            sessionId: sessionId,
            day: 0,
            captureDate: session.startDate,
            photoStandardization: highPhotoMeta
        )
        let highResult = scorer.score(checkIn: highCheckIn, analysis: nil, session: session, expectedDay: 0)
        XCTAssertEqual(highResult.level, .high, "Score >= 0.7 should be high level")

        // Test medium level boundary (>= 0.4, < 0.7)
        // Need penalties totaling 0.35-0.55 to get score between 0.45-0.65
        let mediumPhotoMeta = makePhotoMeta(
            lighting: .tooDark, // -0.25
            faceDetected: true,
            yawDegrees: 25, // -0.20
            pitchDegrees: 0,
            rollDegrees: 0,
            distance: .optimal
        )
        let mediumCheckIn = makeCheckIn(
            sessionId: sessionId,
            day: 0,
            captureDate: session.startDate,
            photoStandardization: mediumPhotoMeta
        )
        let mediumResult = scorer.score(checkIn: mediumCheckIn, analysis: nil, session: session, expectedDay: 0)
        XCTAssertEqual(mediumResult.score, 0.55, accuracy: 0.001)
        XCTAssertEqual(mediumResult.level, .medium, "Score 0.55 should be medium level")

        // Test low level boundary (< 0.4)
        let lowPhotoMeta = makePhotoMeta(
            lighting: .tooDark, // -0.25
            faceDetected: false, // -0.20
            yawDegrees: 25, // -0.20
            pitchDegrees: 0,
            rollDegrees: 0,
            distance: .optimal
        )
        let lowCheckIn = makeCheckIn(
            sessionId: sessionId,
            day: 0,
            captureDate: session.startDate,
            photoStandardization: lowPhotoMeta
        )
        let lowResult = scorer.score(checkIn: lowCheckIn, analysis: nil, session: session, expectedDay: 0)
        XCTAssertEqual(lowResult.score, 0.35, accuracy: 0.001)
        XCTAssertEqual(lowResult.level, .low, "Score 0.35 should be low level")
    }

    /// Test 15: Inconsistent camera position should reduce score
    func testScoreWithInconsistentCameraPosition() {
        // Given: A check-in with inconsistent camera position
        let sessionId = UUID()
        let session = makeSession(id: sessionId, startDate: Date())

        let photoMeta = makePhotoMeta()

        let checkIn = makeCheckIn(
            sessionId: sessionId,
            day: 0,
            captureDate: session.startDate,
            photoStandardization: photoMeta
        )

        // When: cameraPositionConsistency is false
        let result = scorer.score(
            checkIn: checkIn,
            analysis: nil,
            session: session,
            expectedDay: 0,
            cameraPositionConsistency: false // Inconsistent
        )

        // Then: Score should be reduced by 0.10
        XCTAssertEqual(result.score, 0.90, accuracy: 0.001, "Inconsistent camera position should reduce score by 0.10")
        XCTAssertTrue(
            result.reasons.contains(.inconsistentCameraPosition),
            "Should contain inconsistentCameraPosition reason"
        )
    }

    /// Test 16: Slight lighting issues should have smaller penalty
    func testScoreWithSlightLightingIssues() {
        // Given: A check-in with slightly dark lighting
        let sessionId = UUID()
        let session = makeSession(id: sessionId, startDate: Date())

        let photoMeta = makePhotoMeta(
            lighting: .slightlyDark // Slight issue, not severe
        )

        let checkIn = makeCheckIn(
            sessionId: sessionId,
            day: 0,
            captureDate: session.startDate,
            photoStandardization: photoMeta
        )

        // When
        let result = scorer.score(
            checkIn: checkIn,
            analysis: nil,
            session: session,
            expectedDay: 0,
            cameraPositionConsistency: true
        )

        // Then: Score should be reduced by 0.10 (not 0.25)
        XCTAssertEqual(result.score, 0.90, accuracy: 0.001, "Slightly dark should reduce score by 0.10")
        // No reason should be added for slight issues
        XCTAssertFalse(result.reasons.contains(.lowLight), "Slight lighting issue should not add lowLight reason")
    }

    /// Test 17: Moderate timing offset (1-3 days) should have smaller penalty
    func testScoreWithModerateTimingOffset() throws {
        // Given: A check-in captured 2 days after expected
        let sessionId = UUID()
        let sessionStartDate = Date()
        let session = makeSession(id: sessionId, startDate: sessionStartDate)

        // Expected day 7, capture 2 days late (9 days from start)
        let captureDate = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 9, to: sessionStartDate))

        let photoMeta = makePhotoMeta()

        let checkIn = makeCheckIn(
            sessionId: sessionId,
            day: 7,
            captureDate: captureDate,
            photoStandardization: photoMeta
        )

        // When
        let result = scorer.score(
            checkIn: checkIn,
            analysis: nil,
            session: session,
            expectedDay: 7,
            cameraPositionConsistency: true
        )

        // Then: Score should be reduced by 0.05 (dayDiff = 2, which is > 1 but <= 3)
        XCTAssertEqual(result.score, 0.95, accuracy: 0.001, "2 days late should reduce score by 0.05")
        // No longInterval reason for moderate delay
        XCTAssertFalse(result.reasons.contains(.longInterval), "Moderate delay should not add longInterval reason")
    }

    /// Test 18: ScoreAll should correctly score multiple check-ins
    func testScoreAll() throws {
        // Given: A session with multiple check-ins
        let sessionId = UUID()
        let sessionStartDate = Date()
        let session = makeSession(id: sessionId, startDate: sessionStartDate)

        let checkIn0Id = UUID()
        let checkIn1Id = UUID()
        let analysisId = UUID()

        let goodPhotoMeta = makePhotoMeta(lighting: .optimal)
        let badPhotoMeta = makePhotoMeta(lighting: .tooDark)

        let checkIns = try [
            makeCheckIn(
                id: checkIn0Id,
                sessionId: sessionId,
                day: 0,
                captureDate: sessionStartDate,
                analysisId: analysisId,
                photoStandardization: goodPhotoMeta
            ),
            makeCheckIn(
                id: checkIn1Id,
                sessionId: sessionId,
                day: 7,
                captureDate: XCTUnwrap(Calendar.current.date(byAdding: .day, value: 7, to: sessionStartDate)),
                photoStandardization: badPhotoMeta
            )
        ]

        let analyses: [UUID: SkinAnalysis] = [
            analysisId: makeAnalysis(id: analysisId, confidenceScore: 85)
        ]

        // When
        let results = scorer.scoreAll(
            checkIns: checkIns,
            analyses: analyses,
            session: session
        )

        // Then
        XCTAssertEqual(results.count, 2, "Should have results for both check-ins")

        if let result0 = results[checkIn0Id] {
            XCTAssertEqual(result0.score, 1.0, accuracy: 0.001, "First check-in should have perfect score")
        } else {
            XCTFail("Should have result for check-in 0")
        }

        if let result1 = results[checkIn1Id] {
            XCTAssertEqual(result1.score, 0.75, accuracy: 0.001, "Second check-in should have reduced score")
            XCTAssertTrue(result1.reasons.contains(.lowLight))
        } else {
            XCTFail("Should have result for check-in 1")
        }
    }
}
