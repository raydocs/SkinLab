import SwiftUI
import AVFoundation

struct AnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AnalysisViewModel()

    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var capturedImage: UIImage?
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 渐变背景
                Color.skinLabBackground.ignoresSafeArea()
                
                Circle()
                    .fill(LinearGradient.skinLabLavenderGradient)
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .offset(x: 100, y: -300)
                    .opacity(0.5)
                
                switch viewModel.state {
                case .camera:
                    cameraView
                case .analyzing:
                    analyzingView
                case .result(let analysis):
                    AnalysisResultView(analysis: analysis)
                case .error(let message):
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
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPreviewView(capturedImage: $capturedImage)
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(selectedImage: $capturedImage)
        }
        .onChange(of: capturedImage) { _, newImage in
            if let image = newImage {
                capturedImage = nil
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
                // 外层渐变光晕
                Ellipse()
                    .fill(LinearGradient.skinLabRoseGradient.opacity(0.15))
                    .frame(width: 300, height: 380)
                    .blur(radius: 20)
                
                // 轮廓边框
                Ellipse()
                    .stroke(
                        LinearGradient.skinLabRoseGradient,
                        style: StrokeStyle(lineWidth: 3, dash: [8, 6])
                    )
                    .frame(width: 260, height: 340)
                
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.skinLabRoseGradient)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "face.smiling")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }
                    .shadow(color: .skinLabPrimary.opacity(0.3), radius: 15, x: 0, y: 8)
                    
                    Text("AI皮肤分析")
                        .font(.skinLabTitle3)
                        .foregroundColor(.skinLabText)
                    
                    Text("拍摄面部照片获取专业分析")
                        .font(.skinLabSubheadline)
                        .foregroundColor(.skinLabSubtext)
                }
                
                // 装饰闪光
                SparkleView(size: 14)
                    .offset(x: 110, y: -140)
                
                SparkleView(size: 10)
                    .offset(x: -120, y: 100)
            }
            
            // Tips 卡片
            VStack(alignment: .leading, spacing: 10) {
                TipRow(icon: "sun.max.fill", text: "确保光线充足均匀", color: .skinLabAccent)
                TipRow(icon: "face.smiling", text: "保持自然表情，素颜最佳", color: .skinLabPrimary)
                TipRow(icon: "arrow.up.and.down.circle.fill", text: "调整至面部填满框内", color: .skinLabSecondary)
            }
            .padding()
            .background(Color.skinLabCardBackground)
            .cornerRadius(20)
            .skinLabSoftShadow()
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 14) {
                Button {
                    showCamera = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                        Text("拍照分析")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .opacity(0.7)
                    }
                }
                .buttonStyle(SkinLabPrimaryButtonStyle())
                
                Button {
                    showPhotoPicker = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("从相册选择")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .opacity(0.7)
                    }
                }
                .buttonStyle(SkinLabSecondaryButtonStyle())
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
                    .stroke(LinearGradient.skinLabRoseGradient.opacity(0.3), lineWidth: 2)
                    .frame(width: 160, height: 160)
                    .scaleEffect(1.2)
                    .opacity(0.5)
                
                Circle()
                    .stroke(LinearGradient.skinLabRoseGradient.opacity(0.5), lineWidth: 3)
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
                                .stroke(LinearGradient.skinLabRoseGradient, lineWidth: 3)
                        )
                } else {
                    Circle()
                        .fill(LinearGradient.skinLabRoseGradient)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "face.smiling")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                
                // 旋转加载指示器
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(LinearGradient.skinLabPrimaryGradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
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
        VStack(spacing: 28) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.skinLabWarning.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(LinearGradient(colors: [.skinLabWarning, .skinLabWarning.opacity(0.7)], startPoint: .top, endPoint: .bottom))
            }
            
            VStack(spacing: 8) {
                Text("分析失败")
                    .font(.skinLabTitle3)
                    .foregroundColor(.skinLabText)
                
                Text(message)
                    .font(.skinLabBody)
                    .foregroundColor(.skinLabSubtext)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button {
                viewModel.retry()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("重新尝试")
                }
            }
            .buttonStyle(SkinLabPrimaryButtonStyle())
            .padding(.horizontal, 48)
            
            Spacer()
        }
        .padding()
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
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.skinLabSubheadline)
                .foregroundColor(.skinLabText)
        }
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
                .font(.system(size: 20))
                .foregroundColor(isActive ? .skinLabPrimary : .skinLabSubtext.opacity(0.5))
            
            Text(text)
                .font(.skinLabCaption)
                .foregroundColor(isActive ? .skinLabText : .skinLabSubtext.opacity(0.5))
        }
    }
}

#Preview {
    AnalysisView()
}
