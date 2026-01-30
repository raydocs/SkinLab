import SwiftUI

struct TrackingComparisonView: View {
    let beforePath: String?
    let afterPath: String?
    let beforeAnalysisId: UUID?
    let afterAnalysisId: UUID?

    @State private var sliderPosition: CGFloat = 0.5
    @State private var comparisonMode: ComparisonMode = .slider
    @Environment(\.dismiss) private var dismiss

    enum ComparisonMode {
        case slider
        case sideBySide
        case toggle
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mode Selector
            modeSelector

            // Comparison View
            comparisonContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Controls
            if comparisonMode == .slider {
                sliderControl
            }
        }
        .background(Color.black)
        .navigationTitle("对比效果")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.skinLabBackground, for: .navigationBar)
    }

    // MARK: - Mode Selector

    private var modeSelector: some View {
        HStack(spacing: 12) {
            ForEach([ComparisonMode.slider, .sideBySide, .toggle], id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        comparisonMode = mode
                    }
                } label: {
                    HStack {
                        Image(systemName: icon(for: mode))
                        Text(label(for: mode))
                            .font(.skinLabCaption)
                    }
                    .foregroundColor(comparisonMode == mode ? .white : .skinLabText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        comparisonMode == mode ?
                            AnyView(LinearGradient.skinLabRoseGradient) :
                            AnyView(Color.skinLabCardBackground)
                    )
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.skinLabBackground)
    }

    // MARK: - Comparison Content

    @ViewBuilder
    private var comparisonContent: some View {
        switch comparisonMode {
        case .slider:
            sliderView
        case .sideBySide:
            sideBySideView
        case .toggle:
            toggleView
        }
    }

    // MARK: - Slider View

    private var sliderView: some View {
        GeometryReader { geometry in
            ZStack {
                // After Image (Full)
                if let afterPath,
                   let afterImage = loadImage(from: afterPath) {
                    Image(uiImage: afterImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }

                // Before Image (Clipped)
                if let beforePath,
                   let beforeImage = loadImage(from: beforePath) {
                    Image(uiImage: beforeImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .mask(
                            Rectangle()
                                .frame(width: geometry.size.width * sliderPosition)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        )
                }

                // Slider Line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 3)
                    .position(x: geometry.size.width * sliderPosition, y: geometry.size.height / 2)

                // Slider Handle
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .shadow(radius: 4)
                    .overlay(
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                                .font(.caption)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(.skinLabPrimary)
                    )
                    .position(x: geometry.size.width * sliderPosition, y: geometry.size.height / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                sliderPosition = min(max(value.location.x / geometry.size.width, 0), 1)
                            }
                    )

                // Labels
                VStack {
                    HStack {
                        Text("BEFORE")
                            .font(.skinLabCaption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                            .padding(.leading)

                        Spacer()

                        Text("AFTER")
                            .font(.skinLabCaption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                            .padding(.trailing)
                    }
                    Spacer()
                }
                .padding(.top, 20)
            }
        }
    }

    // MARK: - Side by Side View

    private var sideBySideView: some View {
        HStack(spacing: 2) {
            // Before
            VStack(spacing: 8) {
                if let beforePath,
                   let beforeImage = loadImage(from: beforePath) {
                    Image(uiImage: beforeImage)
                        .resizable()
                        .scaledToFit()
                }

                Text("BEFORE")
                    .font(.skinLabCaption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
            }

            // After
            VStack(spacing: 8) {
                if let afterPath,
                   let afterImage = loadImage(from: afterPath) {
                    Image(uiImage: afterImage)
                        .resizable()
                        .scaledToFit()
                }

                Text("AFTER")
                    .font(.skinLabCaption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
            }
        }
        .padding()
    }

    // MARK: - Toggle View

    @State private var showBefore = true

    private var toggleView: some View {
        GeometryReader { geometry in
            ZStack {
                if showBefore {
                    if let beforePath,
                       let beforeImage = loadImage(from: beforePath) {
                        Image(uiImage: beforeImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .transition(.opacity)
                    }
                } else {
                    if let afterPath,
                       let afterImage = loadImage(from: afterPath) {
                        Image(uiImage: afterImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .transition(.opacity)
                    }
                }

                // Toggle Label
                VStack {
                    Text(showBefore ? "BEFORE" : "AFTER")
                        .font(.skinLabHeadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .padding()

                    Spacer()

                    // Tap to toggle hint
                    Text("点击切换")
                        .font(.skinLabCaption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(8)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(8)
                        .padding(.bottom, 40)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showBefore.toggle()
                }
            }
        }
    }

    // MARK: - Slider Control

    private var sliderControl: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Before")
                    .font(.skinLabCaption)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                Text("After")
                    .font(.skinLabCaption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Slider(value: $sliderPosition, in: 0 ... 1)
                .tint(.white)
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }

    // MARK: - Helper Methods

    private func icon(for mode: ComparisonMode) -> String {
        switch mode {
        case .slider: "slider.horizontal.3"
        case .sideBySide: "square.split.2x1"
        case .toggle: "arrow.left.arrow.right"
        }
    }

    private func label(for mode: ComparisonMode) -> String {
        switch mode {
        case .slider: "滑动"
        case .sideBySide: "并排"
        case .toggle: "切换"
        }
    }

    private func loadImage(from path: String) -> UIImage? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagePath = documentsPath.appendingPathComponent(path)
        return UIImage(contentsOfFile: imagePath.path)
    }
}

#Preview {
    NavigationStack {
        TrackingComparisonView(
            beforePath: nil,
            afterPath: nil,
            beforeAnalysisId: nil,
            afterAnalysisId: nil
        )
    }
}
