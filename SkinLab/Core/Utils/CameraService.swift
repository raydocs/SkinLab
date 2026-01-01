import SwiftUI
import AVFoundation
import Vision
import CoreImage
import Metal

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
    
    private let videoQueue = DispatchQueue(label: "camera.video.queue")
    private let faceDetector = FaceDetector()
    private var lastFaceDetectionTime: CFAbsoluteTime = 0
    private let faceDetectionInterval: CFAbsoluteTime = 0.2  // 5fps throttle
    
    // Reuse CIContext for better performance
    private static let sharedCIContext: CIContext = {
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
                return true
            case (.setupFailed, .setupFailed):
                return true
            default:
                return false
            }
        }

        var errorDescription: String? {
            switch self {
            case .denied: return "相机权限被拒绝,请在设置中开启"
            case .unavailable: return "相机不可用"
            case .setupFailed(let error): return "相机初始化失败: \(error.localizedDescription)"
            case .captureInProgress: return "正在拍照中,请稍候"
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
    
    // MARK: - Stop
    func stop() {
        Task.detached { [weak self] in
            guard let self = self else { return }
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
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Create CGImage for preview using shared context
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = CameraService.sharedCIContext.createCGImage(ciImage, from: ciImage.extent) else { return }

        // Throttle face detection to improve performance
        let currentTime = CFAbsoluteTimeGetCurrent()

        Task { @MainActor in
            // Always update frame for smooth preview
            self.frame = cgImage

            // Only run face detection at throttled interval
            if currentTime - self.lastFaceDetectionTime >= self.faceDetectionInterval {
                self.lastFaceDetectionTime = currentTime
                if let condition = await self.faceDetector.analyze(cgImage: cgImage, ciImage: ciImage) {
                    self.photoCondition = condition
                }
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        Task { @MainActor in
            if let error = error {
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
    
    var isReady: Bool {
        faceDetected && 
        lighting.isAcceptable && 
        faceAngle.isOptimal && 
        faceDistance.isAcceptable
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
        
        return result
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
            return true
        default:
            return false
        }
    }
    
    var suggestion: String? {
        switch self {
        case .tooDark: return "光线不足，请移到更亮的地方"
        case .tooBright: return "光线过强，请避开直射光"
        default: return nil
        }
    }
}

struct FaceAngle {
    var yaw: Double = 0      // 左右转头
    var pitch: Double = 0    // 上下点头
    var roll: Double = 0     // 歪头
    
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
            return true
        default:
            return false
        }
    }
    
    var suggestion: String? {
        switch self {
        case .tooFar: return "请靠近一些"
        case .tooClose: return "请稍微远一点"
        default: return nil
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
    
    func analyze(cgImage: CGImage, ciImage: CIImage? = nil) async -> PhotoCondition? {
        // Use VNDetectFaceLandmarksRequest for more accurate detection
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
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
        case 0.05..<0.10:
            condition.faceDistance = .slightlyFar
        case 0.10..<0.30:
            condition.faceDistance = .optimal
        case 0.30..<0.40:
            condition.faceDistance = .slightlyClose
        default:
            condition.faceDistance = .tooClose
        }
        
        // Analyze lighting based on image brightness
        condition.lighting = analyzeLighting(cgImage: cgImage)
        
        return condition
    }
    
    private func analyzeLighting(cgImage: CGImage) -> LightingCondition {
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
        
        switch avgBrightness {
        case ..<0.15:
            return .tooDark
        case 0.15..<0.30:
            return .slightlyDark
        case 0.30..<0.70:
            return .optimal
        case 0.70..<0.85:
            return .slightlyBright
        default:
            return .tooBright
        }
    }
}
