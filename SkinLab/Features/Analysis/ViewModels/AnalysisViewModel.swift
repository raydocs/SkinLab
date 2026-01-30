import PhotosUI
import SwiftData
import SwiftUI

// MARK: - Analysis Run Result

struct AnalysisRunResult: Sendable {
    let analysis: SkinAnalysis
    let analysisId: UUID
    let photoPath: String?
    let standardization: PhotoStandardizationMetadata?
    let photoQualityReport: PhotoQualityReport?
}

@MainActor
class AnalysisViewModel: ObservableObject {
    enum State: Equatable {
        case camera
        case analyzing
        case result(AnalysisRunResult)
        case error(String)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.camera, .camera), (.analyzing, .analyzing):
                true
            case let (.result(a), .result(b)):
                a.analysisId == b.analysisId
            case let (.error(a), .error(b)):
                a == b
            default:
                false
            }
        }
    }

    @Published var state: State = .camera
    @Published var selectedImage: UIImage?
    @Published var analysisProgress: String = ""

    /// The last error that occurred, preserved for retry context
    @Published private(set) var lastError: Error?

    private let analysisService: SkinAnalysisServiceProtocol
    private let photoQualityEvaluator: PhotoQualityEvaluator
    private var modelContext: ModelContext?

    // Store captured data for persistence
    private var lastCapturedImage: UIImage?
    private var lastStandardization: PhotoStandardizationMetadata?
    private var lastPhotoQualityReport: PhotoQualityReport?

    /// Track analysis timing for analytics
    private var analysisStartTime: Date?

    // MARK: - Dependency Injection

    init(
        analysisService: SkinAnalysisServiceProtocol = GeminiService.shared,
        photoQualityEvaluator: PhotoQualityEvaluator = PhotoQualityEvaluator(),
        modelContext: ModelContext? = nil
    ) {
        self.analysisService = analysisService
        self.photoQualityEvaluator = photoQualityEvaluator
        self.modelContext = modelContext
    }

    // MARK: - Actions

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func setCapturedData(_ image: UIImage, standardization: PhotoStandardizationMetadata?) {
        self.lastCapturedImage = image
        self.lastStandardization = standardization
    }

    func retry() {
        state = .camera
        selectedImage = nil
        analysisProgress = ""
        lastCapturedImage = nil
        lastStandardization = nil
        lastPhotoQualityReport = nil
        lastError = nil
    }

    /// Retry analysis with the previously captured image
    func retryWithLastImage() async {
        guard let image = lastCapturedImage ?? selectedImage else {
            retry()
            return
        }
        await analyzeImage(image)
    }

    // MARK: - Analysis

    func analyzeImage(_ image: UIImage) async {
        selectedImage = image
        state = .analyzing
        analysisProgress = "正在评估照片质量..."
        analysisStartTime = Date()

        do {
            // Step 1: Evaluate photo quality locally
            let photoQualityReport = await photoQualityEvaluator.evaluate(image: image)
            lastPhotoQualityReport = photoQualityReport

            if AppConfiguration.Features.lowQualityPhotoBlockingEnabled, !photoQualityReport.isAcceptable {
                throw AppError.operationFailed(
                    operation: "照片质量检查",
                    reason: "照片质量较低，请根据提示重新拍摄"
                )
            }

            // Step 2: AI analysis
            analysisProgress = "AI正在分析你的皮肤..."
            let baseAnalysis = try await analysisService.analyzeSkin(image: image)

            // Step 3: Combine analysis with local photo quality report
            let analysis = SkinAnalysis(
                id: baseAnalysis.id,
                skinType: baseAnalysis.skinType,
                skinAge: baseAnalysis.skinAge,
                overallScore: baseAnalysis.overallScore,
                issues: baseAnalysis.issues,
                regions: baseAnalysis.regions,
                recommendations: baseAnalysis.recommendations,
                analyzedAt: baseAnalysis.analyzedAt,
                confidenceScore: baseAnalysis.confidenceScore,
                imageQuality: baseAnalysis.imageQuality,
                photoQualityReport: photoQualityReport
            )

            // Save photo and persist analysis if modelContext is available
            var photoPath: String? = nil
            if let modelContext,
               let capturedImage = lastCapturedImage {
                // Move compression off main actor to avoid UI hitching
                photoPath = await savePhotoOffMainActor(image: capturedImage, analysisId: analysis.id)

                // Create and insert SkinAnalysisRecord
                let record = SkinAnalysisRecord(from: analysis, photoPath: photoPath)
                modelContext.insert(record)
                try modelContext.save()
            }

            // Create AnalysisRunResult
            let result = AnalysisRunResult(
                analysis: analysis,
                analysisId: analysis.id,
                photoPath: photoPath,
                standardization: lastStandardization,
                photoQualityReport: photoQualityReport
            )

            state = .result(result)
            lastError = nil

            // Track analysis completion
            let duration = analysisStartTime.map { Date().timeIntervalSince($0) } ?? 0
            AnalyticsEvents.analysisCompleted(
                skinType: analysis.skinType.rawValue,
                score: analysis.overallScore,
                durationSeconds: duration
            )

            // Track report viewed (user sees result immediately after analysis)
            AnalyticsEvents.reportViewed(
                analysisId: analysis.id.uuidString,
                score: analysis.overallScore
            )
        } catch let error as GeminiError {
            lastError = error
            state = .error(error.localizedDescription)
        } catch let error as AppError {
            lastError = error
            state = .error(error.localizedDescription)
        } catch {
            lastError = error
            state = .error("分析失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Private

    /// Save photo with compression off main actor to avoid UI hitching
    private func savePhotoOffMainActor(image: UIImage, analysisId: UUID) async -> String? {
        // Run compression and disk I/O on background thread
        await Task.detached(priority: .userInitiated) {
            Self.compressAndSavePhoto(image: image, analysisId: analysisId)
        }.value
    }

    /// Static helper for photo compression and saving (runs on background thread)
    private nonisolated static func compressAndSavePhoto(image: UIImage, analysisId: UUID) -> String? {
        // Use image compression utilities for optimized storage
        guard let data = image.compressed(
            quality: ImageCompressionConfig.defaultQuality,
            maxDimension: ImageCompressionConfig.defaultMaxDimension
        ) else {
            return nil
        }

        let filename = "\(analysisId.uuidString).jpg"
        let relativePath = "analysis_photos/\(filename)"

        let photosDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("analysis_photos", isDirectory: true)

        try? FileManager.default.createDirectory(at: photosDir, withIntermediateDirectories: true)

        let fileURL = photosDir.appendingPathComponent(filename)
        try? data.write(to: fileURL)

        // Also generate and save thumbnail for faster loading in lists
        saveThumbnailStatic(image: image, analysisId: analysisId)

        // Cache the full image for quick access
        Task {
            await ImageCache.shared.storeData(data, for: relativePath)
        }

        return relativePath
    }

    /// Static helper for thumbnail generation (runs on background thread)
    private nonisolated static func saveThumbnailStatic(image: UIImage, analysisId: UUID) {
        guard let thumbnailData = image.thumbnailData(
            size: ImageCompressionConfig.defaultThumbnailSize,
            quality: 0.7
        ) else {
            return
        }

        let thumbnailFilename = "\(analysisId.uuidString)_thumb.jpg"
        let thumbnailPath = "analysis_photos/\(thumbnailFilename)"

        let photosDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("analysis_photos", isDirectory: true)

        let thumbnailURL = photosDir.appendingPathComponent(thumbnailFilename)
        try? thumbnailData.write(to: thumbnailURL)

        // Cache thumbnail
        Task {
            await ImageCache.shared.storeData(thumbnailData, for: thumbnailPath)
        }
    }
}

// MARK: - Mock Service for Testing/Previews

#if DEBUG
    actor MockAnalysisService: SkinAnalysisServiceProtocol {
        func analyzeSkin(image: UIImage) async throws -> SkinAnalysis {
            try await Task.sleep(nanoseconds: 1_500_000_000)
            return SkinAnalysis.mock
        }
    }
#endif
