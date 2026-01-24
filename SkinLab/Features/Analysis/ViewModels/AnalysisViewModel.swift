import SwiftUI
import PhotosUI
import SwiftData

// MARK: - Analysis Run Result
struct AnalysisRunResult: Sendable {
    let analysis: SkinAnalysis
    let analysisId: UUID
    let photoPath: String?
    let standardization: PhotoStandardizationMetadata?
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
                return true
            case (.result(let a), .result(let b)):
                return a.analysisId == b.analysisId
            case (.error(let a), .error(let b)):
                return a == b
            default:
                return false
            }
        }
    }

    @Published var state: State = .camera
    @Published var selectedImage: UIImage?
    @Published var analysisProgress: String = ""

    /// The last error that occurred, preserved for retry context
    @Published private(set) var lastError: Error?

    private let analysisService: SkinAnalysisServiceProtocol
    private var modelContext: ModelContext?

    // Store captured data for persistence
    private var lastCapturedImage: UIImage?
    private var lastStandardization: PhotoStandardizationMetadata?

    // MARK: - Dependency Injection
    init(
        analysisService: SkinAnalysisServiceProtocol = GeminiService.shared,
        modelContext: ModelContext? = nil
    ) {
        self.analysisService = analysisService
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
        analysisProgress = "正在优化图片..."

        do {
            analysisProgress = "AI正在分析你的皮肤..."
            let analysis = try await analysisService.analyzeSkin(image: image)

            // Save photo and persist analysis if modelContext is available
            var photoPath: String? = nil
            if let modelContext = modelContext,
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
                standardization: lastStandardization
            )

            state = .result(result)
            lastError = nil
        } catch let error as GeminiError {
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
        return await Task.detached(priority: .userInitiated) {
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
