import SwiftUI
import SwiftData

struct AnalysisResultView: View {
    let result: AnalysisRunResult
    let onRetake: () -> Void

    @State private var viewModel: AnalysisResultViewModel?
    @State private var selectedTab = 0
    @State private var animateScore = false
    @State private var navigateToTracking: Bool = false
    @State private var createdSession: TrackingSession?

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var trackingSessions: [TrackingSession]
    @Query private var ingredientPreferences: [UserIngredientPreference]

    private var analysis: SkinAnalysis {
        result.analysis
    }

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

    init(result: AnalysisRunResult, onRetake: @escaping () -> Void = {}) {
        self.result = result
        self.onRetake = onRetake
    }

    // MARK: - Actions
    private func startTrackingFromAnalysis() {
        guard let viewModel = viewModel else {
            // Initialize viewModel if needed
            return
        }

        Task { @MainActor in
            do {
                let session = try await viewModel.startTrackingBaseline(
                    analysisRecordId: result.analysisId,
                    photoPath: result.photoPath,
                    standardization: result.standardization
                )
                createdSession = session
                navigateToTracking = true
            } catch {
                // Show error to user (viewModel is guaranteed non-nil after guard)
                viewModel.trackingError = error.localizedDescription
                viewModel.showTrackingError = true
            }
        }
    }

    var body: some View {
        ZStack {
            // 背景渐变
            FreshBackgroundMesh()
            
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
                    Image(systemName: "wand.and.stars")
                        .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                    Text("分析结果")
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)
                }
            }
        }
        .onAppear {
            // Initialize ViewModel with modelContext
            if viewModel == nil {
                viewModel = AnalysisResultViewModel(modelContext: modelContext)
            }

            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animateScore = true
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.showRoutine ?? false },
            set: { viewModel?.showRoutine = $0 }
        )) {
            if let routine = viewModel?.generatedRoutine {
                NavigationStack {
                    RoutineView(routine: routine)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("完成") {
                                    viewModel?.showRoutine = false
                                }
                            }
                        }
                }
            }
        }
        .navigationDestination(isPresented: $navigateToTracking) {
            if let session = createdSession {
                TrackingDetailView(session: session)
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
                        .foregroundColor(selectedTab == index ? .freshPrimary : .skinLabSubtext)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == index ? Color.freshPrimary.opacity(0.1) : Color.clear)
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
                ScoreRing(score: animateScore ? analysis.overallScore : 0, size: 150)
            }
            
            // 分数评语
            Text(scoreComment)
                .font(.skinLabSubheadline)
                .foregroundColor(.freshPrimaryDark)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.freshPrimary.opacity(0.1))
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
        .freshGlassCard()
    }
    
    private var scoreComment: String {
        switch analysis.overallScore {
        case 80...100: return "肌肤状态很棒！继续保持～"
        case 60..<80: return "肌肤状态良好，还有提升空间"
        case 40..<60: return "需要更多关注和护理"
        default: return "建议认真对待护肤问题"
        }
    }

    // MARK: - Skin Type Badge
    private var skinTypeBadge: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.freshPrimary.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: analysis.skinType.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.freshPrimary)
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
        .freshGlassCard()
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
                                onRetake()
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
                            .fill(Color.freshSecondary.opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.freshSecondary)
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
                    startTrackingFromAnalysis()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("立即开始追踪")
                    }
                    .font(.skinLabSubheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.freshSecondary)
                    .cornerRadius(14)
                }
            }
            .padding()
            .freshGlassCard()
        }
    }

    // MARK: - Primary Actions
    private var primaryActions: some View {
        VStack(spacing: 12) {
            // Generate Routine Button
            Button {
                guard let viewModel = viewModel else { return }
                Task {
                    await viewModel.generateRoutine(
                        analysis: analysis,
                        userProfile: userProfile,
                        trackingSessions: trackingSessions,
                        negativeIngredients: negativeIngredients
                    )
                }
            } label: {
                HStack(spacing: 12) {
                    if viewModel?.isGeneratingRoutine == true {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "list.bullet.rectangle.fill")
                    }
                    Text(viewModel?.isGeneratingRoutine == true ? "生成中..." : "生成护肤方案")
                    Spacer()
                    if viewModel?.isGeneratingRoutine != true {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .buttonStyle(FreshGlassButton(color: .freshPrimary))
            .disabled(viewModel?.isGeneratingRoutine == true)
            
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
            .buttonStyle(FreshGlassButton(color: .freshSecondary))

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
            .buttonStyle(FreshSecondaryButton())
        }
        .alert("生成失败", isPresented: Binding(
            get: { viewModel?.showRoutineError ?? false },
            set: { viewModel?.showRoutineError = $0 }
        )) {
            Button("确定") {
                viewModel?.showRoutineError = false
                viewModel?.routineError = nil
            }
        } message: {
            if let error = viewModel?.routineError {
                Text(error)
            }
        }
        .alert("开始追踪失败", isPresented: Binding(
            get: { viewModel?.showTrackingError ?? false },
            set: { viewModel?.showTrackingError = $0 }
        )) {
            Button("确定") {
                viewModel?.showTrackingError = false
                viewModel?.trackingError = nil
            }
        } message: {
            if let error = viewModel?.trackingError {
                Text(error)
            }
        }
    }

    // MARK: - Issues Section
    private var issuesSection: some View {
        VStack(spacing: 16) {
            // Primary issues (top 3 most severe) - always visible
            let sortedIssues = issuesSorted
            let primaryIssues = Array(sortedIssues.prefix(3))
            let secondaryIssues = Array(sortedIssues.dropFirst(3))

            // Key issues summary
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("主要关注")
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)
                    Spacer()
                    Text("\(primaryIssues.filter { $0.score >= 5 }.count)项需关注")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabWarning)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.skinLabWarning.opacity(0.1))
                        .cornerRadius(6)
                }

                ForEach(primaryIssues, id: \.name) { issue in
                    IssueRow(name: issue.name, score: issue.score, icon: issue.icon)
                }
            }
            .padding()
            .freshGlassCard()

            // Secondary issues - collapsible
            if !secondaryIssues.isEmpty {
                ProgressiveDisclosureCard(
                    title: "其他指标",
                    systemImage: "list.bullet"
                ) {
                    Text("\(secondaryIssues.count)项")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.skinLabSubtext.opacity(0.1))
                        .cornerRadius(6)
                } detail: {
                    VStack(spacing: 14) {
                        ForEach(secondaryIssues, id: \.name) { issue in
                            IssueRow(name: issue.name, score: issue.score, icon: issue.icon)
                        }
                    }
                }
            }
        }
    }

    /// Helper to sort issues by severity (highest score first)
    private var issuesSorted: [(name: String, score: Int, icon: String)] {
        [
            ("色斑", analysis.issues.spots, "circle.lefthalf.filled"),
            ("痘痘", analysis.issues.acne, "circle.fill"),
            ("毛孔", analysis.issues.pores, "circle.grid.3x3"),
            ("皱纹", analysis.issues.wrinkles, "water.waves"),
            ("红血丝", analysis.issues.redness, "flame"),
            ("肤色不均", analysis.issues.evenness, "paintpalette"),
            ("纹理", analysis.issues.texture, "square.grid.3x3")
        ].sorted { $0.score > $1.score }
    }
    
    // MARK: - Regions Section
    private var regionsSection: some View {
        VStack(spacing: 16) {
            // Primary regions (lowest scores first - needs most attention)
            let sortedRegions = regionsSorted
            let needsAttention = sortedRegions.filter { $0.score < 70 }
            let healthyRegions = sortedRegions.filter { $0.score >= 70 }

            // Regions needing attention - prominent display
            if !needsAttention.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("需要关注")
                            .font(.skinLabHeadline)
                            .foregroundColor(.skinLabText)
                        Spacer()
                        Text("\(needsAttention.count)个区域")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabWarning)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.skinLabWarning.opacity(0.1))
                            .cornerRadius(6)
                    }

                    ForEach(needsAttention, id: \.name) { region in
                        RegionRow(name: region.name, score: region.score)
                    }
                }
                .padding()
                .freshGlassCard()
            }

            // Healthy regions - collapsible
            if !healthyRegions.isEmpty {
                ProgressiveDisclosureCard(
                    title: "状态良好",
                    systemImage: "checkmark.circle"
                ) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(healthyRegions.count)个区域")
                            .font(.skinLabCaption)
                    }
                    .foregroundColor(.skinLabSuccess)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.skinLabSuccess.opacity(0.1))
                    .cornerRadius(6)
                } detail: {
                    VStack(spacing: 14) {
                        ForEach(healthyRegions, id: \.name) { region in
                            RegionRow(name: region.name, score: region.score)
                        }
                    }
                }
            }

            // Show all if no problematic regions
            if needsAttention.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.skinLabSuccess)
                        Text("所有区域状态良好")
                            .font(.skinLabHeadline)
                            .foregroundColor(.skinLabText)
                    }

                    ForEach(sortedRegions, id: \.name) { region in
                        RegionRow(name: region.name, score: region.score)
                    }
                }
                .padding()
                .freshGlassCard()
            }
        }
    }

    /// Helper to sort regions by score (lowest first for attention priority)
    private var regionsSorted: [(name: String, score: Int)] {
        [
            ("T区", analysis.regions.tZone),
            ("左脸颊", analysis.regions.leftCheek),
            ("右脸颊", analysis.regions.rightCheek),
            ("眼周", analysis.regions.eyeArea),
            ("下巴", analysis.regions.chin)
        ].sorted { $0.score < $1.score }
    }
    
    // MARK: - Recommendations Section
    private var recommendationsSection: some View {
        VStack(spacing: 16) {
            let recommendations = analysis.recommendations
            let primaryRecs = Array(recommendations.prefix(3))
            let moreRecs = Array(recommendations.dropFirst(3))

            // Top 3 recommendations - always visible (key insights)
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("重点建议")
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)
                    Spacer()
                    if recommendations.count > 3 {
                        Text("共\(recommendations.count)条")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                    }
                }

                ForEach(Array(primaryRecs.enumerated()), id: \.offset) { index, recommendation in
                    RecommendationRow(index: index + 1, text: recommendation, isPrimary: true)

                    if index < primaryRecs.count - 1 {
                        Divider()
                            .padding(.leading, 46)
                    }
                }
            }
            .padding()
            .freshGlassCard()

            // More recommendations - collapsible
            if !moreRecs.isEmpty {
                ProgressiveDisclosureCard(
                    title: "更多建议",
                    systemImage: "lightbulb"
                ) {
                    Text("+\(moreRecs.count)条")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.skinLabPrimary.opacity(0.1))
                        .cornerRadius(6)
                } detail: {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(moreRecs.enumerated()), id: \.offset) { index, recommendation in
                            RecommendationRow(index: index + 4, text: recommendation, isPrimary: false)

                            if index < moreRecs.count - 1 {
                                Divider()
                                    .padding(.leading, 46)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Recommendation Row

/// A styled row for displaying a recommendation with numbered badge
struct RecommendationRow: View {
    let index: Int
    let text: String
    let isPrimary: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(isPrimary ? Color.freshPrimary : Color.freshPrimary.opacity(0.6))
                    .frame(width: 32, height: 32)

                Text("\(index)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Text(text)
                .font(.skinLabBody)
                .foregroundColor(isPrimary ? .skinLabText : .skinLabText.opacity(0.9))
                .lineSpacing(4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("建议\(index): \(text)")
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
            Circle()
                .stroke(color.opacity(0.1), lineWidth: 10)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.0), value: score)
            
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .foregroundStyle(color)
                
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
                    .foregroundColor(.freshSecondary)
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
        AnalysisResultView(result: AnalysisRunResult(
            analysis: .mock,
            analysisId: UUID(),
            photoPath: nil,
            standardization: nil
        ))
    }
}
