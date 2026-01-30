@testable import SkinLab
import XCTest

final class PhotoQualityEvaluatorTests: XCTestCase {
    var evaluator: PhotoQualityEvaluator!

    override func setUp() async throws {
        try await super.setUp()
        evaluator = PhotoQualityEvaluator()
    }

    override func tearDown() async throws {
        evaluator = nil
        try await super.tearDown()
    }

    // MARK: - Quality Report Model Tests

    func testPhotoQualityReportIsAcceptable() {
        let goodReport = PhotoQualityReport(
            overallScore: 80,
            blurScore: 85,
            brightnessScore: 90,
            faceDetectionScore: 75,
            issues: [.slightlyBlurry]
        )
        XCTAssertTrue(goodReport.isAcceptable)

        let poorReport = PhotoQualityReport(
            overallScore: 40,
            blurScore: 30,
            brightnessScore: 50,
            faceDetectionScore: 40,
            issues: [.tooBlurry]
        )
        XCTAssertFalse(poorReport.isAcceptable)
    }

    func testPhotoQualityReportCriticalIssue() {
        let criticalReport = PhotoQualityReport(
            overallScore: 70,
            blurScore: 70,
            brightnessScore: 80,
            faceDetectionScore: 0,
            issues: [.noFaceDetected]
        )
        XCTAssertFalse(criticalReport.isAcceptable)
    }

    func testQualityIssueProperties() {
        XCTAssertEqual(QualityIssue.tooBlurry.severity, .critical)
        XCTAssertEqual(QualityIssue.slightlyBlurry.severity, .minor)
        XCTAssertEqual(QualityIssue.tooDark.severity, .warning)
        XCTAssertEqual(QualityIssue.noFaceDetected.severity, .critical)
        XCTAssertEqual(QualityIssue.faceNotCentered.severity, .minor)

        XCTAssertFalse(QualityIssue.tooBlurry.displayName.isEmpty)
        XCTAssertFalse(QualityIssue.tooBlurry.suggestion.isEmpty)
        XCTAssertFalse(QualityIssue.tooBlurry.icon.isEmpty)
    }

    func testQualityLevelFromScore() {
        let excellent = PhotoQualityReport(
            overallScore: 90,
            blurScore: 90,
            brightnessScore: 90,
            faceDetectionScore: 90,
            issues: []
        )
        XCTAssertEqual(excellent.qualityLevel, .excellent)

        let good = PhotoQualityReport(
            overallScore: 70,
            blurScore: 70,
            brightnessScore: 70,
            faceDetectionScore: 70,
            issues: []
        )
        XCTAssertEqual(good.qualityLevel, .good)

        let fair = PhotoQualityReport(
            overallScore: 50,
            blurScore: 50,
            brightnessScore: 50,
            faceDetectionScore: 50,
            issues: []
        )
        XCTAssertEqual(fair.qualityLevel, .fair)

        let poor = PhotoQualityReport(
            overallScore: 30,
            blurScore: 30,
            brightnessScore: 30,
            faceDetectionScore: 30,
            issues: []
        )
        XCTAssertEqual(poor.qualityLevel, .poor)
    }

    func testPrimarySuggestion() {
        let criticalFirst = PhotoQualityReport(
            overallScore: 50,
            blurScore: 30,
            brightnessScore: 60,
            faceDetectionScore: 80,
            issues: [.slightlyBlurry, .tooBlurry, .tooDark]
        )
        XCTAssertEqual(criticalFirst.primarySuggestion, QualityIssue.tooBlurry.suggestion)

        let warningOnly = PhotoQualityReport(
            overallScore: 60,
            blurScore: 70,
            brightnessScore: 50,
            faceDetectionScore: 80,
            issues: [.tooDark]
        )
        XCTAssertEqual(warningOnly.primarySuggestion, QualityIssue.tooDark.suggestion)

        let noIssues = PhotoQualityReport(
            overallScore: 90,
            blurScore: 90,
            brightnessScore: 90,
            faceDetectionScore: 90,
            issues: []
        )
        XCTAssertNil(noIssues.primarySuggestion)
    }

    func testIssueFiltering() {
        let mixedReport = PhotoQualityReport(
            overallScore: 50,
            blurScore: 50,
            brightnessScore: 50,
            faceDetectionScore: 50,
            issues: [.tooBlurry, .tooDark, .slightlyBlurry, .faceNotCentered]
        )

        XCTAssertEqual(mixedReport.criticalIssues, [.tooBlurry])
        XCTAssertEqual(mixedReport.warningIssues, [.tooDark])
        XCTAssertEqual(mixedReport.minorIssues.count, 2)
    }

    // MARK: - Image Evaluation Tests

    func testEvaluateValidImage() async {
        let image = createTestImage(size: CGSize(width: 500, height: 500), withPattern: true)

        let report = await evaluator.evaluate(image: image)

        XCTAssertGreaterThan(report.blurScore, 0)
        XCTAssertGreaterThan(report.brightnessScore, 0)
    }

    func testEvaluateDarkImage() async {
        let image = createTestImage(
            size: CGSize(width: 500, height: 500),
            color: UIColor(white: 0.1, alpha: 1.0)
        )

        let report = await evaluator.evaluate(image: image)

        XCTAssertLessThan(report.brightnessScore, 60)
        XCTAssertTrue(report.issues.contains(.tooDark))
    }

    func testEvaluateBrightImage() async {
        let image = createTestImage(
            size: CGSize(width: 500, height: 500),
            color: UIColor(white: 0.95, alpha: 1.0)
        )

        let report = await evaluator.evaluate(image: image)

        XCTAssertLessThan(report.brightnessScore, 60)
        XCTAssertTrue(report.issues.contains(.tooBright))
    }

    func testEvaluateImageWithOptimalBrightness() async {
        let image = createTestImage(
            size: CGSize(width: 500, height: 500),
            color: UIColor(white: 0.5, alpha: 1.0)
        )

        let report = await evaluator.evaluate(image: image)

        XCTAssertGreaterThanOrEqual(report.brightnessScore, 85)
        XCTAssertFalse(report.issues.contains(.tooDark))
        XCTAssertFalse(report.issues.contains(.tooBright))
    }

    func testNoFaceDetectedInSolidImage() async {
        let image = createTestImage(
            size: CGSize(width: 500, height: 500),
            color: .blue
        )

        let report = await evaluator.evaluate(image: image)

        XCTAssertEqual(report.faceDetectionScore, 0)
        XCTAssertTrue(report.issues.contains(.noFaceDetected))
    }

    // MARK: - Quality Level Tests

    func testQualityLevelDisplayName() {
        XCTAssertEqual(QualityLevel.excellent.displayName, "优秀")
        XCTAssertEqual(QualityLevel.good.displayName, "良好")
        XCTAssertEqual(QualityLevel.fair.displayName, "一般")
        XCTAssertEqual(QualityLevel.poor.displayName, "较差")
    }

    func testQualityLevelColor() {
        XCTAssertEqual(QualityLevel.excellent.color, "green")
        XCTAssertEqual(QualityLevel.good.color, "blue")
        XCTAssertEqual(QualityLevel.fair.color, "orange")
        XCTAssertEqual(QualityLevel.poor.color, "red")
    }

    // MARK: - Issue Severity Tests

    func testAllIssuesHaveDisplayNames() {
        for issue in QualityIssue.allCases {
            XCTAssertFalse(issue.displayName.isEmpty, "\(issue) should have display name")
        }
    }

    func testAllIssuesHaveSuggestions() {
        for issue in QualityIssue.allCases {
            XCTAssertFalse(issue.suggestion.isEmpty, "\(issue) should have suggestion")
        }
    }

    func testAllIssuesHaveIcons() {
        for issue in QualityIssue.allCases {
            XCTAssertFalse(issue.icon.isEmpty, "\(issue) should have icon")
        }
    }

    // MARK: - Unknown Report Tests

    func testUnknownReport() {
        let unknown = PhotoQualityReport.unknown

        XCTAssertEqual(unknown.overallScore, 0)
        XCTAssertEqual(unknown.blurScore, 0)
        XCTAssertEqual(unknown.brightnessScore, 0)
        XCTAssertEqual(unknown.faceDetectionScore, 0)
        XCTAssertTrue(unknown.issues.contains(.unknown))
        XCTAssertFalse(unknown.isAcceptable)
    }

    // MARK: - Codable Tests

    func testPhotoQualityReportCodable() throws {
        let report = PhotoQualityReport(
            overallScore: 75,
            blurScore: 80,
            brightnessScore: 70,
            faceDetectionScore: 75,
            issues: [.slightlyBlurry, .faceNotCentered]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(report)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PhotoQualityReport.self, from: data)

        XCTAssertEqual(report.overallScore, decoded.overallScore)
        XCTAssertEqual(report.blurScore, decoded.blurScore)
        XCTAssertEqual(report.brightnessScore, decoded.brightnessScore)
        XCTAssertEqual(report.faceDetectionScore, decoded.faceDetectionScore)
        XCTAssertEqual(report.issues, decoded.issues)
        XCTAssertEqual(report.isAcceptable, decoded.isAcceptable)
    }

    // MARK: - Blur Detection Tests

    func testBlurryImageDetection() async {
        let blurryImage = createBlurryImage(size: CGSize(width: 500, height: 500))

        let report = await evaluator.evaluate(image: blurryImage)

        XCTAssertGreaterThan(report.blurScore, 0)
    }

    func testSharpImageDetection() async {
        let sharpImage = createSharpImage(size: CGSize(width: 500, height: 500))

        let report = await evaluator.evaluate(image: sharpImage)

        XCTAssertGreaterThanOrEqual(report.blurScore, 60)
    }

    func testSharpImageHasHigherScoreThanUniformImage() async {
        let sharpImage = createSharpImage(size: CGSize(width: 500, height: 500))
        let uniformImage = createTestImage(size: CGSize(width: 500, height: 500), color: .gray)

        let sharpReport = await evaluator.evaluate(image: sharpImage)
        let uniformReport = await evaluator.evaluate(image: uniformImage)

        XCTAssertGreaterThanOrEqual(sharpReport.blurScore, uniformReport.blurScore)
    }

    // MARK: - Helpers

    private func createTestImage(
        size: CGSize,
        color: UIColor = .gray,
        withPattern: Bool = false
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            if withPattern {
                UIColor.white.setStroke()
                for i in stride(from: 0, to: size.width, by: 20) {
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: i, y: 0))
                    path.addLine(to: CGPoint(x: i, y: size.height))
                    path.lineWidth = 2
                    path.stroke()
                }
            }
        }
    }

    private func createBlurryImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.gray.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIColor(white: 0.45, alpha: 1.0).setFill()
            let rect = CGRect(x: size.width / 4, y: size.height / 4, width: size.width / 2, height: size.height / 2)
            context.fill(rect)
        }
    }

    private func createSharpImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIColor.black.setStroke()
            for i in stride(from: 0, to: Int(size.width), by: 5) {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: CGFloat(i), y: 0))
                path.addLine(to: CGPoint(x: CGFloat(i), y: size.height))
                path.lineWidth = 1
                path.stroke()
            }

            for i in stride(from: 0, to: Int(size.height), by: 5) {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: 0, y: CGFloat(i)))
                path.addLine(to: CGPoint(x: size.width, y: CGFloat(i)))
                path.lineWidth = 1
                path.stroke()
            }
        }
    }
}
