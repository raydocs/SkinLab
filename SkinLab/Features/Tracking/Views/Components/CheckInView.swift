import SwiftUI
import SwiftData

// MARK: - Check-In View
struct CheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let session: TrackingSession
    let image: UIImage?
    let standardization: PhotoStandardizationMetadata?

    @State private var feeling: CheckIn.Feeling = .same
    @State private var notes: String = ""
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    // Capture scheduled day ONCE when view opens (from session.nextCheckInDay)
    // This represents the checkpoint we're recording (0/7/14/21/28)
    @State private var scheduledDay: Int?

    // Lifestyle factors state - now truly optional
    @State private var includeLifestyle = false
    @State private var lifestyleDraft = LifestyleDraft()

    // User override for photo quality
    @State private var userFlaggedPhotoIssue = false

    // Product selection
    @State private var selectedProducts: [String] = []
    @State private var showProductPicker = false

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
                        if let day = scheduledDay {
                            Text("Day \(day)")
                                .font(.skinLabTitle2)
                                .foregroundColor(.skinLabPrimary)
                        } else {
                            Text("无可用打卡节点")
                                .font(.skinLabTitle2)
                                .foregroundColor(.red)
                        }

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

                    // Product Selection
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("使用的产品")
                                .font(.skinLabHeadline)

                            Text("可选")
                                .font(.skinLabCaption)
                                .foregroundColor(.skinLabSubtext)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.skinLabPrimary.opacity(0.1))
                                )
                        }

                        if selectedProducts.isEmpty {
                            Text("未选择产品")
                                .font(.skinLabSubheadline)
                                .foregroundColor(.skinLabSubtext)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(selectedProducts, id: \.self) { product in
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.skinLabPrimary)
                                        Text(product)
                                            .font(.skinLabSubheadline)
                                            .foregroundColor(.skinLabText)
                                    }
                                }
                            }
                        }

                        Button {
                            showProductPicker = true
                        } label: {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.skinLabPrimary.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: selectedProducts.isEmpty ? "plus" : "pencil")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.skinLabPrimary)
                                }
                                Text(selectedProducts.isEmpty ? "选择产品" : "修改选择")
                                    .font(.skinLabSubheadline)
                                    .foregroundColor(.skinLabPrimary)
                            }
                        }
                    }
                    .skinLabCard()

                    // Lifestyle Factors (DisclosureGroup - now truly optional)
                    DisclosureGroup(isExpanded: $includeLifestyle) {
                        if includeLifestyle {
                            lifestyleInputsContent
                        }
                    } label: {
                        HStack {
                            Text("生活因素（可选）")
                                .font(.skinLabHeadline)
                                .foregroundColor(.skinLabText)
                            Spacer()
                            if !includeLifestyle || !lifestyleDraft.hasAnyData {
                                Text("未记录")
                                    .font(.skinLabSubheadline)
                                    .foregroundColor(.skinLabSubtext)
                            } else {
                                Text(lifestyleDraft.summary)
                                    .font(.skinLabSubheadline)
                                    .foregroundColor(.skinLabSubtext)
                            }
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
        .onAppear {
            // Capture scheduled day ONCE when view opens
            scheduledDay = session.nextCheckInDay
            // Pre-populate with session's target products if available
            selectedProducts = session.targetProducts
        }
        .sheet(isPresented: $showProductPicker) {
            ProductPickerView(selectedProducts: $selectedProducts)
        }
        .alert("保存失败", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("确定") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
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
                Text("睡眠时间: \(lifestyleDraft.sleepHours.map { "\($0)" } ?? "未填写")小时")
                    .font(.skinLabSubheadline)

                Slider(value: Binding(
                    get: { lifestyleDraft.sleepHours ?? 0 },
                    set: { lifestyleDraft.sleepHours = $0 == 0 ? nil : $0 }
                ), in: 0...12, step: 0.5)
                Stepper("", value: Binding(
                    get: { lifestyleDraft.sleepHours ?? 0 },
                    set: { lifestyleDraft.sleepHours = $0 == 0 ? nil : $0 }
                ), in: 0...12, step: 0.5)
                    .labelsHidden()
            }

            // Stress level
            VStack(alignment: .leading, spacing: 8) {
                Text("压力水平")
                    .font(.skinLabSubheadline)

                Picker("", selection: Binding(
                    get: { lifestyleDraft.stressLevel ?? 3 },
                    set: { lifestyleDraft.stressLevel = $0 }
                )) {
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

                Picker("", selection: Binding(
                    get: { lifestyleDraft.waterIntakeLevel ?? 3 },
                    set: { lifestyleDraft.waterIntakeLevel = $0 }
                )) {
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
                    Text("运动时间: \(lifestyleDraft.exerciseMinutes.map { "\($0)" } ?? "未填写")分钟")
                        .font(.skinLabSubheadline)
                    Spacer()
                }
                Stepper("", value: Binding(
                    get: { lifestyleDraft.exerciseMinutes ?? 0 },
                    set: { lifestyleDraft.exerciseMinutes = $0 == 0 ? nil : $0 }
                ), in: 0...180, step: 15)
                    .labelsHidden()
            }

            // Sun exposure
            VStack(alignment: .leading, spacing: 8) {
                Text("日晒程度")
                    .font(.skinLabSubheadline)

                Picker("", selection: Binding(
                    get: { lifestyleDraft.sunExposureLevel ?? 2 },
                    set: { lifestyleDraft.sunExposureLevel = $0 }
                )) {
                    Text("无").tag(1)
                    Text("少").tag(2)
                    Text("一般").tag(3)
                    Text("多").tag(4)
                    Text("很多").tag(5)
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            // Alcohol
            Toggle("饮酒", isOn: Binding(
                get: { lifestyleDraft.alcoholConsumed ?? false },
                set: { lifestyleDraft.alcoholConsumed = $0 ? true : nil }
            ))
            .font(.skinLabSubheadline)
        }
        .padding()
    }

    @MainActor
    private func saveCheckIn() {
        guard let image = image else {
            dismiss()
            return
        }

        // CRITICAL: Guard scheduledDay was captured successfully
        guard let scheduledDay = scheduledDay else {
            errorMessage = "当前没有可记录的打卡节点"
            return
        }

        isAnalyzing = true

        Task { @MainActor in
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

                // 4. Build lifestyle factors - only if user opted in AND provided data
                var lifestyle: LifestyleFactors?
                if includeLifestyle && lifestyleDraft.hasAnyData {
                    lifestyle = LifestyleFactors(
                        sleepHours: lifestyleDraft.sleepHours,
                        stressLevel: lifestyleDraft.stressLevel,
                        waterIntakeLevel: lifestyleDraft.waterIntakeLevel,
                        alcoholConsumed: lifestyleDraft.alcoholConsumed,
                        exerciseMinutes: lifestyleDraft.exerciseMinutes,
                        sunExposureLevel: lifestyleDraft.sunExposureLevel,
                        dietNotes: lifestyleDraft.dietNotes
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
                    usedProducts: selectedProducts,
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
                    usedProducts: selectedProducts,
                    notes: notes.isEmpty ? nil : notes,
                    feeling: feeling,
                    photoStandardization: updatedStandardization,
                    lifestyle: lifestyle,
                    reliability: reliability  // Computed at capture time
                )

                // 8. Add to session and save (CRITICAL: persist SwiftData changes)
                session.addCheckIn(checkIn)
                try modelContext.save()  // Ensure check-in is persisted

                isAnalyzing = false
                dismiss()
            } catch {
                isAnalyzing = false
                errorMessage = "分析失败: \(error.localizedDescription)"
            }
        }
    }

    private func savePhoto() -> String? {
        guard let image = image,
              let data = image.jpegData(compressionQuality: 0.8),
              let scheduledDay = scheduledDay else {
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
