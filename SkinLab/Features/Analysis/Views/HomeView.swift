import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: [SortDescriptor(\SkinAnalysisRecord.analyzedAt, order: .reverse)])
    private var recentAnalyses: [SkinAnalysisRecord]
    
    @Query(filter: #Predicate<TrackingSession> { $0.statusRaw == "active" })
    private var activeSessions: [TrackingSession]

    @State private var showAnalysis = false
    @State private var showNewTracking = false

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        heroSection
                        quickActionsSection
                        trackingPromptCard
                        if !recentAnalyses.isEmpty { recentSection }
                        dailyTipSection
                        featuresSection
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
                        Text("SkinLab")
                            .font(.skinLabTitle3)
                            .foregroundColor(.skinLabText)
                    }
                }
            }
            .fullScreenCover(isPresented: $showAnalysis) {
                AnalysisView()
            }
            .sheet(isPresented: $showNewTracking) {
                NavigationStack {
                    TrackingView()
                }
            }
        }
    }

    private var backgroundGradient: some View {
        ZStack {
            Color.romanticCream.ignoresSafeArea()

            // 主光晕：保留一个即可
            Circle()
                .fill(LinearGradient.romanticBlushGradient)
                .frame(width: 320, height: 320)
                .blur(radius: 110)
                .offset(x: -100, y: -200)
                .opacity(0.35)

            // 静态装饰：单一元素，降低噪音
            Image(systemName: "sparkle")
                .font(.system(size: 18))
                .foregroundColor(.romanticGold.opacity(0.25))
                .offset(x: 120, y: -240)
        }
    }

    private var heroSection: some View {
        Button {
            showAnalysis = true
        } label: {
            VStack(spacing: 24) {
                ZStack {
                    // 简化圆形背景 + 图标
                    Circle()
                        .fill(LinearGradient.romanticBlushGradient)
                        .frame(width: 108, height: 108)
                        .shadow(color: .romanticPink.opacity(0.25), radius: 16, x: 0, y: 8)

                    Image(systemName: "face.smiling")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                }

                VStack(spacing: 10) {
                    Text("发现你的肌肤之美")
                        .font(.skinLabTitle2)
                        .foregroundColor(.skinLabText)
                    Text("AI智能分析，定制专属护肤方案")
                        .font(.skinLabBody)
                        .foregroundColor(.skinLabSubtext)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)

                    Text("点击开始分析")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabPrimary)
                }
            }
            .padding(.top, 24)
        }
        .buttonStyle(.plain)
    }

    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            NavigationLink {
                CommunityView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                    Text("进入社群")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.skinLabPrimary.opacity(0.7))
                }
            }
            .buttonStyle(SkinLabSecondaryButtonStyle())
        }
    }

    // MARK: - 28 Day Tracking Prompt Card
    private var trackingPromptCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.skinLabPrimaryGradient.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 22))
                        .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("28天效果验证")
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)
                    
                    Text(activeSessionPrompt)
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }
                
                Spacer()
            }
            
            if let session = activeSessions.first {
                // Show progress for active session
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("已记录 \(session.checkIns.count) 次")
                            .font(.skinLabSubheadline)
                            .foregroundColor(.skinLabPrimary)
                        
                        Spacer()
                        
                        if let nextDay = session.nextCheckInDay {
                            let currentDay = session.duration
                            let daysUntil = nextDay - currentDay
                            if daysUntil >= 0 {
                                Text("第\(nextDay)天打卡")
                                    .font(.skinLabCaption)
                                    .foregroundColor(.skinLabSubtext)
                            }
                        }
                    }
                    
                    ProgressView(value: Double(session.checkIns.count), total: 5.0)
                        .tint(LinearGradient.skinLabPrimaryGradient)
                        .scaleEffect(y: 1.5)
                    
                    NavigationLink {
                        TrackingView()
                    } label: {
                        HStack {
                            Image(systemName: "eye.fill")
                            Text("查看详情")
                        }
                        .font(.skinLabSubheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LinearGradient.skinLabPrimaryGradient)
                        .cornerRadius(14)
                    }
                }
            } else {
                // Show start button for new users
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.skinLabSuccess)
                        Text("用数据说话，让效果看得见")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                    }
                    
                    Button {
                        showNewTracking = true
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("开始28天验证")
                        }
                        .font(.skinLabSubheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LinearGradient.skinLabPrimaryGradient)
                        .cornerRadius(14)
                    }
                }
            }
        }
        .padding()
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow(radius: 10, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(LinearGradient.skinLabPrimaryGradient.opacity(0.3), lineWidth: 1.5)
        )
    }
    
    private var activeSessionPrompt: String {
        if activeSessions.isEmpty {
            return "记录护肤效果，科学验证产品是否有效"
        } else {
            let session = activeSessions.first!
            let progress = Int((Double(session.checkIns.count) / 5.0) * 100)
            return "进行中 · \(progress)% 完成"
        }
    }

    private var dailyTipSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb")
                    .foregroundColor(.skinLabPrimary)
                Text("今日小贴士")
                    .font(.skinLabHeadline)
                    .foregroundColor(.skinLabText)
            }
            Text("早晚洁面后，在皮肤微湿时涂抹精华液，可以更好地锁住水分～")
                .font(.skinLabSubheadline)
                .foregroundColor(.skinLabSubtext)
                .lineSpacing(3)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.skinLabCardBackground)
        .cornerRadius(20)
        .skinLabSoftShadow(radius: 10, y: 5)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("最近分析")
                .font(.skinLabTitle3)
                .foregroundColor(.skinLabText)

            ForEach(recentAnalyses.prefix(2)) { record in
                if let analysis = record.toAnalysis() {
                    NavigationLink {
                        AnalysisResultView(analysis: analysis)
                    } label: {
                        RecentAnalysisCard(analysis: analysis)
                    }
                }
            }
        }
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("更多功能")
                .font(.skinLabTitle3)
                .foregroundColor(.skinLabText)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                FeatureCard(icon: "chart.line.uptrend.xyaxis", title: "28天追踪", description: "记录肌肤变化", gradient: .skinLabPrimaryGradient)
                FeatureCard(icon: "person.2.fill", title: "肌肤双胞胎", description: "找到相似用户", gradient: .skinLabLavenderGradient)
                FeatureCard(icon: "list.bullet.rectangle.fill", title: "成分分析", description: "智能解读配方", gradient: .skinLabGoldGradient)
                FeatureCard(icon: "star.fill", title: "产品推荐", description: "个性化好物", gradient: LinearGradient(colors: [.skinLabMint, .skinLabMint.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
        }
    }
}

struct RecentAnalysisCard: View {
    let analysis: SkinAnalysis

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.scoreColor(for: analysis.overallScore).opacity(0.2), lineWidth: 4)
                    .frame(width: 54, height: 54)
                Circle()
                    .trim(from: 0, to: CGFloat(analysis.overallScore) / 100)
                    .stroke(
                        LinearGradient(
                            colors: [Color.scoreColor(for: analysis.overallScore), Color.scoreColor(for: analysis.overallScore).opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 54, height: 54)
                    .rotationEffect(.degrees(-90))
                Text("\(analysis.overallScore)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.scoreColor(for: analysis.overallScore), Color.scoreColor(for: analysis.overallScore).opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(analysis.skinType.displayName)
                    .font(.skinLabHeadline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.romanticPink, .romanticPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text(analysis.analyzedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.skinLabCaption)
                    .foregroundColor(.skinLabSubtext)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.romanticPink.opacity(0.6), .romanticPurple.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding()
        .background(Color.romanticWhite)
        .cornerRadius(22)
        .shadow(color: .romanticPink.opacity(0.08), radius: 14, x: 0, y: 7)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    LinearGradient(
                        colors: [.romanticPink.opacity(0.2), .romanticPurple.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    var gradient: LinearGradient = .skinLabPrimaryGradient

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(gradient)
                    .opacity(0.16)
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(gradient)
            }
            Text(title)
                .font(.skinLabHeadline)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.romanticPink, .romanticPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Text(description)
                .font(.skinLabCaption)
                .foregroundColor(.skinLabSubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(Color.romanticWhite)
        .cornerRadius(22)
        .shadow(color: .romanticPink.opacity(0.06), radius: 12, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(gradient, lineWidth: 1)
                .opacity(0.2)
        )
    }
}

#Preview {
    HomeView()
}
