import SwiftUI
import SwiftData

struct TrackingDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var session: TrackingSession

    @State private var viewModel: TrackingDetailViewModel?
    @State private var showCamera = false
    @State private var showCheckIn = false
    @State private var capturedImage: UIImage?
    @State private var capturedStandardization: PhotoStandardizationMetadata?
    @State private var showProductPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Progress Header
                progressHeader
                
                // Timeline
                timelineSection
                
                // Products Used
                productsSection
                
                // Actions
                actionsSection
            }
            .padding()
        }
        .background(Color.skinLabBackground)
        .navigationTitle("追踪详情")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Initialize ViewModel with modelContext
            if viewModel == nil {
                viewModel = TrackingDetailViewModel(modelContext: modelContext)
            }
        }
        .sheet(isPresented: $showCheckIn) {
            CheckInView(
                session: session,
                image: capturedImage,
                standardization: capturedStandardization
            )
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.showReport ?? false },
            set: { viewModel?.showReport = $0 }
        )) {
            if let report = viewModel?.generatedReport {
                NavigationStack {
                    TrackingReportView(report: report)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("完成") {
                                    viewModel?.showReport = false
                                }
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $showProductPicker) {
            ProductPickerView(
                selectedProducts: Binding(
                    get: { session.targetProducts },
                    set: { session.targetProducts = $0 }
                )
            )
        }
        .alert("报告生成失败", isPresented: Binding(
            get: { viewModel?.reportError != nil },
            set: { if !$0 { viewModel?.reportError = nil } }
        )) {
            Button("确定") {
                viewModel?.reportError = nil
            }
        } message: {
            if let error = viewModel?.reportError {
                Text(error)
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPreviewView(
                capturedImage: $capturedImage,
                capturedStandardization: $capturedStandardization
            )
        }
        .onChange(of: capturedImage) { _, newImage in
            if newImage != nil {
                showCheckIn = true
            }
        }
    }
    
    // MARK: - Progress Header
    private var progressHeader: some View {
        VStack(spacing: 16) {
            // Progress Ring
            ZStack {
                Circle()
                    .trim(from: 0, to: session.progress)
                    .stroke(Color.freshPrimary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .background(
                        Circle()
                            .stroke(Color.freshPrimary.opacity(0.1), lineWidth: 8)
                    )
                
                VStack(spacing: 4) {
                    Text("\(session.duration)")
                        .font(.system(size: 44, weight: .light, design: .rounded))
                        .foregroundColor(.freshPrimary)
                    Text("/ 28天")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }
            }
            
            // Stats Row
            HStack(spacing: 32) {
                VStack {
                    Text("\(session.checkIns.count)")
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)
                    Text("已打卡")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }
                
                VStack {
                    Text(session.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)
                    Text("开始日期")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }
                
                VStack {
                    Text("\(28 - session.duration)")
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)
                    Text("剩余天数")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }
            }
        }
        .freshGlassCard()
    }
    
    // MARK: - Timeline Section
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("追踪时间线")
                .font(.skinLabHeadline)
            
            // Check-in nodes
            HStack(spacing: 0) {
                ForEach([0, 7, 14, 21, 28], id: \.self) { day in
                    VStack(spacing: 8) {
                        timelineNode(for: day)
                        Text("Day \(day)")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                    }
                    
                    if day < 28 {
                        Rectangle()
                            .fill(isCompleted(day: day) ? Color.freshPrimary : Color.gray.opacity(0.2))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            
            // Check-in list
            ForEach(session.checkIns.sorted(by: { $0.day < $1.day })) { checkIn in
                CheckInRow(checkIn: checkIn)
            }
        }
        .freshGlassCard()
    }
    
    private func timelineNode(for day: Int) -> some View {
        let completed = isCompleted(day: day)
        let current = session.duration == day
        
        if completed {
            return AnyView(
                Circle()
                    .fill(Color.freshPrimary)
                    .frame(width: 24, height: 24)
                    .overlay(Image(systemName: "checkmark").font(.caption2).foregroundColor(.white))
            )
        } else if current {
            return AnyView(
                Circle()
                    .stroke(Color.freshPrimary, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay(Circle().fill(Color.freshPrimary).frame(width: 12, height: 12))
            )
        } else {
            return AnyView(
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 20, height: 20)
            )
        }
    }
    
    private func isCompleted(day: Int) -> Bool {
        session.checkIns.contains { $0.day == day }
    }
    
    // MARK: - Products Section
    private var productsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("使用的产品")
                    .font(.skinLabHeadline)
                
                Spacer()
                
                Button("添加") {
                    showProductPicker = true
                }
                .font(.skinLabSubheadline)
                .foregroundColor(.freshPrimary)
            }
            
            if session.targetProducts.isEmpty {
                Text("尚未添加产品")
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabSubtext)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(session.targetProducts, id: \.self) { productId in
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Text(productId)
                            .font(.skinLabBody)
                        
                        Spacer()
                    }
                }
            }
        }
        .freshGlassCard()
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if let nextDay = session.nextCheckInDay, nextDay <= session.duration {
                Button {
                    showCamera = true
                } label: {
                    Text("记录第 \(nextDay) 天")
                }
                .buttonStyle(FreshGlassButton(color: .freshPrimary))
            }

            if session.duration >= 28 && session.status == .active {
                Button {
                    viewModel?.completeSession(session)
                } label: {
                    Text("完成追踪")
                }
                .buttonStyle(FreshGlassButton(color: .freshPrimary))
            }

            Button {
                guard let viewModel = viewModel else { return }
                Task {
                    await viewModel.generateReport(for: session)
                }
            } label: {
                Text(viewModel?.isGeneratingReport == true ? "生成中..." : "生成报告")
            }
            .buttonStyle(FreshSecondaryButton())
            .disabled(viewModel?.isGeneratingReport == true || session.checkIns.count < 2)
        }
    }
}

// MARK: - Check-In Row
struct CheckInRow: View {
    let checkIn: CheckIn

    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Text("Day")
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
                Text("\(checkIn.day)")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabPrimary)
            }
            .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(checkIn.captureDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.skinLabSubheadline)
                    .foregroundColor(.skinLabText)

                if let feeling = checkIn.feeling {
                    HStack(spacing: 4) {
                        Image(systemName: feeling.icon)
                            .font(.caption)
                        Text(feeling.displayName)
                            .font(.skinLabCaption)
                    }
                    .foregroundColor(feelingColor(feeling))
                }
            }

            Spacer()

            // Reliability badge (persistent location in timeline list)
            if let reliability = checkIn.reliability {
                ReliabilityBadgeView(reliability: reliability, size: .small)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.skinLabSubtext)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func feelingColor(_ feeling: CheckIn.Feeling) -> Color {
        switch feeling {
        case .better: return .skinLabSuccess
        case .same: return .skinLabSubtext
        case .worse: return .skinLabWarning
        }
    }
}

// MARK: - Check-In View
struct CheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let session: TrackingSession
    let image: UIImage?
    let standardization: PhotoStandardizationMetadata?

    // Capture scheduled day ONCE when view opens (from session.nextCheckInDay)
    // This represents the checkpoint we're recording (0/7/14/21/28)
    private var scheduledDay: Int {
        guard let nextDay = session.nextCheckInDay else {
            // Fallback - shouldn't happen in valid check-in flow
            return session.duration
        }
        return nextDay
    }

    @State private var feeling: CheckIn.Feeling = .same
    @State private var notes: String = ""
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    // Lifestyle factors state
    @State private var sleepHours: Double = 7.0
    @State private var stressLevel: Int = 3
    @State private var waterIntakeLevel: Int = 3
    @State private var alcoholConsumed: Bool = false
    @State private var exerciseMinutes: Double = 0
    @State private var sunExposureLevel: Int = 2
    @State private var dietNotes: String = ""
    @State private var isLifestyleExpanded = false

    // User override for photo quality
    @State private var userFlaggedPhotoIssue = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Photo Preview
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                    }

                    // Photo Standardization Card
                    if let standardization = standardization {
                        photoStandardizationCard(standardization)
                    }

                    // Day Info
                    VStack {
                        Text("Day \(scheduledDay)")
                            .font(.skinLabTitle2)
                            .foregroundColor(.skinLabPrimary)

                        Text(Date().formatted(date: .complete, time: .omitted))
                            .font(.skinLabSubheadline)
                            .foregroundColor(.skinLabSubtext)
                    }

                    // Feeling Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("今天感觉皮肤怎么样？")
                            .font(.skinLabHeadline)

                        HStack(spacing: 16) {
                            ForEach([CheckIn.Feeling.better, .same, .worse], id: \.self) { f in
                                FeelingButton(feeling: f, isSelected: feeling == f) {
                                    feeling = f
                                }
                            }
                        }
                    }
                    .skinLabCard()

                    // Lifestyle Factors (DisclosureGroup)
                    DisclosureGroup(isExpanded: $isLifestyleExpanded) {
                        lifestyleInputsContent
                    } label: {
                        HStack {
                            Text("生活因素（可选）")
                                .font(.skinLabHeadline)
                            Spacer()
                            Text(lifestyleSummary)
                                .font(.skinLabSubheadline)
                                .foregroundColor(.skinLabSubtext)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("备注（可选）")
                            .font(.skinLabHeadline)

                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .skinLabCard()

                    // Disclaimer
                    Text("生活因素用于发现可能关联，不代表因果关系")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                        .multilineTextAlignment(.center)

                    // Save Button
                    Button {
                        saveCheckIn()
                    } label: {
                        if isAnalyzing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("保存记录")
                        }
                    }
                    .buttonStyle(SkinLabPrimaryButtonStyle())
                    .disabled(isAnalyzing)
                }
                .padding()
            }
            .navigationTitle("记录打卡")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .alert("保存失败", isPresented: .constant(errorMessage != nil)) {
            Button("确定") { errorMessage = nil }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Photo Standardization Card
    @ViewBuilder
    private func photoStandardizationCard(_ meta: PhotoStandardizationMetadata) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("拍照标准化")
                    .font(.skinLabHeadline)

                Spacer()

                // Status badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(meta.isReady ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)

                    Text(meta.isReady ? "良好" : "一般")
                        .font(.skinLabCaption)
                        .foregroundColor(meta.isReady ? .green : .orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(meta.isReady ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            // Conditions chips
            HStack(spacing: 8) {
                conditionChip("光线", meta.lighting)
                conditionChip("角度", angle: abs(meta.yawDegrees) + abs(meta.pitchDegrees))
                conditionChip("距离", meta.distance)
            }

            // Suggestions
            if !meta.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(meta.suggestions, id: \.self) { suggestion in
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(suggestion)
                                .font(.skinLabSubheadline)
                                .foregroundColor(.skinLabText)
                        }
                    }
                }
            }

            // User override toggle
            Toggle("本次照片不太标准", isOn: $userFlaggedPhotoIssue)
                .font(.skinLabSubheadline)
                .toggleStyle(SwitchToggleStyle(tint: .orange))
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    private func conditionChip(_ label: String, _ rating: PhotoStandardizationMetadata.LightingRating) -> some View {
        let (color, text) = chipInfo(for: rating)
        return chipContent(label: label, text: text, color: color)
    }

    private func conditionChip(_ label: String, angle: Double) -> some View {
        let (color, text): (Color, String) = angle < 15 ? (.green, "标准") : angle < 20 ? (.orange, "一般") : (.red, "偏差")
        return chipContent(label: label, text: text, color: color)
    }

    private func conditionChip(_ label: String, _ distance: PhotoStandardizationMetadata.DistanceRating) -> some View {
        let (color, text) = chipInfo(for: distance)
        return chipContent(label: label, text: text, color: color)
    }

    private func chipContent(label: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.skinLabCaption)
                .foregroundColor(.skinLabSubtext)
            Text(text)
                .font(.skinLabCaption)
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }

    private func chipInfo(for rating: PhotoStandardizationMetadata.LightingRating) -> (Color, String) {
        switch rating {
        case .optimal: return (.green, "良好")
        case .slightlyDark, .slightlyBright: return (.orange, "一般")
        case .tooDark, .tooBright: return (.red, "差")
        }
    }

    private func chipInfo(for rating: PhotoStandardizationMetadata.DistanceRating) -> (Color, String) {
        switch rating {
        case .optimal: return (.green, "良好")
        case .slightlyFar, .slightlyClose: return (.orange, "一般")
        case .tooFar, .tooClose: return (.red, "差")
        }
    }

    // MARK: - Lifestyle Inputs Content
    private var lifestyleInputsContent: some View {
        VStack(spacing: 16) {
            // Sleep hours
            VStack(alignment: .leading, spacing: 8) {
                Text("睡眠时间: \(Int(sleepHours))小时")
                    .font(.skinLabSubheadline)

                Slider(value: $sleepHours, in: 0...12, step: 0.5)
                Stepper("", value: $sleepHours, in: 0...12, step: 0.5)
                    .labelsHidden()
            }

            // Stress level
            VStack(alignment: .leading, spacing: 8) {
                Text("压力水平")
                    .font(.skinLabSubheadline)

                Picker("", selection: $stressLevel) {
                    Text("很低").tag(1)
                    Text("低").tag(2)
                    Text("一般").tag(3)
                    Text("高").tag(4)
                    Text("很高").tag(5)
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            // Water intake
            VStack(alignment: .leading, spacing: 8) {
                Text("饮水量")
                    .font(.skinLabSubheadline)

                Picker("", selection: $waterIntakeLevel) {
                    Text("少").tag(1)
                    Text("较少").tag(2)
                    Text("一般").tag(3)
                    Text("充足").tag(4)
                    Text("很多").tag(5)
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            // Exercise
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("运动时间: \(Int(exerciseMinutes))分钟")
                        .font(.skinLabSubheadline)
                    Spacer()
                }
                Stepper("", value: $exerciseMinutes, in: 0...180, step: 15)
                    .labelsHidden()
            }

            // Sun exposure
            VStack(alignment: .leading, spacing: 8) {
                Text("日晒程度")
                    .font(.skinLabSubheadline)

                Picker("", selection: $sunExposureLevel) {
                    Text("无").tag(1)
                    Text("少").tag(2)
                    Text("一般").tag(3)
                    Text("多").tag(4)
                    Text("很多").tag(5)
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            // Alcohol
            Toggle("饮酒", isOn: $alcoholConsumed)
                .font(.skinLabSubheadline)
        }
        .padding()
    }

    private var lifestyleSummary: String {
        var parts: [String] = []
        parts.append("睡眠\(Int(sleepHours))h")
        parts.append("压力\(stressLevel)")
        parts.append("日晒\(sunExposureLevel)")
        return parts.joined(separator: " · ")
    }

    @MainActor
    private func saveCheckIn() {
        guard let image = image else {
            dismiss()
            return
        }

        isAnalyzing = true

        Task {
            do {
                // 1. Save photo locally
                let photoPath = savePhoto()

                // 2. Analyze skin using AI
                let analysisService = GeminiService.shared
                let analysis = try await analysisService.analyzeSkin(image: image)

                // 3. Save analysis to database
                let analysisRecord = SkinAnalysisRecord(from: analysis, photoPath: photoPath)
                modelContext.insert(analysisRecord)
                try modelContext.save()

                // 4. Build lifestyle factors
                var lifestyle: LifestyleFactors?
                if sleepHours > 0 || exerciseMinutes > 0 || !dietNotes.isEmpty {
                    lifestyle = LifestyleFactors(
                        sleepHours: sleepHours > 0 ? sleepHours : nil,
                        stressLevel: stressLevel,
                        waterIntakeLevel: waterIntakeLevel,
                        alcoholConsumed: alcoholConsumed ? alcoholConsumed : nil,
                        exerciseMinutes: exerciseMinutes > 0 ? Int(exerciseMinutes) : nil,
                        sunExposureLevel: sunExposureLevel,
                        dietNotes: dietNotes.isEmpty ? nil : dietNotes
                    )
                }

                // 5. Build photo standardization with user override
                var updatedStandardization = standardization
                if userFlaggedPhotoIssue {
                    if var meta = standardization {
                        updatedStandardization = PhotoStandardizationMetadata(
                            capturedAt: meta.capturedAt,
                            cameraPosition: meta.cameraPosition,
                            captureSource: meta.captureSource,
                            lighting: meta.lighting,
                            faceDetected: meta.faceDetected,
                            yawDegrees: meta.yawDegrees,
                            pitchDegrees: meta.pitchDegrees,
                            rollDegrees: meta.rollDegrees,
                            distance: meta.distance,
                            isReady: meta.isReady,
                            suggestions: meta.suggestions,
                            userOverride: .userFlaggedIssue
                        )
                    }
                }

                // 6. Compute reliability at capture time
                let scorer = ReliabilityScorer()
                let preliminaryCheckIn = CheckIn(
                    sessionId: session.id,
                    day: scheduledDay,
                    captureDate: Date(),
                    photoPath: photoPath,
                    analysisId: analysis.id,
                    usedProducts: [],
                    notes: notes.isEmpty ? nil : notes,
                    feeling: feeling,
                    photoStandardization: updatedStandardization,
                    lifestyle: lifestyle,
                    reliability: nil  // Temporary, for scoring
                )

                let reliability = scorer.score(
                    checkIn: preliminaryCheckIn,
                    analysis: analysis,
                    session: session,
                    expectedDay: scheduledDay,  // Pass scheduled day as the checkpoint
                    cameraPositionConsistency: true
                )

                // 7. Create final check-in with reliability
                let checkIn = CheckIn(
                    sessionId: session.id,
                    day: scheduledDay,  // Use scheduled day, not session.duration
                    captureDate: Date(),
                    photoPath: photoPath,
                    analysisId: analysis.id,
                    usedProducts: [],
                    notes: notes.isEmpty ? nil : notes,
                    feeling: feeling,
                    photoStandardization: updatedStandardization,
                    lifestyle: lifestyle,
                    reliability: reliability  // Computed at capture time
                )

                // 8. Add to session
                session.addCheckIn(checkIn)

                await MainActor.run {
                    isAnalyzing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    errorMessage = "分析失败: \(error.localizedDescription)"
                }
            }
        }
    }

    private func savePhoto() -> String? {
        guard let image = image,
              let data = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }

        let filename = "\(session.id.uuidString)_day\(scheduledDay).jpg"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("tracking_photos", isDirectory: true)

        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)

        let fileURL = url.appendingPathComponent(filename)
        try? data.write(to: fileURL)

        return filename
    }
}

// MARK: - Feeling Button
struct FeelingButton: View {
    let feeling: CheckIn.Feeling
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: feeling.icon)
                    .font(.title2)
                
                Text(feeling.displayName)
                    .font(.skinLabCaption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.skinLabPrimary.opacity(0.1) : Color.gray.opacity(0.05))
            .foregroundColor(isSelected ? .skinLabPrimary : .skinLabText)
            .cornerRadius(12)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.skinLabPrimary : Color.clear, lineWidth: 2)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TrackingDetailView(session: TrackingSession())
    }
}
