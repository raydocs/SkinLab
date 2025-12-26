import SwiftUI
import SwiftData

struct AnalysisResultView: View {
    let analysis: SkinAnalysis
    @State private var selectedTab = 0
    @State private var animateScore = false
    @State private var isGeneratingRoutine = false
    @State private var generatedRoutine: SkincareRoutine?
    @State private var showRoutine = false
    @State private var routineError: String?
    @State private var showNewTracking = false
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var trackingSessions: [TrackingSession]
    @Query private var ingredientPreferences: [UserIngredientPreference]

    private var userProfile: UserProfile? {
        profiles.first
    }

    private var historyStore: UserHistoryStore {
        UserHistoryStore(modelContext: modelContext)
    }

    private var negativeIngredients: [String] {
        ingredientPreferences
            .filter { $0.preferenceType == .disliked || $0.preferenceType == .avoided }
            .map { $0.ingredientName }
    }
    
    var body: some View {
        ZStack {
            // 背景渐变
            Color.skinLabBackground.ignoresSafeArea()
            
            Circle()
                .fill(LinearGradient.skinLabRoseGradient)
                .frame(width: 250, height: 250)
                .blur(radius: 100)
                .offset(x: -80, y: -300)
                .opacity(0.4)
            
            Circle()
                .fill(LinearGradient.skinLabLavenderGradient)
                .frame(width: 200, height: 200)
                .blur(radius: 80)
                .offset(x: 120, y: 200)
                .opacity(0.3)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    scoreHeader
                    skinTypeBadge
                    confidenceCard
                    trackingEntryCard
                    primaryActions
                    tabSelector
                    selectedContent
                }
                .padding()
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                    Text("分析结果")
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animateScore = true
            }
        }
        .sheet(isPresented: $showRoutine) {
            if let routine = generatedRoutine {
                NavigationStack {
                    RoutineView(routine: routine)
                }
            }
        }
        .sheet(isPresented: $showNewTracking) {
            NavigationStack {
                TrackingView()
            }
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(["问题", "区域", "建议"].indices, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = index
                    }
                } label: {
                    Text(["问题", "区域", "建议"][index])
                        .font(.skinLabHeadline)
                        .foregroundColor(selectedTab == index ? .white : .skinLabSubtext)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedTab == index
                                ? LinearGradient.skinLabPrimaryGradient
                                : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                }
            }
        }
        .padding(4)
        .background(Color.skinLabCardBackground)
        .cornerRadius(16)
        .skinLabSoftShadow()
    }
    
    // MARK: - Selected Content
    @ViewBuilder
    private var selectedContent: some View {
        switch selectedTab {
        case 0:
            issuesSection
        case 1:
            regionsSection
        case 2:
            recommendationsSection
        default:
            EmptyView()
        }
    }
    
    // MARK: - Score Header
    private var scoreHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                // 装饰闪光
                SparkleView(size: 14)
                    .offset(x: 70, y: -60)
                
                SparkleView(size: 10)
                    .offset(x: -75, y: 50)
                
                ScoreRing(score: animateScore ? analysis.overallScore : 0, size: 150)
            }
            
            // 分数评语
            Text(scoreComment)
                .font(.skinLabSubheadline)
                .foregroundColor(.skinLabPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.skinLabPrimary.opacity(0.1))
                .cornerRadius(20)
            
            HStack(spacing: 32) {
                StatItem(label: "皮肤年龄", value: "\(analysis.skinAge)岁", icon: "clock.fill")
                
                Divider()
                    .frame(height: 30)
                
                StatItem(label: "分析时间", value: analysis.analyzedAt.formatted(date: .abbreviated, time: .omitted), icon: "calendar")
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal)
        .background(Color.skinLabCardBackground)
        .cornerRadius(24)
        .skinLabSoftShadow(radius: 15, y: 8)
    }
    
    private var scoreComment: String {
        switch analysis.overallScore {
        case 80...100: return "肌肤状态很棒！继续保持～"
        case 60..<80: return "肌肤状态良好，还有提升空间"
        case 40..<60: return "需要更多关注和护理"
        default: return "建议认真对待护肤问题"
        }
    }
    
    // MARK: - Routine Generation
    private func generateRoutine() async {
        isGeneratingRoutine = true
        routineError = nil

        do {
            // Get recent tracking report if available
            let trackingReport: EnhancedTrackingReport? = await getRecentTrackingReport()

            let service = RoutineService()
            let routine = try await service.generateRoutine(
                analysis: analysis,
                profile: userProfile,
                trackingReport: trackingReport,
                negativeIngredients: negativeIngredients
            )

            // Save to SwiftData
            let record = SkincareRoutineRecord(from: routine)
            modelContext.insert(record)
            try modelContext.save()

            // Show routine
            await MainActor.run {
                generatedRoutine = routine
                showRoutine = true
                isGeneratingRoutine = false
            }
        } catch {
            await MainActor.run {
                routineError = error.localizedDescription
                isGeneratingRoutine = false
            }
        }
    }

    private func getRecentTrackingReport() async -> EnhancedTrackingReport? {
        // Find most recent completed tracking session
        guard let recentSession = trackingSessions
            .filter({ $0.status == .completed && $0.checkIns.count >= 2 })
            .sorted(by: { $0.startDate > $1.startDate })
            .first else {
            return nil
        }

        // Collect analyses for the check-ins
        var analyses: [UUID: SkinAnalysis] = [:]
        for checkIn in recentSession.checkIns {
            if let analysisId = checkIn.analysisId {
                // Fetch analysis from SwiftData
                let descriptor = FetchDescriptor<SkinAnalysisRecord>(
                    predicate: #Predicate<SkinAnalysisRecord> { $0.id == analysisId }
                )
                if let record = try? modelContext.fetch(descriptor).first,
                   let skinAnalysis = record.toAnalysis() {
                    analyses[analysisId] = skinAnalysis
                }
            }
        }

        guard !analyses.isEmpty else { return nil }

        // Generate report using TrackingReportGenerator
        let generator = TrackingReportGenerator(geminiService: GeminiService.shared)
        return await generator.generateReport(
            session: recentSession,
            checkIns: recentSession.checkIns,
            analyses: analyses,
            productDatabase: [:]  // Could be enhanced with actual product database
        )
    }

    // MARK: - Skin Type Badge
    private var skinTypeBadge: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient.skinLabPrimaryGradient.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: analysis.skinType.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("你的肤质")
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
                
                Text(analysis.skinType.displayName)
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
            }
            
            Spacer()
            
            Image(systemName: "info.circle")
                .foregroundColor(.skinLabSubtext)
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(16)
        .skinLabSoftShadow()
    }

    // MARK: - Confidence Card
    @ViewBuilder
    private var confidenceCard: some View {
        if analysis.confidenceScore < 80 || analysis.imageQuality != nil {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(confidenceColor.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: confidenceIcon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(confidenceColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("分析可信度")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                        
                        Text("\(analysis.confidenceScore)%")
                            .font(.skinLabHeadline)
                            .foregroundColor(.skinLabText)
                    }
                    
                    Spacer()
                    
                    // Quality indicator
                    if let quality = analysis.imageQuality {
                        let avgQuality = (quality.lighting + quality.sharpness + quality.angle + quality.occlusion + quality.faceCoverage) / 5
                        Text(avgQuality >= 80 ? "照片质量良好" : "照片质量一般")
                            .font(.skinLabCaption)
                            .foregroundColor(avgQuality >= 80 ? .skinLabSuccess : .skinLabWarning)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background((avgQuality >= 80 ? Color.skinLabSuccess : Color.skinLabWarning).opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                
                // Quality notes if available
                if let quality = analysis.imageQuality, !quality.notes.isEmpty {
                    Divider()
                        .background(Color.skinLabSubtext.opacity(0.2))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("拍照建议")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                        
                        ForEach(quality.notes, id: \.self) { note in
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.skinLabWarning)
                                
                                Text(note)
                                    .font(.skinLabCaption)
                                    .foregroundColor(.skinLabText)
                            }
                        }
                        
                        // Suggest retake if confidence is low
                        if analysis.confidenceScore < 70 {
                            Button {
                                // TODO: Navigate to camera view
                            } label: {
                                HStack {
                                    Image(systemName: "camera.fill")
                                    Text("重新拍照")
                                }
                                .font(.skinLabSubheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(LinearGradient.skinLabPrimaryGradient)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.skinLabCardBackground)
            .cornerRadius(16)
            .skinLabSoftShadow()
        }
    }
    
    private var confidenceColor: Color {
        if analysis.confidenceScore >= 80 {
            return .skinLabSuccess
        } else if analysis.confidenceScore >= 60 {
            return .skinLabWarning
        } else {
            return .skinLabError
        }
    }
    
    private var confidenceIcon: String {
        if analysis.confidenceScore >= 80 {
            return "checkmark.shield.fill"
        } else if analysis.confidenceScore >= 60 {
            return "exclamationmark.shield.fill"
        } else {
            return "xmark.shield.fill"
        }
    }

    // MARK: - Tracking Entry Card
    @ViewBuilder
    private var trackingEntryCard: some View {
        let activeSession = trackingSessions.first { $0.status == .active }
        
        if activeSession == nil {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.skinLabLavenderGradient.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 20))
                            .foregroundStyle(LinearGradient.skinLabLavenderGradient)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("开始28天效果验证")
                            .font(.skinLabHeadline)
                            .foregroundColor(.skinLabText)
                        
                        Text("用数据证明护肤效果")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                    }
                    
                    Spacer()
                }
                
                Divider()
                    .background(Color.skinLabSubtext.opacity(0.2))
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.skinLabSuccess)
                        Text("将本次分析作为第0天基准")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabText)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.skinLabSuccess)
                        Text("定期记录皮肤变化")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabText)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.skinLabSuccess)
                        Text("生成可视化效果报告")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabText)
                    }
                }
                
                Button {
                    showNewTracking = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("立即开始追踪")
                    }
                    .font(.skinLabSubheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(LinearGradient.skinLabLavenderGradient)
                    .cornerRadius(14)
                }
            }
            .padding()
            .background(Color.skinLabCardBackground)
            .cornerRadius(16)
            .skinLabSoftShadow()
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(LinearGradient.skinLabLavenderGradient.opacity(0.3), lineWidth: 1.5)
            )
        }
    }

    // MARK: - Primary Actions
    private var primaryActions: some View {
        VStack(spacing: 12) {
            // Generate Routine Button
            Button {
                Task {
                    await generateRoutine()
                }
            } label: {
                HStack(spacing: 12) {
                    if isGeneratingRoutine {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "list.bullet.rectangle.fill")
                    }
                    Text(isGeneratingRoutine ? "生成中..." : "生成护肤方案")
                    Spacer()
                    if !isGeneratingRoutine {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .buttonStyle(SkinLabPrimaryButtonStyle())
            .disabled(isGeneratingRoutine)
            
            NavigationLink {
                TrackingView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                    Text("开始28天追踪")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .buttonStyle(SkinLabPrimaryButtonStyle())

            NavigationLink {
                ProductsView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                    Text("查看推荐产品")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.skinLabPrimary.opacity(0.7))
                }
            }
            .buttonStyle(SkinLabSecondaryButtonStyle())
        }
        .sheet(isPresented: $showRoutine) {
            if let routine = generatedRoutine {
                NavigationStack {
                    RoutineView(routine: routine)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("完成") {
                                    showRoutine = false
                                }
                            }
                        }
                }
            }
        }
        .alert("生成失败", isPresented: .constant(routineError != nil)) {
            Button("确定") {
                routineError = nil
            }
        } message: {
            if let error = routineError {
                Text(error)
            }
        }
    }
    
    // MARK: - Issues Section
    private var issuesSection: some View {
        VStack(spacing: 14) {
            IssueRow(name: "色斑", score: analysis.issues.spots, icon: "circle.lefthalf.filled")
            IssueRow(name: "痘痘", score: analysis.issues.acne, icon: "circle.fill")
            IssueRow(name: "毛孔", score: analysis.issues.pores, icon: "circle.grid.3x3")
            IssueRow(name: "皱纹", score: analysis.issues.wrinkles, icon: "water.waves")
            IssueRow(name: "红血丝", score: analysis.issues.redness, icon: "flame")
            IssueRow(name: "肤色不均", score: analysis.issues.evenness, icon: "paintpalette")
            IssueRow(name: "纹理", score: analysis.issues.texture, icon: "square.grid.3x3")
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }
    
    // MARK: - Regions Section
    private var regionsSection: some View {
        VStack(spacing: 14) {
            RegionRow(name: "T区", score: analysis.regions.tZone)
            RegionRow(name: "左脸颊", score: analysis.regions.leftCheek)
            RegionRow(name: "右脸颊", score: analysis.regions.rightCheek)
            RegionRow(name: "眼周", score: analysis.regions.eyeArea)
            RegionRow(name: "下巴", score: analysis.regions.chin)
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }
    
    // MARK: - Recommendations Section
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(analysis.recommendations.enumerated()), id: \.offset) { index, recommendation in
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.skinLabPrimaryGradient)
                            .frame(width: 32, height: 32)
                        
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Text(recommendation)
                        .font(.skinLabBody)
                        .foregroundColor(.skinLabText)
                        .lineSpacing(4)
                }
                
                if index < analysis.recommendations.count - 1 {
                    Divider()
                        .padding(.leading, 46)
                }
            }
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow()
    }
}

// MARK: - Score Ring
struct ScoreRing: View {
    let score: Int
    let size: CGFloat
    
    private var color: Color {
        Color.scoreColor(for: score)
    }
    
    var body: some View {
        ZStack {
            // 外层装饰环
            Circle()
                .stroke(color.opacity(0.1), lineWidth: 20)
                .frame(width: size, height: size)
            
            // 进度环
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(
                    LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.0), value: score)
            
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                
                Text("综合评分")
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
            }
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let label: String
    let value: String
    var icon: String = ""
    
    var body: some View {
        VStack(spacing: 6) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.skinLabSecondary)
            }
            
            Text(value)
                .font(.skinLabHeadline)
                .foregroundColor(.skinLabText)
            
            Text(label)
                .font(.skinLabCaption)
                .foregroundColor(.skinLabSubtext)
        }
    }
}

// MARK: - Issue Row
struct IssueRow: View {
    let name: String
    let score: Int
    let icon: String
    
    private var color: Color {
        switch score {
        case 0...3: return .skinLabSuccess
        case 4...6: return .skinLabWarning
        default: return .skinLabError
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            
            Text(name)
                .font(.skinLabBody)
                .foregroundColor(.skinLabText)
            
            Spacer()
            
            ProgressBarView(progress: CGFloat(score) / 10, color: color, width: 80)
            
            Text("\(score)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .frame(width: 24)
        }
    }
}

// MARK: - Region Row
struct RegionRow: View {
    let name: String
    let score: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Text(name)
                .font(.skinLabBody)
                .foregroundColor(.skinLabText)
                .frame(width: 50, alignment: .leading)
            
            Spacer()
            
            ProgressBarView(progress: CGFloat(score) / 100, color: Color.scoreColor(for: score), width: 140)
            
            Text("\(score)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Color.scoreColor(for: score))
                .frame(width: 32)
        }
    }
}

// MARK: - Progress Bar View
struct ProgressBarView: View {
    let progress: CGFloat
    let color: Color
    let width: CGFloat
    
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(color.opacity(0.15))
                .frame(width: width, height: 8)
            
            Capsule()
                .fill(LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                .frame(width: width * min(progress, 1.0), height: 8)
                .animation(.easeOut(duration: 0.5), value: progress)
        }
    }
}

#Preview {
    NavigationStack {
        AnalysisResultView(analysis: .mock)
    }
}
