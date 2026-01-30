import CoreImage
import UIKit
import Vision

// MARK: - Photo Quality Report

struct PhotoQualityReport: Codable, Equatable, Sendable {
    let overallScore: Int
    let blurScore: Int
    let brightnessScore: Int
    let faceDetectionScore: Int
    let issues: [QualityIssue]
    let isAcceptable: Bool
    let evaluatedAt: Date

    init(
        overallScore: Int,
        blurScore: Int,
        brightnessScore: Int,
        faceDetectionScore: Int,
        issues: [QualityIssue],
        evaluatedAt: Date = Date()
    ) {
        self.overallScore = overallScore
        self.blurScore = blurScore
        self.brightnessScore = brightnessScore
        self.faceDetectionScore = faceDetectionScore
        self.issues = issues
        self.evaluatedAt = evaluatedAt
        self.isAcceptable = overallScore >= 60 && !issues.contains { $0.severity == .critical }
    }

    static let unknown = PhotoQualityReport(
        overallScore: 0,
        blurScore: 0,
        brightnessScore: 0,
        faceDetectionScore: 0,
        issues: [.unknown]
    )
}

// MARK: - Quality Issue

enum QualityIssue: String, Codable, Equatable, Sendable, CaseIterable {
    case tooBlurry
    case slightlyBlurry
    case tooDark
    case tooBright
    case unevenLighting
    case noFaceDetected
    case faceTooSmall
    case faceTooLarge
    case faceNotCentered
    case multipleFaces
    case facePartiallyVisible
    case unknown

    var displayName: String {
        switch self {
        case .tooBlurry: "图像模糊"
        case .slightlyBlurry: "图像略微模糊"
        case .tooDark: "光线太暗"
        case .tooBright: "光线太亮"
        case .unevenLighting: "光线不均匀"
        case .noFaceDetected: "未检测到面部"
        case .faceTooSmall: "面部太远"
        case .faceTooLarge: "面部太近"
        case .faceNotCentered: "面部未居中"
        case .multipleFaces: "检测到多张面孔"
        case .facePartiallyVisible: "面部不完整"
        case .unknown: "无法评估"
        }
    }

    var suggestion: String {
        switch self {
        case .tooBlurry: "请保持手机稳定后重拍"
        case .slightlyBlurry: "建议保持稳定以获得更清晰的照片"
        case .tooDark: "请移至光线充足的地方"
        case .tooBright: "请避免直射光线"
        case .unevenLighting: "请调整位置使面部光线均匀"
        case .noFaceDetected: "请确保面部在取景框内"
        case .faceTooSmall: "请靠近相机"
        case .faceTooLarge: "请稍微远离相机"
        case .faceNotCentered: "请将面部移至画面中央"
        case .multipleFaces: "请确保只有一张面孔在画面中"
        case .facePartiallyVisible: "请确保整张脸在画面内"
        case .unknown: "请重新拍照"
        }
    }

    var severity: IssueSeverity {
        switch self {
        case .tooBlurry, .noFaceDetected, .facePartiallyVisible:
            .critical
        case .tooDark, .tooBright, .faceTooSmall, .faceTooLarge, .multipleFaces:
            .warning
        case .slightlyBlurry, .unevenLighting, .faceNotCentered:
            .minor
        case .unknown:
            .critical
        }
    }

    var icon: String {
        switch self {
        case .tooBlurry, .slightlyBlurry: "camera.metering.none"
        case .tooDark: "sun.min"
        case .tooBright: "sun.max.fill"
        case .unevenLighting: "sun.haze"
        case .noFaceDetected, .facePartiallyVisible: "person.crop.circle.badge.questionmark"
        case .faceTooSmall: "arrow.up.left.and.arrow.down.right"
        case .faceTooLarge: "arrow.down.right.and.arrow.up.left"
        case .faceNotCentered: "viewfinder"
        case .multipleFaces: "person.2"
        case .unknown: "questionmark.circle"
        }
    }
}

enum IssueSeverity: String, Codable, Sendable {
    case critical
    case warning
    case minor
}

// MARK: - Photo Quality Evaluator

actor PhotoQualityEvaluator {
    private static let sharedCIContext: CIContext = {
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            return CIContext(mtlDevice: metalDevice, options: [.cacheIntermediates: false])
        }
        return CIContext(options: [.useSoftwareRenderer: false, .cacheIntermediates: false])
    }()

    // MARK: - Main Evaluation

    func evaluate(image: UIImage) async -> PhotoQualityReport {
        guard let cgImage = image.cgImage else {
            return .unknown
        }

        let ciImage = CIImage(cgImage: cgImage)

        async let blurResult = evaluateBlur(cgImage: cgImage)
        async let brightnessResult = evaluateBrightness(ciImage: ciImage, cgImage: cgImage)
        async let faceResult = evaluateFaceDetection(cgImage: cgImage, imageOrientation: image.imageOrientation)

        let blur = await blurResult
        let brightness = await brightnessResult
        let face = await faceResult

        var issues: [QualityIssue] = []
        issues.append(contentsOf: blur.issues)
        issues.append(contentsOf: brightness.issues)
        issues.append(contentsOf: face.issues)

        let overallScore = calculateOverallScore(
            blurScore: blur.score,
            brightnessScore: brightness.score,
            faceScore: face.score
        )

        return PhotoQualityReport(
            overallScore: overallScore,
            blurScore: blur.score,
            brightnessScore: brightness.score,
            faceDetectionScore: face.score,
            issues: issues
        )
    }

    // MARK: - Blur Evaluation (Laplacian Variance)

    private func evaluateBlur(cgImage: CGImage) -> (score: Int, issues: [QualityIssue]) {
        let width = cgImage.width
        let height = cgImage.height

        guard width > 10, height > 10,
              let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            return (0, [.unknown])
        }

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let dataLength = CFDataGetLength(data)

        var laplacianValues: [Double] = []
        let step = 5

        for y in stride(from: 1, to: height - 1, by: step) {
            for x in stride(from: 1, to: width - 1, by: step) {
                func grayscale(atX px: Int, atY py: Int) -> Double {
                    let offset = (py * bytesPerRow) + (px * bytesPerPixel)
                    guard offset + 2 < dataLength else { return 0 }
                    let r = Double(bytes[offset])
                    let g = Double(bytes[offset + 1])
                    let b = Double(bytes[offset + 2])
                    return 0.299 * r + 0.587 * g + 0.114 * b
                }

                let center = grayscale(atX: x, atY: y)
                let top = grayscale(atX: x, atY: y - 1)
                let bottom = grayscale(atX: x, atY: y + 1)
                let left = grayscale(atX: x - 1, atY: y)
                let right = grayscale(atX: x + 1, atY: y)

                let laplacian = top + bottom + left + right - 4 * center
                laplacianValues.append(laplacian)
            }
        }

        guard !laplacianValues.isEmpty else {
            return (0, [.unknown])
        }

        let mean = laplacianValues.reduce(0, +) / Double(laplacianValues.count)
        let variance = laplacianValues.reduce(0) { $0 + pow($1 - mean, 2) } / Double(laplacianValues.count)

        let score: Int
        var issues: [QualityIssue] = []

        switch variance {
        case ..<50:
            score = 30
            issues.append(.tooBlurry)
        case 50 ..< 100:
            score = 60
            issues.append(.slightlyBlurry)
        case 100 ..< 200:
            score = 80
        default:
            score = 100
        }

        return (score, issues)
    }

    // MARK: - Brightness Evaluation

    private func evaluateBrightness(ciImage: CIImage, cgImage: CGImage) -> (score: Int, issues: [QualityIssue]) {
        if let avgBrightness = averageBrightness(ciImage: ciImage) {
            return evaluateBrightnessValue(avgBrightness)
        }

        if let avgBrightness = calculateBrightnessFromCGImage(cgImage) {
            return evaluateBrightnessValue(avgBrightness)
        }

        return (50, [.unknown])
    }

    private func evaluateBrightnessValue(_ brightness: Double) -> (score: Int, issues: [QualityIssue]) {
        var issues: [QualityIssue] = []
        let score: Int

        switch brightness {
        case ..<0.15:
            score = 30
            issues.append(.tooDark)
        case 0.15 ..< 0.25:
            score = 60
            issues.append(.tooDark)
        case 0.25 ..< 0.40:
            score = 85
        case 0.40 ..< 0.60:
            score = 100
        case 0.60 ..< 0.75:
            score = 85
        case 0.75 ..< 0.85:
            score = 60
            issues.append(.tooBright)
        default:
            score = 30
            issues.append(.tooBright)
        }

        return (score, issues)
    }

    private func averageBrightness(ciImage: CIImage) -> Double? {
        let extent = ciImage.extent
        guard extent.width > 0, extent.height > 0 else { return nil }

        guard let filter = CIFilter(name: "CIAreaAverage") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)

        guard let outputImage = filter.outputImage else { return nil }

        var pixel = [UInt8](repeating: 0, count: 4)
        Self.sharedCIContext.render(
            outputImage,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        let r = Double(pixel[0])
        let g = Double(pixel[1])
        let b = Double(pixel[2])
        return (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
    }

    private func calculateBrightnessFromCGImage(_ cgImage: CGImage) -> Double? {
        let width = cgImage.width
        let height = cgImage.height

        guard let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            return nil
        }

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let totalBytes = bytesPerRow * height
        let step = 10

        var totalBrightness: Double = 0
        var sampleCount: Double = 0

        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                guard offset + 2 < totalBytes else { continue }

                let r = Double(bytes[offset])
                let g = Double(bytes[offset + 1])
                let b = Double(bytes[offset + 2])

                let brightness = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
                totalBrightness += brightness
                sampleCount += 1
            }
        }

        guard sampleCount > 0 else { return nil }
        return totalBrightness / sampleCount
    }

    // MARK: - Face Detection Evaluation

    private func evaluateFaceDetection(
        cgImage: CGImage,
        imageOrientation: UIImage.Orientation
    ) -> (score: Int, issues: [QualityIssue]) {
        let orientation = visionOrientation(from: imageOrientation)
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return (0, [.noFaceDetected])
        }

        guard let results = request.results, !results.isEmpty else {
            return (0, [.noFaceDetected])
        }

        var issues: [QualityIssue] = []
        var score = 100

        if results.count > 1 {
            issues.append(.multipleFaces)
            score -= 20
        }

        guard let face = results.first else {
            return (0, [.noFaceDetected])
        }

        let faceArea = face.boundingBox.width * face.boundingBox.height

        switch faceArea {
        case ..<0.03:
            issues.append(.faceTooSmall)
            score -= 40
        case 0.03 ..< 0.08:
            issues.append(.faceTooSmall)
            score -= 20
        case 0.08 ..< 0.35:
            break
        case 0.35 ..< 0.50:
            issues.append(.faceTooLarge)
            score -= 20
        default:
            issues.append(.faceTooLarge)
            score -= 40
        }

        let faceCenter = CGPoint(
            x: face.boundingBox.midX,
            y: face.boundingBox.midY
        )

        let centerDeviation = sqrt(
            pow(faceCenter.x - 0.5, 2) + pow(faceCenter.y - 0.5, 2)
        )

        if centerDeviation > 0.25 {
            issues.append(.faceNotCentered)
            score -= 15
        }

        let boundingBox = face.boundingBox
        if boundingBox.minX < 0.02 || boundingBox.maxX > 0.98 ||
            boundingBox.minY < 0.02 || boundingBox.maxY > 0.98 {
            issues.append(.facePartiallyVisible)
            score -= 30
        }

        return (max(0, score), issues)
    }

    private func visionOrientation(from imageOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }

    // MARK: - Overall Score Calculation

    private func calculateOverallScore(
        blurScore: Int,
        brightnessScore: Int,
        faceScore: Int
    ) -> Int {
        let blurWeight = 0.35
        let brightnessWeight = 0.25
        let faceWeight = 0.40

        let weightedScore = Double(blurScore) * blurWeight +
            Double(brightnessScore) * brightnessWeight +
            Double(faceScore) * faceWeight

        return Int(weightedScore.rounded())
    }
}

// MARK: - PhotoQualityReport Extension

extension PhotoQualityReport {
    var criticalIssues: [QualityIssue] {
        issues.filter { $0.severity == .critical }
    }

    var warningIssues: [QualityIssue] {
        issues.filter { $0.severity == .warning }
    }

    var minorIssues: [QualityIssue] {
        issues.filter { $0.severity == .minor }
    }

    var primarySuggestion: String? {
        if let critical = criticalIssues.first {
            return critical.suggestion
        }
        if let warning = warningIssues.first {
            return warning.suggestion
        }
        return minorIssues.first?.suggestion
    }

    var qualityLevel: QualityLevel {
        switch overallScore {
        case 80...: .excellent
        case 60 ..< 80: .good
        case 40 ..< 60: .fair
        default: .poor
        }
    }
}

enum QualityLevel: String, Sendable {
    case excellent
    case good
    case fair
    case poor

    var displayName: String {
        switch self {
        case .excellent: "优秀"
        case .good: "良好"
        case .fair: "一般"
        case .poor: "较差"
        }
    }

    var color: String {
        switch self {
        case .excellent: "green"
        case .good: "blue"
        case .fair: "orange"
        case .poor: "red"
        }
    }
}
