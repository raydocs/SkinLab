import SwiftUI
import PhotosUI

@MainActor
class AnalysisViewModel: ObservableObject {
    enum State: Equatable {
        case camera
        case analyzing
        case result(SkinAnalysis)
        case error(String)
        
        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.camera, .camera), (.analyzing, .analyzing):
                return true
            case (.result(let a), .result(let b)):
                return a.id == b.id
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
    
    // MARK: - Dependency Injection
    init(analysisService: SkinAnalysisServiceProtocol = GeminiService.shared) {
        self.analysisService = analysisService
    }
    
    // MARK: - Actions
    func retry() {
        state = .camera
        selectedImage = nil
        analysisProgress = ""
    }
    
    // MARK: - Analysis
    func analyzeImage(_ image: UIImage) async {
        selectedImage = image
        state = .analyzing
        analysisProgress = "正在优化图片..."
        
        do {
            analysisProgress = "AI正在分析你的皮肤..."
            let analysis = try await analysisService.analyzeSkin(image: image)
            state = .result(analysis)
        } catch let error as GeminiError {
            state = .error(error.localizedDescription)
        } catch {
            state = .error("分析失败: \(error.localizedDescription)")
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
