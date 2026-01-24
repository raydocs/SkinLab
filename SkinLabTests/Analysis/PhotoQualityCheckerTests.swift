// SkinLabTests/Analysis/PhotoQualityCheckerTests.swift
import XCTest

@testable import SkinLab

final class PhotoQualityCheckerTests: XCTestCase {

    // MARK: - LightingCondition Tests

    func testLightingCondition_isAcceptable() {
        XCTAssertFalse(LightingCondition.unknown.isAcceptable)
        XCTAssertFalse(LightingCondition.tooDark.isAcceptable)
        XCTAssertTrue(LightingCondition.slightlyDark.isAcceptable)
        XCTAssertTrue(LightingCondition.optimal.isAcceptable)
        XCTAssertTrue(LightingCondition.slightlyBright.isAcceptable)
        XCTAssertFalse(LightingCondition.tooBright.isAcceptable)
    }

    func testLightingCondition_suggestion() {
        XCTAssertNil(LightingCondition.unknown.suggestion)
        XCTAssertNotNil(LightingCondition.tooDark.suggestion)
        XCTAssertNil(LightingCondition.slightlyDark.suggestion)
        XCTAssertNil(LightingCondition.optimal.suggestion)
        XCTAssertNil(LightingCondition.slightlyBright.suggestion)
        XCTAssertNotNil(LightingCondition.tooBright.suggestion)
    }

    // MARK: - FaceAngle Tests

    func testFaceAngle_isOptimal_perfectAngle() {
        let angle = FaceAngle(yaw: 0, pitch: 0, roll: 0)
        XCTAssertTrue(angle.isOptimal)
        XCTAssertNil(angle.suggestion)
    }

    func testFaceAngle_isOptimal_withinTolerance() {
        let angle = FaceAngle(yaw: 10, pitch: 10, roll: 5)
        XCTAssertTrue(angle.isOptimal)
        XCTAssertNil(angle.suggestion)
    }

    func testFaceAngle_yawTooMuch_suggestionProvided() {
        let angleRight = FaceAngle(yaw: 20, pitch: 0, roll: 0)
        XCTAssertFalse(angleRight.isOptimal)
        XCTAssertNotNil(angleRight.suggestion)
        XCTAssertTrue(angleRight.suggestion?.contains("左") == true)

        let angleLeft = FaceAngle(yaw: -20, pitch: 0, roll: 0)
        XCTAssertFalse(angleLeft.isOptimal)
        XCTAssertNotNil(angleLeft.suggestion)
        XCTAssertTrue(angleLeft.suggestion?.contains("右") == true)
    }

    func testFaceAngle_pitchTooMuch_suggestionProvided() {
        let angleUp = FaceAngle(yaw: 0, pitch: 20, roll: 0)
        XCTAssertFalse(angleUp.isOptimal)
        XCTAssertNotNil(angleUp.suggestion)
        XCTAssertTrue(angleUp.suggestion?.contains("低头") == true)

        let angleDown = FaceAngle(yaw: 0, pitch: -20, roll: 0)
        XCTAssertFalse(angleDown.isOptimal)
        XCTAssertNotNil(angleDown.suggestion)
        XCTAssertTrue(angleDown.suggestion?.contains("抬头") == true)
    }

    func testFaceAngle_rollTooMuch_suggestionProvided() {
        let angleTilted = FaceAngle(yaw: 0, pitch: 0, roll: 15)
        XCTAssertFalse(angleTilted.isOptimal)
        XCTAssertNotNil(angleTilted.suggestion)
        XCTAssertTrue(angleTilted.suggestion?.contains("端正") == true)
    }

    // MARK: - DistanceCondition Tests

    func testDistanceCondition_isAcceptable() {
        XCTAssertFalse(DistanceCondition.unknown.isAcceptable)
        XCTAssertFalse(DistanceCondition.tooFar.isAcceptable)
        XCTAssertTrue(DistanceCondition.slightlyFar.isAcceptable)
        XCTAssertTrue(DistanceCondition.optimal.isAcceptable)
        XCTAssertTrue(DistanceCondition.slightlyClose.isAcceptable)
        XCTAssertFalse(DistanceCondition.tooClose.isAcceptable)
    }

    func testDistanceCondition_suggestion() {
        XCTAssertNil(DistanceCondition.unknown.suggestion)
        XCTAssertNotNil(DistanceCondition.tooFar.suggestion)
        XCTAssertNil(DistanceCondition.slightlyFar.suggestion)
        XCTAssertNil(DistanceCondition.optimal.suggestion)
        XCTAssertNil(DistanceCondition.slightlyClose.suggestion)
        XCTAssertNotNil(DistanceCondition.tooClose.suggestion)
    }

    // MARK: - CenteringCondition Tests

    func testCenteringCondition_isAcceptable() {
        XCTAssertTrue(CenteringCondition.unknown.isAcceptable)
        XCTAssertFalse(CenteringCondition.tooLeft.isAcceptable)
        XCTAssertFalse(CenteringCondition.tooRight.isAcceptable)
        XCTAssertFalse(CenteringCondition.tooHigh.isAcceptable)
        XCTAssertFalse(CenteringCondition.tooLow.isAcceptable)
        XCTAssertTrue(CenteringCondition.optimal.isAcceptable)
    }

    func testCenteringCondition_suggestion() {
        XCTAssertNil(CenteringCondition.unknown.suggestion)
        XCTAssertNotNil(CenteringCondition.tooLeft.suggestion)
        XCTAssertNotNil(CenteringCondition.tooRight.suggestion)
        XCTAssertNotNil(CenteringCondition.tooHigh.suggestion)
        XCTAssertNotNil(CenteringCondition.tooLow.suggestion)
        XCTAssertNil(CenteringCondition.optimal.suggestion)
    }

    func testCenteringCondition_fromFaceCenter_centered() {
        let center = CGPoint(x: 0.5, y: 0.5)
        let result = CenteringCondition.from(faceCenter: center)
        XCTAssertEqual(result, .optimal)
    }

    func testCenteringCondition_fromFaceCenter_withinTolerance() {
        // Just within 15% tolerance
        let nearCenter = CGPoint(x: 0.4, y: 0.6)
        let result = CenteringCondition.from(faceCenter: nearCenter)
        XCTAssertEqual(result, .optimal)
    }

    func testCenteringCondition_fromFaceCenter_tooLeft() {
        let leftOfCenter = CGPoint(x: 0.2, y: 0.5)
        let result = CenteringCondition.from(faceCenter: leftOfCenter)
        XCTAssertEqual(result, .tooLeft)
    }

    func testCenteringCondition_fromFaceCenter_tooRight() {
        let rightOfCenter = CGPoint(x: 0.8, y: 0.5)
        let result = CenteringCondition.from(faceCenter: rightOfCenter)
        XCTAssertEqual(result, .tooRight)
    }

    func testCenteringCondition_fromFaceCenter_tooLow() {
        let lowCenter = CGPoint(x: 0.5, y: 0.2)
        let result = CenteringCondition.from(faceCenter: lowCenter)
        XCTAssertEqual(result, .tooLow)
    }

    func testCenteringCondition_fromFaceCenter_tooHigh() {
        let highCenter = CGPoint(x: 0.5, y: 0.8)
        let result = CenteringCondition.from(faceCenter: highCenter)
        XCTAssertEqual(result, .tooHigh)
    }

    // MARK: - SharpnessCondition Tests

    func testSharpnessCondition_isAcceptable() {
        XCTAssertFalse(SharpnessCondition.unknown.isAcceptable)
        XCTAssertFalse(SharpnessCondition.blurry.isAcceptable)
        XCTAssertTrue(SharpnessCondition.slightlyBlurry.isAcceptable)
        XCTAssertTrue(SharpnessCondition.sharp.isAcceptable)
    }

    func testSharpnessCondition_suggestion() {
        XCTAssertNil(SharpnessCondition.unknown.suggestion)
        XCTAssertNotNil(SharpnessCondition.blurry.suggestion)
        XCTAssertNil(SharpnessCondition.slightlyBlurry.suggestion)
        XCTAssertNil(SharpnessCondition.sharp.suggestion)
    }

    func testSharpnessCondition_fromLaplacianVariance_blurry() {
        let result = SharpnessCondition.from(laplacianVariance: 30)
        XCTAssertEqual(result, .blurry)
    }

    func testSharpnessCondition_fromLaplacianVariance_slightlyBlurry() {
        let result = SharpnessCondition.from(laplacianVariance: 75)
        XCTAssertEqual(result, .slightlyBlurry)
    }

    func testSharpnessCondition_fromLaplacianVariance_sharp() {
        let result = SharpnessCondition.from(laplacianVariance: 150)
        XCTAssertEqual(result, .sharp)
    }

    // MARK: - PhotoCondition Tests

    func testPhotoCondition_isReady_allOptimal() {
        let condition = PhotoCondition(
            lighting: .optimal,
            faceDetected: true,
            faceAngle: FaceAngle(yaw: 0, pitch: 0, roll: 0),
            faceDistance: .optimal,
            faceCentering: .optimal,
            sharpness: .sharp
        )
        XCTAssertTrue(condition.isReady)
        XCTAssertTrue(condition.suggestions.isEmpty)
    }

    func testPhotoCondition_isReady_noFaceDetected() {
        let condition = PhotoCondition(
            lighting: .optimal,
            faceDetected: false,
            faceAngle: FaceAngle(yaw: 0, pitch: 0, roll: 0),
            faceDistance: .optimal,
            faceCentering: .optimal,
            sharpness: .sharp
        )
        XCTAssertFalse(condition.isReady)
        XCTAssertFalse(condition.suggestions.isEmpty)
    }

    func testPhotoCondition_isReady_poorLighting() {
        let condition = PhotoCondition(
            lighting: .tooDark,
            faceDetected: true,
            faceAngle: FaceAngle(yaw: 0, pitch: 0, roll: 0),
            faceDistance: .optimal,
            faceCentering: .optimal,
            sharpness: .sharp
        )
        XCTAssertFalse(condition.isReady)
        XCTAssertFalse(condition.suggestions.isEmpty)
    }

    func testPhotoCondition_isReady_blurry() {
        let condition = PhotoCondition(
            lighting: .optimal,
            faceDetected: true,
            faceAngle: FaceAngle(yaw: 0, pitch: 0, roll: 0),
            faceDistance: .optimal,
            faceCentering: .optimal,
            sharpness: .blurry
        )
        XCTAssertFalse(condition.isReady)
        XCTAssertFalse(condition.suggestions.isEmpty)
    }

    func testPhotoCondition_isReady_offCenter() {
        let condition = PhotoCondition(
            lighting: .optimal,
            faceDetected: true,
            faceAngle: FaceAngle(yaw: 0, pitch: 0, roll: 0),
            faceDistance: .optimal,
            faceCentering: .tooLeft,
            sharpness: .sharp
        )
        XCTAssertFalse(condition.isReady)
        XCTAssertFalse(condition.suggestions.isEmpty)
    }

    func testPhotoCondition_suggestions_includesAllIssues() {
        let condition = PhotoCondition(
            lighting: .tooDark,
            faceDetected: true,
            faceAngle: FaceAngle(yaw: 20, pitch: 0, roll: 0),
            faceDistance: .tooFar,
            faceCentering: .tooLeft,
            sharpness: .blurry
        )
        XCTAssertFalse(condition.isReady)
        // Should have 5 suggestions: lighting, angle, distance, centering, sharpness
        XCTAssertEqual(condition.suggestions.count, 5)
    }

    // MARK: - PhotoStandardizationMetadata Rating Tests

    func testCenteringRating_fromCondition() {
        XCTAssertEqual(
            PhotoStandardizationMetadata.CenteringRating(from: .optimal),
            .optimal
        )
        XCTAssertEqual(
            PhotoStandardizationMetadata.CenteringRating(from: .tooLeft),
            .tooLeft
        )
        XCTAssertEqual(
            PhotoStandardizationMetadata.CenteringRating(from: .tooRight),
            .tooRight
        )
        XCTAssertEqual(
            PhotoStandardizationMetadata.CenteringRating(from: .tooHigh),
            .tooHigh
        )
        XCTAssertEqual(
            PhotoStandardizationMetadata.CenteringRating(from: .tooLow),
            .tooLow
        )
        XCTAssertEqual(
            PhotoStandardizationMetadata.CenteringRating(from: .unknown),
            .optimal
        )
    }

    func testSharpnessRating_fromCondition() {
        XCTAssertEqual(
            PhotoStandardizationMetadata.SharpnessRating(from: .sharp),
            .sharp
        )
        XCTAssertEqual(
            PhotoStandardizationMetadata.SharpnessRating(from: .slightlyBlurry),
            .slightlyBlurry
        )
        XCTAssertEqual(
            PhotoStandardizationMetadata.SharpnessRating(from: .blurry),
            .blurry
        )
        XCTAssertEqual(
            PhotoStandardizationMetadata.SharpnessRating(from: .unknown),
            .sharp
        )
    }

    // MARK: - ReliabilityMetadata Reason Tests

    func testReliabilityMetadata_reasonDescriptions_includesNewReasons() {
        let metadata = ReliabilityMetadata(
            score: 0.5,
            level: .medium,
            reasons: [.centeringOff, .blurry]
        )

        let descriptions = metadata.reasonDescriptions()
        XCTAssertEqual(descriptions.count, 2)

        let reasonStrings = descriptions.map { $0.description }
        XCTAssertTrue(reasonStrings.contains("面部偏离中心"))
        XCTAssertTrue(reasonStrings.contains("图像模糊"))
    }
}
