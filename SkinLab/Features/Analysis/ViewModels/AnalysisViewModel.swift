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
                photoPath = savePhoto(image: capturedImage, analysisId: analysis.id)

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
        } catch let error as GeminiError {
            state = .error(error.localizedDescription)
        } catch {
            state = .error("分析失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Private
    private func savePhoto(image: UIImage, analysisId: UUID) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }

        let filename = "\(analysisId.uuidString).jpg"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("analysis_photos", isDirectory: true)

        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)

        let fileURL = url.appendingPathComponent(filename)
        try? data.write(to: fileURL)

        return filename
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
