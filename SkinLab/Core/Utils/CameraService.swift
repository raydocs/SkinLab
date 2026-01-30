import AVFoundation
import CoreImage
import ImageIO
import Metal
import SwiftUI
import Vision

// MARK: - Camera Service

@MainActor
class CameraService: NSObject, ObservableObject {
    @Published var frame: CGImage?
    @Published var error: CameraError?
    @Published var photoCondition: PhotoCondition = .init()
    @Published var isReady = false

    private let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var videoInput: AVCaptureDeviceInput?
    private var currentPosition: AVCaptureDevice.Position = .front
    private var photoContinuation: CheckedContinuation<UIImage, Error>?
    private var conditionWindow: [PhotoCondition] = []
    private let smoothingWindowSize = 5
    private let requiredStableFrames = 3

    private let videoQueue = DispatchQueue(label: "camera.video.queue")
    private let faceDetector = FaceDetector()
    private var lastFaceDetectionTime: CFAbsoluteTime = 0
    private let faceDetectionInterval: CFAbsoluteTime = 0.2 // 5fps throttle

    /// Read-only access to current camera position
    var activeCameraPosition: AVCaptureDevice.Position {
        currentPosition
    }

    /// Reuse CIContext for better performance
    private nonisolated static let sharedCIContext: CIContext = {
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            return CIContext(mtlDevice: metalDevice, options: [.cacheIntermediates: false])
        }
        return CIContext(options: [.useSoftwareRenderer: false, .cacheIntermediates: false])
    }()

    enum CameraError: LocalizedError, Equatable {
        case denied
        case unavailable
        case setupFailed(Error)
        case captureInProgress

        static func == (lhs: CameraError, rhs: CameraError) -> Bool {
            switch (lhs, rhs) {
            case (.denied, .denied), (.unavailable, .unavailable), (.captureInProgress, .captureInProgress):
                true
            case (.setupFailed, .setupFailed):
                true
            default:
                false
            }
        }

        var errorDescription: String? {
            switch self {
            case .denied: "相机权限被拒绝,请在设置中开启"
            case .unavailable: "相机不可用"
            case let .setupFailed(error): "相机初始化失败: \(error.localizedDescription)"
            case .captureInProgress: "正在拍照中,请稍候"
            }
        }
    }

    override init() {
        super.init()
    }

    // MARK: - Setup

    func checkPermission() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            await setupCamera()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                await setupCamera()
            } else {
                error = .denied
            }
        case .denied, .restricted:
            error = .denied
        @unknown default:
            error = .unavailable
        }
    }

    private func setupCamera() async {
        do {
            captureSession.beginConfiguration()
            captureSession.sessionPreset = .photo

            // Add video input
            try configureInput(position: currentPosition)

            // Add photo output
            if !captureSession.outputs.contains(where: { $0 === photoOutput }),
               captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }

            // Add video output for preview and face detection
            videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
            if !captureSession.outputs.contains(where: { $0 === videoOutput }),
               captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }

            // Set video orientation
            if let connection = videoOutput.connection(with: .video) {
                connection.videoRotationAngle = 90
                connection.isVideoMirrored = currentPosition == .front
            }

            captureSession.commitConfiguration()

            // Start session on background thread
            Task.detached { [weak self] in
                self?.captureSession.startRunning()
            }

            isReady = true
        } catch {
            self.error = .setupFailed(error)
        }
    }

    // MARK: - Camera Toggle

    func toggleCamera() {
        guard isReady else { return }
        let newPosition: AVCaptureDevice.Position = currentPosition == .front ? .back : .front
        do {
            captureSession.beginConfiguration()
            try configureInput(position: newPosition)
            if let connection = videoOutput.connection(with: .video) {
                connection.videoRotationAngle = 90
                connection.isVideoMirrored = newPosition == .front
            }
            captureSession.commitConfiguration()
        } catch {
            captureSession.commitConfiguration()
            self.error = .setupFailed(error)
        }
    }

    private func configureInput(position: AVCaptureDevice.Position) throws {
        if let currentInput = videoInput {
            captureSession.removeInput(currentInput)
        }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            throw CameraError.unavailable
        }

        let input = try AVCaptureDeviceInput(device: device)
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
            videoInput = input
            currentPosition = position
        } else {
            throw CameraError.unavailable
        }
    }

    // MARK: - Capture Photo

    func capturePhoto() async throws -> UIImage {
        // Prevent concurrent capture requests
        guard photoContinuation == nil else {
            throw CameraError.captureInProgress
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.photoContinuation = continuation

            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off

            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func validateCapturedImage(_ image: UIImage) async -> PhotoCondition? {
        guard let cgImage = image.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        let orientation = CameraService.visionOrientation(from: image.imageOrientation)
        return await faceDetector.analyze(
            cgImage: cgImage,
            ciImage: ciImage,
            orientation: orientation
        )
    }

    // MARK: - Stop

    func stop() {
        Task.detached { [weak self] in
            guard let self else { return }
            self.captureSession.stopRunning()

            // Remove all inputs and outputs
            for input in self.captureSession.inputs {
                self.captureSession.removeInput(input)
            }
            for output in self.captureSession.outputs {
                self.captureSession.removeOutput(output)
            }
        }
    }

    private func updatePhotoCondition(with condition: PhotoCondition) {
        conditionWindow.append(condition)
        if conditionWindow.count > smoothingWindowSize {
            conditionWindow.removeFirst(conditionWindow.count - smoothingWindowSize)
        }

        let smoothed = PhotoCondition.smoothed(
            from: conditionWindow,
            requiredStableFrames: requiredStableFrames
        )
        photoCondition = smoothed
    }

    private nonisolated static func visionOrientation(
        rotationAngle: Double,
        isMirrored: Bool
    ) -> CGImagePropertyOrientation {
        switch rotationAngle {
        case 90:
            isMirrored ? .leftMirrored : .right
        case 270:
            isMirrored ? .rightMirrored : .left
        case 180:
            isMirrored ? .downMirrored : .down
        default:
            isMirrored ? .upMirrored : .up
        }
    }

    private nonisolated static func visionOrientation(
        from imageOrientation: UIImage.Orientation
    ) -> CGImagePropertyOrientation {
        switch imageOrientation {
        case .up:
            return .up
        case .upMirrored:
            return .upMirrored
        case .down:
            return .down
        case .downMirrored:
            return .downMirrored
        case .left:
            return .left
        case .leftMirrored:
            return .leftMirrored
        case .right:
            return .right
        case .rightMirrored:
            return .rightMirrored
        @unknown default:
            return .right
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Create CGImage for preview using shared context
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = CameraService.sharedCIContext.createCGImage(ciImage, from: ciImage.extent) else { return }
        let orientation = CameraService.visionOrientation(
            rotationAngle: connection.videoRotationAngle,
            isMirrored: connection.isVideoMirrored
        )

        // Throttle face detection to improve performance
        let currentTime = CFAbsoluteTimeGetCurrent()

        Task { @MainActor [weak self] in
            guard let self else { return }
            // Always update frame for smooth preview
            self.frame = cgImage

            // Only run face detection at throttled interval
            if currentTime - self.lastFaceDetectionTime >= self.faceDetectionInterval {
                self.lastFaceDetectionTime = currentTime
                if let condition = await self.faceDetector.analyze(
                    cgImage: cgImage,
                    ciImage: ciImage,
                    orientation: orientation
                ) {
                    self.updatePhotoCondition(with: condition)
                }
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let error {
                photoContinuation?.resume(throwing: error)
                photoContinuation = nil
                return
            }

            guard let data = photo.fileDataRepresentation(),
                  let image = UIImage(data: data) else {
                photoContinuation?.resume(throwing: CameraError.unavailable)
                photoContinuation = nil
                return
            }

            photoContinuation?.resume(returning: image)
            photoContinuation = nil
        }
    }
}

// MARK: - Photo Condition

struct PhotoCondition {
    var lighting: LightingCondition = .unknown
    var faceDetected: Bool = false
    var faceAngle: FaceAngle = .init()
    var faceDistance: DistanceCondition = .unknown
    var faceCentering: CenteringCondition = .unknown
    var sharpness: SharpnessCondition = .unknown
    var stableReady: Bool = true

    var baseReady: Bool {
        faceDetected &&
            lighting.isAcceptable &&
            faceAngle.isOptimal &&
            faceDistance.isAcceptable &&
            faceCentering.isAcceptable &&
            sharpness.isAcceptable
    }

    var isReady: Bool {
        baseReady && stableReady
    }

    var suggestions: [String] {
        var result: [String] = []

        if !faceDetected {
            result.append("请将面部对准框内")
        }

        if let suggestion = lighting.suggestion {
            result.append(suggestion)
        }

        if let suggestion = faceAngle.suggestion {
            result.append(suggestion)
        }

        if let suggestion = faceDistance.suggestion {
            result.append(suggestion)
        }

        if let suggestion = faceCentering.suggestion {
            result.append(suggestion)
        }

        if let suggestion = sharpness.suggestion {
            result.append(suggestion)
        }

        if baseReady, !stableReady {
            result.append("请保持稳定")
        }

        return result
    }

    static func smoothed(from conditions: [PhotoCondition], requiredStableFrames: Int) -> PhotoCondition {
        guard let latest = conditions.last else { return PhotoCondition() }

        let faceDetectedValues = conditions.map(\.faceDetected)
        let faceDetectedCount = faceDetectedValues.filter { $0 }.count
        let faceDetected: Bool = if faceDetectedCount == conditions.count - faceDetectedCount {
            latest.faceDetected
        } else {
            faceDetectedCount > conditions.count - faceDetectedCount
        }

        let lighting = mode(conditions.map(\.lighting), fallback: latest.lighting)
        let faceDistance = mode(conditions.map(\.faceDistance), fallback: latest.faceDistance)
        let faceCentering = mode(conditions.map(\.faceCentering), fallback: latest.faceCentering)
        let sharpness = mode(conditions.map(\.sharpness), fallback: latest.sharpness)

        let yaw = average(conditions.map(\.faceAngle.yaw))
        let pitch = average(conditions.map(\.faceAngle.pitch))
        let roll = average(conditions.map(\.faceAngle.roll))

        let stableFrameCount = max(requiredStableFrames, 1)
        let stableWindow = conditions.suffix(stableFrameCount)
        let stableReady = conditions.count >= stableFrameCount && stableWindow.allSatisfy(\.baseReady)

        return PhotoCondition(
            lighting: lighting,
            faceDetected: faceDetected,
            faceAngle: FaceAngle(yaw: yaw, pitch: pitch, roll: roll),
            faceDistance: faceDistance,
            faceCentering: faceCentering,
            sharpness: sharpness,
            stableReady: stableReady
        )
    }

    private static func mode<T: Hashable>(_ values: [T], fallback: T) -> T {
        guard !values.isEmpty else { return fallback }
        var counts: [T: Int] = [:]
        for value in values {
            counts[value, default: 0] += 1
        }
        let maxCount = counts.values.max() ?? 0
        let modes = counts.filter { $0.value == maxCount }.map(\.key)
        if modes.count == 1, let mode = modes.first {
            return mode
        }
        return fallback
    }

    private static func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let total = values.reduce(0, +)
        return total / Double(values.count)
    }
}

enum LightingCondition {
    case unknown
    case tooDark
    case slightlyDark
    case optimal
    case slightlyBright
    case tooBright

    var isAcceptable: Bool {
        switch self {
        case .optimal, .slightlyDark, .slightlyBright:
            true
        default:
            false
        }
    }

    var suggestion: String? {
        switch self {
        case .tooDark: "光线不足，请移到更亮的地方"
        case .tooBright: "光线过强，请避开直射光"
        default: nil
        }
    }

    static func from(averageBrightness: Double) -> LightingCondition {
        switch averageBrightness {
        case ..<0.15:
            .tooDark
        case 0.15 ..< 0.30:
            .slightlyDark
        case 0.30 ..< 0.70:
            .optimal
        case 0.70 ..< 0.85:
            .slightlyBright
        default:
            .tooBright
        }
    }
}

struct FaceAngle {
    var yaw: Double = 0 // 左右转头
    var pitch: Double = 0 // 上下点头
    var roll: Double = 0 // 歪头

    var isOptimal: Bool {
        abs(yaw) < 15 && abs(pitch) < 15 && abs(roll) < 10
    }

    var suggestion: String? {
        if abs(yaw) >= 15 {
            return yaw > 0 ? "请稍微向左转" : "请稍微向右转"
        }
        if abs(pitch) >= 15 {
            return pitch > 0 ? "请稍微低头" : "请稍微抬头"
        }
        if abs(roll) >= 10 {
            return "请保持头部端正"
        }
        return nil
    }
}

enum DistanceCondition {
    case unknown
    case tooFar
    case slightlyFar
    case optimal
    case slightlyClose
    case tooClose

    var isAcceptable: Bool {
        switch self {
        case .optimal, .slightlyFar, .slightlyClose:
            true
        default:
            false
        }
    }

    var suggestion: String? {
        switch self {
        case .tooFar: "请靠近一些"
        case .tooClose: "请稍微远一点"
        default: nil
        }
    }
}

// MARK: - Centering Condition

enum CenteringCondition {
    case unknown
    case tooLeft
    case tooRight
    case tooHigh
    case tooLow
    case optimal

    var isAcceptable: Bool {
        self == .optimal || self == .unknown
    }

    var suggestion: String? {
        switch self {
        case .tooLeft: "请稍微向右移动"
        case .tooRight: "请稍微向左移动"
        case .tooHigh: "请稍微向下移动"
        case .tooLow: "请稍微向上移动"
        default: nil
        }
    }

    /// Create centering condition from face bounding box center
    /// - Parameter faceCenter: Normalized face center (0-1 range, origin at bottom-left per Vision framework)
    static func from(faceCenter: CGPoint) -> CenteringCondition {
        // Vision uses normalized coordinates (0-1) with origin at bottom-left
        // Center of frame is (0.5, 0.5)
        let centerX = faceCenter.x
        let centerY = faceCenter.y

        // Allow 15% deviation from center
        let tolerance: CGFloat = 0.15

        if centerX < 0.5 - tolerance {
            return .tooLeft
        } else if centerX > 0.5 + tolerance {
            return .tooRight
        } else if centerY < 0.5 - tolerance {
            return .tooLow
        } else if centerY > 0.5 + tolerance {
            return .tooHigh
        }

        return .optimal
    }
}

// MARK: - Sharpness Condition

enum SharpnessCondition {
    case unknown
    case blurry
    case slightlyBlurry
    case sharp

    var isAcceptable: Bool {
        switch self {
        case .sharp, .slightlyBlurry:
            true
        default:
            false
        }
    }

    var suggestion: String? {
        switch self {
        case .blurry: "图像模糊，请保持稳定"
        default: nil
        }
    }

    /// Create sharpness condition from Laplacian variance
    /// Higher variance = sharper image
    static func from(laplacianVariance: Double) -> SharpnessCondition {
        // Thresholds determined empirically for mobile camera
        switch laplacianVariance {
        case ..<50:
            .blurry
        case 50 ..< 100:
            .slightlyBlurry
        default:
            .sharp
        }
    }

    static func from(faceCaptureQuality: Float) -> SharpnessCondition {
        switch faceCaptureQuality {
        case ..<0.2:
            .blurry
        case 0.2 ..< 0.45:
            .slightlyBlurry
        default:
            .sharp
        }
    }
}

// MARK: - Face Detector

actor FaceDetector {
    private static let sharedCIContext: CIContext = {
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            return CIContext(mtlDevice: metalDevice)
        }
        return CIContext()
    }()

    func analyze(
        cgImage: CGImage,
        ciImage: CIImage? = nil,
        orientation: CGImagePropertyOrientation = .right
    ) async -> PhotoCondition? {
        // Use VNDetectFaceLandmarksRequest for more accurate detection
        let request = VNDetectFaceLandmarksRequest()
        let captureQualityRequest = VNDetectFaceCaptureQualityRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

        do {
            try handler.perform([captureQualityRequest, request])
        } catch {
            return nil
        }

        guard let face = request.results?.first else {
            return PhotoCondition(faceDetected: false)
        }

        var condition = PhotoCondition(faceDetected: true)

        // Analyze face angle
        condition.faceAngle = FaceAngle(
            yaw: (face.yaw?.doubleValue ?? 0) * 180 / .pi,
            pitch: (face.pitch?.doubleValue ?? 0) * 180 / .pi,
            roll: (face.roll?.doubleValue ?? 0) * 180 / .pi
        )

        // Analyze distance based on face size
        let faceArea = face.boundingBox.width * face.boundingBox.height
        switch faceArea {
        case ..<0.05:
            condition.faceDistance = .tooFar
        case 0.05 ..< 0.10:
            condition.faceDistance = .slightlyFar
        case 0.10 ..< 0.30:
            condition.faceDistance = .optimal
        case 0.30 ..< 0.40:
            condition.faceDistance = .slightlyClose
        default:
            condition.faceDistance = .tooClose
        }

        // Analyze face centering
        let faceCenter = CGPoint(
            x: face.boundingBox.midX,
            y: face.boundingBox.midY
        )
        condition.faceCentering = CenteringCondition.from(faceCenter: faceCenter)

        // Analyze lighting based on image brightness
        condition.lighting = analyzeLighting(cgImage: cgImage, ciImage: ciImage)

        // Analyze sharpness using Laplacian variance
        if let quality = captureQualityRequest.results?.first?.faceCaptureQuality {
            condition.sharpness = SharpnessCondition.from(faceCaptureQuality: quality)
        } else {
            condition.sharpness = analyzeSharpness(cgImage: cgImage)
        }

        return condition
    }

    private func analyzeLighting(cgImage: CGImage, ciImage: CIImage?) -> LightingCondition {
        if let ciImage, let brightness = averageBrightness(ciImage: ciImage) {
            return LightingCondition.from(averageBrightness: brightness)
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let totalBytes = bytesPerRow * height

        guard let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            return .unknown
        }

        // Sample pixels for brightness calculation (every 10th pixel for performance)
        var totalBrightness: Double = 0
        var sampleCount: Double = 0
        let step = 10

        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                guard offset + 2 < totalBytes else { continue }

                let r = Double(bytes[offset])
                let g = Double(bytes[offset + 1])
                let b = Double(bytes[offset + 2])

                // Calculate perceived brightness (ITU-R BT.601)
                let brightness = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
                totalBrightness += brightness
                sampleCount += 1
            }
        }

        guard sampleCount > 0 else { return .unknown }
        let avgBrightness = totalBrightness / sampleCount

        return LightingCondition.from(averageBrightness: avgBrightness)
    }

    private func averageBrightness(ciImage: CIImage) -> Double? {
        let extent = ciImage.extent
        guard extent.width > 0, extent.height > 0 else { return nil }
        let filter = CIFilter(name: "CIAreaAverage")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)

        guard let outputImage = filter?.outputImage else { return nil }

        var pixel = [UInt8](repeating: 0, count: 4)
        FaceDetector.sharedCIContext.render(
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

    /// Analyze image sharpness using Laplacian variance method
    /// Higher variance indicates sharper image
    private func analyzeSharpness(cgImage: CGImage) -> SharpnessCondition {
        let width = cgImage.width
        let height = cgImage.height

        // Skip for very small images
        guard width > 10, height > 10 else { return .unknown }

        guard let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            return .unknown
        }

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel

        // Convert to grayscale and compute Laplacian
        // Laplacian kernel: [0, 1, 0], [1, -4, 1], [0, 1, 0]
        var laplacianValues: [Double] = []

        // Sample every 5th pixel for performance
        let step = 5

        for y in stride(from: 1, to: height - 1, by: step) {
            for x in stride(from: 1, to: width - 1, by: step) {
                // Get grayscale values for 3x3 neighborhood
                func grayscale(atX px: Int, atY py: Int) -> Double {
                    let offset = (py * bytesPerRow) + (px * bytesPerPixel)
                    guard offset + 2 < CFDataGetLength(data) else { return 0 }
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

                // Apply Laplacian kernel
                let laplacian = top + bottom + left + right - 4 * center
                laplacianValues.append(laplacian)
            }
        }

        guard !laplacianValues.isEmpty else { return .unknown }

        // Calculate variance of Laplacian values
        let mean = laplacianValues.reduce(0, +) / Double(laplacianValues.count)
        let variance = laplacianValues.reduce(0) { $0 + pow($1 - mean, 2) } / Double(laplacianValues.count)

        return SharpnessCondition.from(laplacianVariance: variance)
    }
}
