import AVFoundation
import SwiftUI

struct AnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = AnalysisViewModel()

    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var capturedImage: UIImage?
    @State private var capturedStandardization: PhotoStandardizationMetadata?
    @State private var rotationAngle: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                FreshBackgroundMesh()

                switch viewModel.state {
                case .camera:
                    cameraView
                case .analyzing:
                    analyzingView
                case let .result(result):
                    AnalysisResultView(result: result) {
                        viewModel.retry()
                    }
                case let .error(message):
                    errorView(message)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("皮肤分析")
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.gray.opacity(0.5))
                    }
                    .accessibilityLabel("关闭")
                    .accessibilityHint("返回上一页面")
                }
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPreviewView(
                capturedImage: $capturedImage,
                capturedStandardization: $capturedStandardization
            )
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(selectedImage: $capturedImage, onImageSelected: {
                capturedStandardization = PhotoStandardizationMetadata(
                    capturedAt: Date(),
                    cameraPosition: .unknown,
                    captureSource: .library,
                    lighting: .optimal,
                    faceDetected: false,
                    yawDegrees: 0,
                    pitchDegrees: 0,
                    rollDegrees: 0,
                    distance: .optimal,
                    isReady: false,
                    suggestions: ["从相册选择，无实时拍照条件数据"],
                    userOverride: nil
                )
            })
        }
        .onChange(of: capturedImage) { _, newImage in
            if let image = newImage {
                capturedImage = nil
                // Store captured data for persistence
                viewModel.setCapturedData(image, standardization: capturedStandardization)
                Task {
                    await viewModel.analyzeImage(image)
                }
            }
        }
    }

    // MARK: - Camera View

    private var cameraView: some View {
        VStack(spacing: 28) {
            Spacer()

            // 面部轮廓引导
            ZStack {
                // Fresh Guide Oval
                Ellipse()
                    .stroke(
                        Color.freshPrimary.opacity(0.5),
                        style: StrokeStyle(lineWidth: 3, dash: [8, 6])
                    )
                    .frame(width: 260, height: 340)

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.freshPrimary.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "face.smiling")
                            .font(.system(size: 36))
                            .foregroundColor(.freshPrimary)
                    }

                    Text("AI皮肤分析")
                        .font(.skinLabTitle3)
                        .foregroundColor(.skinLabText)

                    Text("拍摄面部照片获取专业分析")
                        .font(.skinLabSubheadline)
                        .foregroundColor(.skinLabSubtext)
                }
            }

            // Tips 卡片
            VStack(alignment: .leading, spacing: 10) {
                TipRow(icon: "sun.max.fill", text: "确保光线充足均匀", color: .freshAccent)
                TipRow(icon: "face.smiling", text: "保持自然表情，素颜最佳", color: .freshPrimary)
                TipRow(icon: "arrow.up.and.down.circle.fill", text: "调整至面部填满框内", color: .freshSecondary)
            }
            .padding()
            .freshGlassCard()

            Spacer()

            // Action Buttons
            VStack(spacing: 14) {
                Button {
                    AnalyticsEvents.analysisStarted(source: .camera)
                    showCamera = true
                } label: {
                    Text("Take Photo")
                }
                .buttonStyle(FreshGlassButton(color: .freshPrimary))
                .accessibilityLabel("拍摄照片")
                .accessibilityHint("打开相机拍摄皮肤照片")

                Button {
                    AnalyticsEvents.analysisStarted(source: .library)
                    showPhotoPicker = true
                } label: {
                    Text("Select from Library")
                }
                .buttonStyle(FreshSecondaryButton())
                .accessibilityLabel("从相册选择")
                .accessibilityHint("从照片库选择皮肤照片")
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .padding()
    }

    // MARK: - Analyzing View

    private var analyzingView: some View {
        VStack(spacing: 28) {
            Spacer()

            // 分析动画
            ZStack {
                // 外层脉冲圆
                Circle()
                    .stroke(Color.freshPrimary.opacity(0.2), lineWidth: 1)
                    .frame(width: 160, height: 160)
                    .scaleEffect(1.2)
                    .opacity(0.6)

                Circle()
                    .stroke(Color.freshPrimary.opacity(0.3), lineWidth: 2)
                    .frame(width: 120, height: 120)

                // 图片预览
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.freshPrimary, lineWidth: 2)
                        )
                } else {
                    Circle()
                        .fill(Color.freshPrimary.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "face.smiling")
                        .font(.system(size: 40))
                        .foregroundColor(.freshPrimary)
                }

                // 旋转加载指示器
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.freshPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }
            }

            VStack(spacing: 8) {
                Text(viewModel.analysisProgress)
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)

                Text("AI正在识别你的肌肤特征...")
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabSubtext)
            }

            // 分析步骤指示
            HStack(spacing: 20) {
                AnalysisStep(icon: "checkmark.circle.fill", text: "图片优化", isActive: true)
                AnalysisStep(icon: "circle", text: "肤质识别", isActive: false)
                AnalysisStep(icon: "circle", text: "问题检测", isActive: false)
            }
            .padding(.top, 20)

            Spacer()
        }
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        // Use the preserved error for better categorization, fallback to message-based error
        let displayError: Error = viewModel.lastError ?? NSError(
            domain: "SkinLabAnalysis",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )

        return ErrorRecoveryView(
            error: displayError,
            retryAction: {
                // Retry with the last captured image if available
                await viewModel.retryWithLastImage()
            },
            dismissAction: {
                viewModel.retry()
            }
        )
        // Note: ErrorRecoveryView has internal padding, no additional padding needed
    }
}

// MARK: - Tip Row

struct TipRow: View {
    let icon: String
    let text: String
    var color: Color = .skinLabSecondary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(text)
                .font(.skinLabSubheadline)
                .foregroundColor(.skinLabText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

// MARK: - Analysis Step Indicator

struct AnalysisStep: View {
    let icon: String
    let text: String
    let isActive: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(isActive ? .freshPrimary : .skinLabSubtext.opacity(0.5))
                .accessibilityHidden(true)

            Text(text)
                .font(.skinLabCaption)
                .foregroundColor(isActive ? .skinLabText : .skinLabSubtext.opacity(0.5))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(text)，\(isActive ? "进行中" : "等待中")")
    }
}

#Preview {
    AnalysisView()
}
