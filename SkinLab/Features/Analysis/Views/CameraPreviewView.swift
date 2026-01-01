import SwiftUI
import AVFoundation

// MARK: - Camera Preview View
struct CameraPreviewView: View {
    @StateObject private var camera = CameraService()
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var showPhotoPicker = false
    @State private var isCapturing = false
    @State private var showError = false
    
    var body: some View {
        ZStack {
            // Camera Preview
            if let frame = camera.frame {
                Image(decorative: frame, scale: 1.0)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
            }
            
            // Overlay
            VStack {
                // Top Bar
                topBar
                
                Spacer()
                
                // Face Guide
                faceGuide
                
                Spacer()
                
                // Condition Indicators
                conditionIndicators
                
                // Bottom Controls
                bottomControls
            }
        }
        .task {
            await camera.checkPermission()
        }
        .onDisappear {
            camera.stop()
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(selectedImage: $capturedImage)
        }
        .onChange(of: capturedImage) { _, newValue in
            if newValue != nil {
                dismiss()
            }
        }
        .onChange(of: camera.error) { _, newValue in
            showError = newValue != nil
        }
        .alert("相机错误", isPresented: $showError) {
            Button("确定") {
                camera.error = nil
                showError = false
            }
        } message: {
            Text(camera.error?.localizedDescription ?? "")
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
            }
            
            Spacer()
            
            Text("皮肤分析")
                .font(.skinLabHeadline)
                .foregroundColor(.white)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Face Guide
    private var faceGuide: some View {
        ZStack {
            // Oval guide
            Ellipse()
                .stroke(
                    camera.photoCondition.isReady ? Color.green : Color.white,
                    style: StrokeStyle(lineWidth: 3, dash: camera.photoCondition.faceDetected ? [] : [10, 5])
                )
                .frame(width: 260, height: 340)
            
            // Corner markers
            if camera.photoCondition.faceDetected {
                ForEach(0..<4) { index in
                    CornerMarker(isReady: camera.photoCondition.isReady)
                        .rotationEffect(.degrees(Double(index) * 90))
                        .offset(cornerOffset(for: index))
                }
            }
        }
    }
    
    private func cornerOffset(for index: Int) -> CGSize {
        let x: CGFloat = 130
        let y: CGFloat = 170
        switch index {
        case 0: return CGSize(width: -x, height: -y)
        case 1: return CGSize(width: x, height: -y)
        case 2: return CGSize(width: x, height: y)
        case 3: return CGSize(width: -x, height: y)
        default: return .zero
        }
    }
    
    // MARK: - Condition Indicators
    private var conditionIndicators: some View {
        VStack(spacing: 8) {
            if !camera.photoCondition.suggestions.isEmpty {
                ForEach(camera.photoCondition.suggestions, id: \.self) { suggestion in
                    Text(suggestion)
                        .font(.skinLabSubheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                }
            } else if camera.photoCondition.isReady {
                Text("✓ 状态良好，可以拍照")
                    .font(.skinLabSubheadline)
                    .foregroundColor(.green)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        HStack(spacing: 60) {
            // Photo Library
            Button {
                showPhotoPicker = true
            } label: {
                Image(systemName: "photo.on.rectangle")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
            }
            
            // Capture Button
            Button {
                capturePhoto()
            } label: {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 72, height: 72)
                    
                    Circle()
                        .fill(isCapturing ? Color.gray : Color.white)
                        .frame(width: 60, height: 60)
                }
            }
            .disabled(isCapturing)
            
            // Flip Camera (placeholder)
            Button {
                camera.toggleCamera()
            } label: {
                Image(systemName: "camera.rotate")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
            }
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Capture
    private func capturePhoto() {
        guard !isCapturing else { return }
        isCapturing = true
        
        Task {
            do {
                let image = try await camera.capturePhoto()
                capturedImage = image
            } catch {
                print("Capture error: \(error)")
            }
            isCapturing = false
        }
    }
}

// MARK: - Corner Marker
struct CornerMarker: View {
    let isReady: Bool
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(isReady ? Color.green : Color.white, lineWidth: 3)
    }
}

#Preview {
    CameraPreviewView(capturedImage: .constant(nil))
}
