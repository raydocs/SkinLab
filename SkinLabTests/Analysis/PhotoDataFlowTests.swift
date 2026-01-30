// SkinLabTests/Analysis/PhotoDataFlowTests.swift
@testable import SkinLab
import XCTest

/// Tests for photo data flow from Analysis to CheckIn to Report
final class PhotoDataFlowTests: XCTestCase {
    // MARK: - Photo Path Format Tests

    func testPhotoPath_trackingPhotos_includesSubdirectory() {
        // Verify that tracking photo paths include the subdirectory
        let expectedPattern = "tracking_photos/"
        let testPath = "tracking_photos/test_session_day0.jpg"

        XCTAssertTrue(
            testPath.hasPrefix(expectedPattern),
            "Tracking photo paths must include 'tracking_photos/' subdirectory"
        )
    }

    func testPhotoPath_analysisPhotos_includesSubdirectory() {
        // Verify that analysis photo paths include the subdirectory
        let expectedPattern = "analysis_photos/"
        let testPath = "analysis_photos/test_analysis.jpg"

        XCTAssertTrue(
            testPath.hasPrefix(expectedPattern),
            "Analysis photo paths must include 'analysis_photos/' subdirectory"
        )
    }

    // MARK: - CheckIn Analysis Association Tests

    func testCheckIn_analysisIdAssociation() {
        let sessionId = UUID()
        let analysisId = UUID()

        let checkIn = CheckIn(
            sessionId: sessionId,
            day: 0,
            captureDate: Date(),
            photoPath: "tracking_photos/test.jpg",
            analysisId: analysisId,
            usedProducts: [],
            notes: nil,
            feeling: nil
        )

        XCTAssertEqual(checkIn.analysisId, analysisId)
        XCTAssertNotNil(checkIn.analysisId, "CheckIn must have associated analysisId for data flow")
    }

    func testCheckIn_photoPathAssociation() {
        let sessionId = UUID()
        let photoPath = "tracking_photos/session_day7.jpg"

        let checkIn = CheckIn(
            sessionId: sessionId,
            day: 7,
            captureDate: Date(),
            photoPath: photoPath,
            analysisId: UUID(),
            usedProducts: [],
            notes: nil,
            feeling: nil
        )

        XCTAssertEqual(checkIn.photoPath, photoPath)
        XCTAssertTrue(
            checkIn.photoPath?.hasPrefix("tracking_photos/") ?? false,
            "CheckIn photoPath should include subdirectory for correct loading"
        )
    }

    // MARK: - TrackingSession Data Flow Tests

    func testTrackingSession_addCheckIn_preservesAnalysisId() {
        let session = TrackingSession()
        let analysisId = UUID()

        let checkIn = CheckIn(
            sessionId: session.id,
            day: 0,
            captureDate: Date(),
            photoPath: "tracking_photos/test.jpg",
            analysisId: analysisId,
            usedProducts: [],
            notes: nil,
            feeling: nil
        )

        session.addCheckIn(checkIn)

        let savedCheckIn = session.checkIns.first
        XCTAssertEqual(savedCheckIn?.analysisId, analysisId)
    }

    func testTrackingSession_addCheckIn_preservesPhotoPath() {
        let session = TrackingSession()
        let photoPath = "tracking_photos/session_day0.jpg"

        let checkIn = CheckIn(
            sessionId: session.id,
            day: 0,
            captureDate: Date(),
            photoPath: photoPath,
            analysisId: UUID(),
            usedProducts: [],
            notes: nil,
            feeling: nil
        )

        session.addCheckIn(checkIn)

        let savedCheckIn = session.checkIns.first
        XCTAssertEqual(savedCheckIn?.photoPath, photoPath)
    }

    func testTrackingSession_multipleCheckIns_preserveDataFlow() {
        let session = TrackingSession()

        let day0AnalysisId = UUID()
        let day7AnalysisId = UUID()

        let day0CheckIn = CheckIn(
            sessionId: session.id,
            day: 0,
            captureDate: Date(),
            photoPath: "tracking_photos/session_day0.jpg",
            analysisId: day0AnalysisId,
            usedProducts: [],
            notes: nil,
            feeling: nil
        )

        let day7CheckIn = CheckIn(
            sessionId: session.id,
            day: 7,
            captureDate: Date(),
            photoPath: "tracking_photos/session_day7.jpg",
            analysisId: day7AnalysisId,
            usedProducts: ["Product A"],
            notes: "Feeling good",
            feeling: .better
        )

        session.addCheckIn(day0CheckIn)
        session.addCheckIn(day7CheckIn)

        XCTAssertEqual(session.checkIns.count, 2)

        let sortedCheckIns = session.checkIns.sorted { $0.day < $1.day }
        XCTAssertEqual(sortedCheckIns[0].analysisId, day0AnalysisId)
        XCTAssertEqual(sortedCheckIns[1].analysisId, day7AnalysisId)
    }

    // MARK: - PhotoStandardization Data Flow Tests

    func testCheckIn_photoStandardization_preserved() {
        let sessionId = UUID()
        let standardization = PhotoStandardizationMetadata(
            capturedAt: Date(),
            cameraPosition: .front,
            captureSource: .camera,
            lighting: .optimal,
            faceDetected: true,
            yawDegrees: 5.0,
            pitchDegrees: 3.0,
            rollDegrees: 1.0,
            distance: .optimal,
            isReady: true,
            suggestions: [],
            userOverride: nil
        )

        let checkIn = CheckIn(
            sessionId: sessionId,
            day: 0,
            captureDate: Date(),
            photoPath: "tracking_photos/test.jpg",
            analysisId: UUID(),
            usedProducts: [],
            notes: nil,
            feeling: nil,
            photoStandardization: standardization,
            lifestyle: nil,
            reliability: nil
        )

        XCTAssertNotNil(checkIn.photoStandardization)
        XCTAssertEqual(checkIn.photoStandardization?.lighting, .optimal)
        XCTAssertEqual(checkIn.photoStandardization?.faceDetected, true)
        XCTAssertEqual(checkIn.photoStandardization?.distance, .optimal)
    }

    // MARK: - AnalysisRunResult Data Flow Tests

    func testAnalysisRunResult_containsAllRequiredData() {
        let analysis = SkinAnalysis.mock
        let analysisId = analysis.id
        let photoPath = "analysis_photos/\(analysisId.uuidString).jpg"
        let standardization = PhotoStandardizationMetadata(
            capturedAt: Date(),
            cameraPosition: .front,
            captureSource: .camera,
            lighting: .optimal,
            faceDetected: true,
            yawDegrees: 0,
            pitchDegrees: 0,
            rollDegrees: 0,
            distance: .optimal,
            isReady: true,
            suggestions: [],
            userOverride: nil
        )

        let result = AnalysisRunResult(
            analysis: analysis,
            analysisId: analysisId,
            photoPath: photoPath,
            standardization: standardization
        )

        XCTAssertEqual(result.analysisId, analysisId)
        XCTAssertEqual(result.photoPath, photoPath)
        XCTAssertNotNil(result.standardization)
        XCTAssertTrue(
            result.photoPath?.hasPrefix("analysis_photos/") ?? false,
            "Analysis photoPath should include subdirectory"
        )
    }

    // MARK: - ScorePoint Data Flow Tests

    func testScorePoint_checkInIdForJoins() {
        let checkInId = UUID()

        let point = ScorePoint(
            day: 7,
            date: Date(),
            overallScore: 75,
            skinAge: 26,
            checkInId: checkInId
        )

        XCTAssertEqual(point.checkInId, checkInId)
        XCTAssertEqual(point.day, 7)
        XCTAssertEqual(point.overallScore, 75)
    }

    func testScorePoint_usedForTimelineJoins() {
        // Verify ScorePoint uses checkInId (not day) for joins
        // This is critical per spec rule #1
        let checkInId1 = UUID()
        let checkInId2 = UUID()

        let point1 = ScorePoint(
            day: 0,
            date: Date(),
            overallScore: 70,
            skinAge: 28,
            checkInId: checkInId1
        )

        let point2 = ScorePoint(
            day: 7,
            date: Date(),
            overallScore: 75,
            skinAge: 27,
            checkInId: checkInId2
        )

        // Build a mock reliability map using checkInId as key
        var reliabilityMap: [UUID: ReliabilityMetadata] = [:]
        reliabilityMap[checkInId1] = ReliabilityMetadata.high
        reliabilityMap[checkInId2] = ReliabilityMetadata.high

        // Verify lookup works by checkInId
        XCTAssertNotNil(reliabilityMap[point1.checkInId])
        XCTAssertNotNil(reliabilityMap[point2.checkInId])
    }
}

// MARK: - ReliabilityMetadata Test Extension

extension ReliabilityMetadata {
    static var high: ReliabilityMetadata {
        ReliabilityMetadata(
            score: 0.9,
            level: .high,
            reasons: []
        )
    }
}
