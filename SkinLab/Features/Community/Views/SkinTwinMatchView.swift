import SwiftData

// SkinLab/Features/Community/Views/SkinTwinMatchView.swift
import SwiftUI

/// 皮肤双胞胎匹配主视图
struct SkinTwinMatchView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SkinTwinViewModel()
    @State private var selectedTwin: SkinTwin?
    @State private var showConsentSheet = false

    var body: some View {
        ZStack {
            // 浪漫风格背景
            backgroundView

            ScrollView {
                VStack(spacing: 24) {
                    // 头部区域
                    headerSection

                    // 内容区域
                    contentSection
                }
                .padding()
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .navigationTitle("肌肤双胞胎")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showConsentSheet = true
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                }
            }
        }
        .sheet(isPresented: $showConsentSheet) {
            ConsentSettingsView(
                selectedLevel: $viewModel.consentLevel,
                onSave: { level in
                    Task {
                        await viewModel.updateConsent(level)
                    }
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $selectedTwin) { twin in
            NavigationStack {
                SkinTwinDetailView(
                    twin: twin,
                    recommendations: viewModel.selectedTwinRecommendations,
                    onFeedback: { matchId in
                        viewModel.showFeedback(for: matchId)
                    }
                )
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $viewModel.showFeedbackForm) {
            if let matchId = viewModel.feedbackMatchId {
                FeedbackView(matchId: matchId) { accuracy, isHelpful, text in
                    Task {
                        await viewModel.submitFeedback(
                            matchId: matchId,
                            accuracy: accuracy,
                            isHelpful: isHelpful,
                            feedbackText: text
                        )
                    }
                }
                .presentationDetents([.medium])
            }
        }
        .task {
            viewModel.configure(with: modelContext)
            await viewModel.loadMatches()
        }
        .onChange(of: selectedTwin) { _, newValue in
            if let twin = newValue {
                Task {
                    await viewModel.selectTwin(twin)
                }
            }
        }
    }

    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            Color.skinLabBackground.ignoresSafeArea()

            Circle()
                .fill(LinearGradient.skinLabLavenderGradient)
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: -120, y: -220)
                .opacity(0.3)

            Circle()
                .fill(LinearGradient.skinLabRoseGradient)
                .frame(width: 220, height: 220)
                .blur(radius: 90)
                .offset(x: 140, y: 180)
                .opacity(0.25)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // 标题
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("我的肌肤双胞胎")
                        .font(.skinLabTitle2)
                        .foregroundColor(.skinLabText)

                    if let stats = viewModel.matchStats {
                        Text(stats.summary)
                            .font(.skinLabBody)
                            .foregroundColor(.skinLabSubtext)
                    } else if viewModel.consentLevel == .none {
                        Text("设置隐私选项开始匹配")
                            .font(.skinLabBody)
                            .foregroundColor(.skinLabSubtext)
                    }
                }

                Spacer()

                // 统计徽章
                if let stats = viewModel.matchStats {
                    statsBadge(stats)
                }
            }

            // 同意提示 (如果未设置)
            if viewModel.consentLevel == .none {
                consentPromptCard
            }
        }
        .padding(.top, 8)
    }

    private func statsBadge(_ stats: MatchStats) -> some View {
        VStack(spacing: 2) {
            Text("\(stats.avgSimilarityPercent)%")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
            Text("平均相似")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.skinLabSubtext)
        }
        .padding(12)
        .background(Color.skinLabCardBackground)
        .cornerRadius(14)
        .skinLabSoftShadow(radius: 6, y: 3)
    }

    private var consentPromptCard: some View {
        Button {
            showConsentSheet = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.skinLabLavenderGradient.opacity(0.18))
                        .frame(width: 48, height: 48)
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(LinearGradient.skinLabLavenderGradient)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("设置隐私选项")
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)
                    Text("选择您愿意分享的数据范围")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.skinLabPrimary.opacity(0.6))
            }
            .padding(16)
            .background(Color.skinLabCardBackground)
            .cornerRadius(18)
            .skinLabGradientBorder(lineWidth: 1.5, cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content Section

    @ViewBuilder
    private var contentSection: some View {
        if viewModel.isLoading {
            loadingView
        } else if let error = viewModel.errorMessage {
            errorView(error)
        } else if viewModel.consentLevel == .none {
            emptyConsentView
        } else if viewModel.matches.isEmpty {
            emptyMatchesView
        } else {
            matchesListView
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.skinLabPrimary)

            Text("正在寻找肌肤双胞胎...")
                .font(.skinLabBody)
                .foregroundColor(.skinLabSubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.skinLabWarning)

            Text(message)
                .font(.skinLabBody)
                .foregroundColor(.skinLabSubtext)
                .multilineTextAlignment(.center)

            Button("重试") {
                Task {
                    viewModel.clearError()
                    await viewModel.refresh()
                }
            }
            .buttonStyle(SkinLabSecondaryButtonStyle())
            .frame(width: 120)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var emptyConsentView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient.skinLabLavenderGradient)

            Text("开启肌肤双胞胎匹配")
                .font(.skinLabTitle3)
                .foregroundColor(.skinLabText)

            Text("找到相似肤质的人，\n发现他们验证有效的产品")
                .font(.skinLabBody)
                .foregroundColor(.skinLabSubtext)
                .multilineTextAlignment(.center)

            Button("开始设置") {
                showConsentSheet = true
            }
            .buttonStyle(SkinLabPrimaryButtonStyle())
            .frame(width: 200)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var emptyMatchesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 50))
                .foregroundStyle(LinearGradient.skinLabPrimaryGradient)

            Text("暂无匹配结果")
                .font(.skinLabTitle3)
                .foregroundColor(.skinLabText)

            Text("稍后会有更多用户加入匹配池")
                .font(.skinLabBody)
                .foregroundColor(.skinLabSubtext)

            Button("刷新") {
                Task {
                    await viewModel.refresh()
                }
            }
            .buttonStyle(SkinLabSecondaryButtonStyle())
            .frame(width: 120)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var matchesListView: some View {
        VStack(spacing: 16) {
            // 顶级匹配区域
            if !viewModel.topMatches.isEmpty {
                topMatchesSection
            }

            // 产品推荐区域
            if !viewModel.recommendations.isEmpty {
                recommendationsSection
            }

            // 所有匹配列表
            allMatchesSection
        }
    }

    // MARK: - Top Matches Section

    private var topMatchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最佳匹配")
                .font(.skinLabHeadline)
                .foregroundColor(.skinLabText)

            ForEach(viewModel.topMatches) { twin in
                TwinMatchCard(twin: twin) {
                    selectedTwin = twin
                }
                .staggered(
                    delay: Double(viewModel.topMatches.firstIndex(where: { $0.id == twin.id }) ?? 0)
                        * 0.1
                )
            }
        }
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("推荐产品")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)

                Spacer()

                Text("基于双胞胎验证")
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.recommendations.prefix(5)) { recommendation in
                        ProductRecommendationCard(recommendation: recommendation)
                    }
                }
            }
        }
    }

    // MARK: - All Matches Section

    private var allMatchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.matches.count > 3 {
                Text("更多相似用户")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)

                ForEach(viewModel.matches.dropFirst(3)) { twin in
                    TwinMatchCardCompact(twin: twin)
                        .onTapGesture {
                            selectedTwin = twin
                        }
                }
            }
        }
    }
}

// MARK: - Product Recommendation Card

struct ProductRecommendationCard: View {
    let recommendation: ProductRecommendationScore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 产品图片占位
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient.skinLabLavenderGradient.opacity(0.2))
                    .frame(width: 100, height: 80)

                Image(systemName: recommendation.product.category.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
            }

            // 产品信息
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.product.brand)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.skinLabSubtext)

                Text(recommendation.product.name)
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabText)
                    .lineLimit(2)
            }

            // 推荐分数
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                Text("\(recommendation.scorePercent)分")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(.skinLabAccent)
        }
        .frame(width: 120)
        .padding(10)
        .background(Color.skinLabCardBackground)
        .cornerRadius(14)
        .skinLabSoftShadow(radius: 6, y: 3)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SkinTwinMatchView()
    }
    .modelContainer(for: [UserProfile.self, MatchResultRecord.self])
}
