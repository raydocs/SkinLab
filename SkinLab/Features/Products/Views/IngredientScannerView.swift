import SwiftUI
import SwiftData

struct IngredientScannerFullView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = IngredientScannerViewModel()
    @Query private var profiles: [UserProfile]
    @Query private var preferences: [UserIngredientPreference]

    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var capturedImage: UIImage?
    @State private var scanRotationAngle: Double = 0

    private var userProfile: UserProfile? {
        profiles.first
    }

    private var historyStore: UserHistoryStore {
        UserHistoryStore(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Beautiful gradient background
                LinearGradient(
                    colors: [
                        Color.skinLabPrimary.opacity(0.08),
                        Color.skinLabSecondary.opacity(0.06),
                        Color.skinLabBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                switch viewModel.state {
                case .idle:
                    idleView
                case .scanning:
                    scanningView
                case .result(let baseResult, let enhancedResult):
                    if let enhanced = enhancedResult {
                        EnhancedIngredientResultView(enhancedResult: enhanced, profile: userProfile)
                    } else {
                        resultView(baseResult)
                    }
                case .error(let error):
                    errorView(error)
                }
            }
            .navigationTitle("成分扫描")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                        .foregroundColor(.skinLabPrimary)
                }
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(selectedImage: $capturedImage)
        }
        .fullScreenCover(isPresented: $showCamera) {
            SimpleImagePicker(selectedImage: $capturedImage)
        }
        .onChange(of: capturedImage) { _, newImage in
            if let image = newImage {
                Task {
                    await viewModel.scan(
                        image: image,
                        profile: userProfile,
                        historyStore: historyStore,
                        preferences: preferences
                    )
                }
            }
        }
    }
    
    // MARK: - Idle View
    private var idleView: some View {
        VStack(spacing: 28) {
            Spacer()
            
            // Icon with sparkle effect
            ZStack {
                Circle()
                    .fill(LinearGradient.skinLabPrimaryGradient.opacity(0.12))
                    .frame(width: 130, height: 130)
                
                Circle()
                    .fill(LinearGradient.skinLabPrimaryGradient.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "text.viewfinder")
                    .font(.system(size: 48))
                    .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                
                SparkleView(size: 16)
                    .offset(x: 50, y: -45)
            }
            
            VStack(spacing: 12) {
                Text("扫描护肤品成分表")
                    .font(.skinLabTitle2)
                    .foregroundColor(.skinLabText)
                
                Text("拍摄成分表照片\nAI将自动识别并解读成分")
                    .font(.skinLabBody)
                    .foregroundColor(.skinLabSubtext)
                    .multilineTextAlignment(.center)
            }
            
            // Feature hints with beautiful styling
            VStack(alignment: .leading, spacing: 16) {
                BeautifulHintRow(icon: "checkmark.circle.fill", text: "识别成分功效", gradient: .skinLabPrimaryGradient)
                BeautifulHintRow(icon: "exclamationmark.triangle.fill", text: "标注风险成分", gradient: .skinLabGoldGradient)
                BeautifulHintRow(icon: "person.fill.checkmark", text: "分析是否适合你", gradient: .skinLabLavenderGradient)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 14) {
                Button {
                    showCamera = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                        Text("拍照扫描")
                            .font(.skinLabHeadline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(LinearGradient.skinLabPrimaryGradient)
                    .cornerRadius(28)
                    .shadow(color: .skinLabPrimary.opacity(0.35), radius: 12, y: 6)
                }
                
                Button {
                    showPhotoPicker = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 16))
                        Text("从相册选择")
                            .font(.skinLabHeadline)
                    }
                    .foregroundColor(.skinLabPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.skinLabCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(LinearGradient.skinLabPrimaryGradient, lineWidth: 2)
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .padding()
    }
    
    // MARK: - Scanning View
    private var scanningView: some View {
        VStack(spacing: 32) {
            // Animated scanning indicator
            ZStack {
                Circle()
                    .stroke(LinearGradient.skinLabPrimaryGradient.opacity(0.2), lineWidth: 4)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(LinearGradient.skinLabPrimaryGradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(scanRotationAngle - 90))
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            scanRotationAngle = 360
                        }
                    }

                Image(systemName: "text.magnifyingglass")
                    .font(.system(size: 36))
                    .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
            }
            
            VStack(spacing: 10) {
                Text("正在识别成分...")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
                
                Text("AI 正在分析成分表")
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabSubtext)
            }
        }
    }
    
    // MARK: - Result View
    private func resultView(_ result: IngredientScanResult) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Safety Summary with beautiful design
                beautifulSafetySummary(result)
                
                // Highlights
                if !result.highlights.isEmpty {
                    beautifulHighlightsSection(result.highlights)
                }
                
                // Warnings
                if !result.warnings.isEmpty {
                    beautifulWarningsSection(result.warnings)
                }
                
                // All Ingredients
                beautifulIngredientsList(result.ingredients)
                
                // Scan Again Button
                Button {
                    viewModel.reset()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                        Text("重新扫描")
                            .font(.skinLabHeadline)
                    }
                    .foregroundColor(.skinLabPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.skinLabCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(LinearGradient.skinLabPrimaryGradient, lineWidth: 1.5)
                    )
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
    
    private func beautifulSafetySummary(_ result: IngredientScanResult) -> some View {
        HStack(spacing: 16) {
            // Safety indicator
            ZStack {
                Circle()
                    .fill(safetyGradient(result.overallSafety).opacity(0.15))
                    .frame(width: 70, height: 70)
                
                Circle()
                    .fill(safetyGradient(result.overallSafety))
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: safetyIcon(result.overallSafety))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("整体评价")
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
                
                Text(result.overallSafety.rawValue)
                    .font(.skinLabTitle3)
                    .foregroundStyle(safetyGradient(result.overallSafety))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(result.ingredients.count)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                Text("种成分")
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.skinLabCardBackground)
        )
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
    
    private func beautifulHighlightsSection(_ highlights: [String]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.skinLabSuccess.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.skinLabSuccess)
                }
                Text("亮点成分")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabSuccess)
            }
            
            ForEach(highlights, id: \.self) { highlight in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.skinLabSuccess)
                    Text(highlight)
                        .font(.skinLabBody)
                        .foregroundColor(.skinLabText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.skinLabSuccess.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.skinLabSuccess.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func beautifulWarningsSection(_ warnings: [String]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.skinLabWarning.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.skinLabWarning)
                }
                Text("注意事项")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabWarning)
            }
            
            ForEach(warnings, id: \.self) { warning in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.skinLabWarning)
                    Text(warning)
                        .font(.skinLabBody)
                        .foregroundColor(.skinLabText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.skinLabWarning.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.skinLabWarning.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func beautifulIngredientsList(_ ingredients: [IngredientScanResult.ParsedIngredient]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("全部成分")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
                Spacer()
                Text("\(ingredients.count)种")
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(ingredients) { ingredient in
                    BeautifulIngredientChip(ingredient: ingredient)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.skinLabCardBackground)
        )
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }
    
    // MARK: - Error View
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.skinLabWarning.opacity(0.12))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 44))
                    .foregroundColor(.skinLabWarning)
            }
            
            VStack(spacing: 10) {
                Text("识别失败")
                    .font(.skinLabTitle3)
                    .foregroundColor(.skinLabText)
                
                Text(error.localizedDescription)
                    .font(.skinLabBody)
                    .foregroundColor(.skinLabSubtext)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                viewModel.reset()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                    Text("重试")
                        .font(.skinLabHeadline)
                }
                .foregroundColor(.white)
                .frame(width: 160, height: 50)
                .background(LinearGradient.skinLabPrimaryGradient)
                .cornerRadius(25)
                .shadow(color: .skinLabPrimary.opacity(0.3), radius: 10, y: 5)
            }
        }
        .padding()
    }
    
    // MARK: - Helpers
    private func safetyGradient(_ level: IngredientScanResult.SafetyLevel) -> LinearGradient {
        switch level {
        case .safe:
            return LinearGradient(colors: [.skinLabSuccess, .skinLabSuccess.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .caution:
            return LinearGradient.skinLabGoldGradient
        case .warning:
            return LinearGradient(colors: [.skinLabError, .skinLabError.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private func safetyColor(_ level: IngredientScanResult.SafetyLevel) -> Color {
        switch level {
        case .safe: return .skinLabSuccess
        case .caution: return .skinLabWarning
        case .warning: return .skinLabError
        }
    }
    
    private func safetyIcon(_ level: IngredientScanResult.SafetyLevel) -> String {
        switch level {
        case .safe: return "checkmark"
        case .caution: return "exclamationmark"
        case .warning: return "xmark"
        }
    }
}

// MARK: - Beautiful Hint Row
struct BeautifulHintRow: View {
    let icon: String
    let text: String
    var gradient: LinearGradient = .skinLabPrimaryGradient
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(gradient)
            }
            
            Text(text)
                .font(.skinLabSubheadline)
                .foregroundColor(.skinLabText)
        }
    }
}

// MARK: - Beautiful Ingredient Chip
struct BeautifulIngredientChip: View {
    let ingredient: IngredientScanResult.ParsedIngredient
    
    var body: some View {
        HStack(spacing: 5) {
            if ingredient.isHighlight {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.skinLabAccent)
            }
            if ingredient.isWarning {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.skinLabWarning)
            }
            
            Text(ingredient.name)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(chipTextColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(chipBackground)
        .cornerRadius(14)
    }
    
    private var chipTextColor: Color {
        if ingredient.isWarning { return .skinLabWarning }
        if ingredient.isHighlight { return .skinLabSuccess }
        return .skinLabText
    }
    
    private var chipBackground: some View {
        Group {
            if ingredient.isWarning {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.skinLabWarning.opacity(0.1))
            } else if ingredient.isHighlight {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.skinLabSuccess.opacity(0.1))
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.gray.opacity(0.08))
            }
        }
    }
}

// MARK: - Simple Image Picker (for camera)
struct SimpleImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: SimpleImagePicker
        
        init(_ parent: SimpleImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - View Model
@MainActor
class IngredientScannerViewModel: ObservableObject {
    enum State {
        case idle
        case scanning
        case result(IngredientScanResult, EnhancedIngredientScanResult?)
        case error(Error)
    }
    
    @Published var state: State = .idle
    
    private let ocrService = IngredientOCRService.shared
    private let database = IngredientDatabase.shared
    private let riskAnalyzer = IngredientRiskAnalyzer()
    
    @MainActor
    func scan(
        image: UIImage,
        profile: UserProfile?,
        historyStore: UserHistoryStore,
        preferences: [UserIngredientPreference]
    ) async {
        state = .scanning

        do {
            let ingredients = try await ocrService.recognizeIngredients(from: image)

            if ingredients.isEmpty {
                throw OCRError.noTextFound
            }

            let baseResult = database.analyze(ingredients)

            // Enhance with risk analysis including historical data
            let enhancedResult = riskAnalyzer.analyze(
                scanResult: baseResult,
                profile: profile,
                historyStore: historyStore,
                userPreferences: preferences
            )

            state = .result(baseResult, enhancedResult)
        } catch {
            state = .error(error)
        }
    }
    
    func reset() {
        state = .idle
    }
}

#Preview {
    IngredientScannerFullView()
}
