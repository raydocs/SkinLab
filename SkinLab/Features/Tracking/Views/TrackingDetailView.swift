import SwiftUI
import SwiftData

struct TrackingDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var session: TrackingSession
    
    @State private var showCamera = false
    @State private var showCheckIn = false
    @State private var capturedImage: UIImage?
    @State private var isGeneratingReport = false
    @State private var generatedReport: EnhancedTrackingReport?
    @State private var showReport = false
    @State private var reportError: String?
    @Query private var allAnalyses: [SkinAnalysisRecord]
    
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
        .sheet(isPresented: $showCheckIn) {
            CheckInView(session: session, image: capturedImage)
        }
        .sheet(isPresented: $showReport) {
            if let report = generatedReport {
                NavigationStack {
                    TrackingReportView(report: report)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("完成") {
                                    showReport = false
                                }
                            }
                        }
                }
            }
        }
        .alert("报告生成失败", isPresented: .constant(reportError != nil)) {
            Button("确定") {
                reportError = nil
            }
        } message: {
            if let error = reportError {
                Text(error)
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPreviewView(capturedImage: $capturedImage)
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
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: session.progress)
                    .stroke(Color.skinLabPrimary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(session.duration)")
                        .font(.skinLabScoreLarge)
                        .foregroundColor(.skinLabPrimary)
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
        .skinLabCard()
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
                            .fill(isCompleted(day: day) ? Color.skinLabPrimary : Color.gray.opacity(0.3))
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
        .skinLabCard()
    }
    
    private func timelineNode(for day: Int) -> some View {
        let completed = isCompleted(day: day)
        let current = session.duration == day
        
        return Circle()
            .fill(completed ? Color.skinLabPrimary : (current ? Color.skinLabAccent : Color.gray.opacity(0.3)))
            .frame(width: 32, height: 32)
            .overlay {
                if completed {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.white)
                } else if current {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                }
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
                    // TODO: Add product
                }
                .font(.skinLabSubheadline)
                .foregroundColor(.skinLabPrimary)
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
        .skinLabCard()
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if let nextDay = session.nextCheckInDay, nextDay <= session.duration {
                Button {
                    showCamera = true
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("记录 Day \(nextDay)")
                    }
                }
                .buttonStyle(SkinLabPrimaryButtonStyle())
            }
            
            if session.duration >= 28 && session.status == .active {
                Button {
                    completeSession()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("完成追踪")
                    }
                }
                .buttonStyle(SkinLabPrimaryButtonStyle())
            }
            
            Button {
                Task {
                    await generateReport()
                }
            } label: {
                HStack {
                    if isGeneratingReport {
                        ProgressView()
                            .tint(.skinLabPrimary)
                    } else {
                        Image(systemName: "doc.text")
                    }
                    Text(isGeneratingReport ? "生成中..." : "生成报告")
                }
            }
            .buttonStyle(SkinLabSecondaryButtonStyle())
            .disabled(isGeneratingReport || session.checkIns.count < 2)
        }
    }
    
    // MARK: - Report Generation
    private func generateReport() async {
        isGeneratingReport = true
        reportError = nil
        
        do {
            // Convert SkinAnalysisRecord to SkinAnalysis and create dictionary
            var analysisDict: [UUID: SkinAnalysis] = [:]
            for record in allAnalyses {
                if let analysis = record.toAnalysis() {
                    analysisDict[record.id] = analysis
                }
            }
            
            // Generate report
            let generator = TrackingReportGenerator()
            if let report = await generator.generateReport(
                session: session,
                checkIns: session.checkIns,
                analyses: analysisDict
            ) {
                await MainActor.run {
                    generatedReport = report
                    showReport = true
                    isGeneratingReport = false
                }
            } else {
                await MainActor.run {
                    reportError = "需要至少2次打卡记录才能生成报告"
                    isGeneratingReport = false
                }
            }
        } catch {
            await MainActor.run {
                reportError = error.localizedDescription
                isGeneratingReport = false
            }
        }
    }
    
    private func completeSession() {
        session.status = .completed
        session.endDate = Date()
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
    
    @State private var feeling: CheckIn.Feeling = .same
    @State private var notes: String = ""
    @State private var isAnalyzing = false
    
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
                    
                    // Day Info
                    VStack {
                        Text("Day \(session.duration)")
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
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("备注（可选）")
                            .font(.skinLabHeadline)
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .skinLabCard()
                    
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
    }
    
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

                // 4. Create check-in with analysis ID
                let checkIn = CheckIn(
                    sessionId: session.id,
                    day: session.duration,
                    photoPath: photoPath,
                    analysisId: analysis.id,  // ✅ 关联分析结果
                    notes: notes.isEmpty ? nil : notes,
                    feeling: feeling
                )

                // 5. Add to session
                session.addCheckIn(checkIn)

                await MainActor.run {
                    isAnalyzing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    // TODO: Show error alert to user
                    print("分析失败: \(error.localizedDescription)")
                    dismiss()
                }
            }
        }
    }
    
    private func savePhoto() -> String? {
        guard let image = image,
              let data = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        let filename = "\(session.id.uuidString)_day\(session.duration).jpg"
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
