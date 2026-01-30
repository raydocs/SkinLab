import SwiftData
import SwiftUI

struct TrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<TrackingSession> { $0.statusRaw == "active" },
        sort: [SortDescriptor(\TrackingSession.startDate, order: .reverse)]
    )
    private var activeSessions: [TrackingSession]

    @Query(
        filter: #Predicate<TrackingSession> { $0.statusRaw != "active" },
        sort: [SortDescriptor(\TrackingSession.startDate, order: .reverse)]
    )
    private var pastSessions: [TrackingSession]

    @State private var showNewSession = false
    @State private var showPastSessions = false

    /// Number of past sessions currently displayed (for pagination)
    @State private var displayedPastSessionsCount = 20

    /// Page size for loading more sessions
    private static let pageSize = 20

    var body: some View {
        NavigationStack {
            ZStack {
                // Beautiful gradient background
                LinearGradient(
                    colors: [
                        Color.skinLabPrimary.opacity(0.08),
                        Color.skinLabSecondary.opacity(0.06),
                        Color.skinLabBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Decorative floating elements
                GeometryReader { geometry in
                    FloatingBubble(size: 90, color: .skinLabPrimary)
                        .position(x: geometry.size.width * 0.85, y: 80)
                    FloatingBubble(size: 50, color: .skinLabSecondary)
                        .position(x: 40, y: 200)
                    FloatingBubble(size: 70, color: .skinLabAccent)
                        .position(x: geometry.size.width * 0.7, y: geometry.size.height * 0.5)
                }
                .accessibilityHidden(true)

                ScrollView {
                    LazyVStack(spacing: 24) {
                        if let activeSession = activeSessions.first {
                            activeSessionView(activeSession)
                        } else {
                            emptyStateView
                        }

                        if !pastSessions.isEmpty {
                            pastSessionsSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("效果追踪")
            .sheet(isPresented: $showNewSession) {
                NewTrackingSessionView()
            }
            .onChange(of: showPastSessions) { _, isExpanded in
                // Reset pagination when disclosure group is collapsed
                if !isExpanded {
                    displayedPastSessionsCount = Self.pageSize
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "chart.line.uptrend.xyaxis",
            title: "开始28天追踪",
            message: "记录护肤过程，见证皮肤变化\n获得真实的效果数据",
            actionTitle: "开始28天追踪",
            features: [
                EmptyStateFeature(icon: "camera.fill", text: "标准化拍照，确保对比准确", gradient: .skinLabPrimaryGradient),
                EmptyStateFeature(
                    icon: "calendar.badge.clock",
                    text: "第7/14/21/28天提醒打卡",
                    gradient: .skinLabLavenderGradient
                ),
                EmptyStateFeature(icon: "chart.bar.fill", text: "AI分析改善趋势", gradient: .skinLabGoldGradient),
                EmptyStateFeature(icon: "square.and.arrow.up.fill", text: "生成可分享的对比图", gradient: .skinLabRoseGradient)
            ],
            action: {
                showNewSession = true
            }
        )
        .padding(.top, 32)
    }

    // MARK: - Active Session

    private func activeSessionView(_ session: TrackingSession) -> some View {
        NavigationLink(destination: TrackingDetailView(session: session)) {
            VStack(spacing: 20) {
                // Progress Card with glass effect
                VStack(spacing: 18) {
                    HStack {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.skinLabPrimaryGradient.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                            }
                            Text("28天追踪进行中")
                                .font(.skinLabHeadline)
                                .foregroundColor(.skinLabText)
                        }
                        Spacer()
                        Text("第\(session.duration)天")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(LinearGradient.skinLabPrimaryGradient.opacity(0.12))
                            )
                    }

                    // Beautiful progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 10)

                            Capsule()
                                .fill(LinearGradient.skinLabPrimaryGradient)
                                .frame(width: geometry.size.width * session.progress, height: 10)
                                .shadow(color: .skinLabPrimary.opacity(0.4), radius: 4, y: 2)
                        }
                    }
                    .frame(height: 10)

                    HStack {
                        Text("开始于 \(session.startDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                        Spacer()
                        Text("还剩\(28 - session.duration)天")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabPrimary)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.6), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .skinLabPrimary.opacity(0.1), radius: 15, y: 5)

                // Check-in Status with beautiful nodes
                VStack(spacing: 16) {
                    HStack {
                        Text("打卡节点")
                            .font(.skinLabHeadline)
                            .foregroundColor(.skinLabText)
                        Spacer()
                        Text("\(session.checkIns.count)/5 完成")
                            .font(.skinLabCaption)
                            .foregroundColor(.skinLabSubtext)
                    }

                    HStack(spacing: 0) {
                        ForEach(TrackingConstants.checkInDays, id: \.self) { day in
                            let status: BeautifulCheckInNode.CheckInStatus = if session.checkIns
                                .contains(where: { $0.day == day }) {
                                .completed
                            } else if day <= session.duration {
                                .missed
                            } else {
                                .upcoming
                            }
                            BeautifulCheckInNode(day: day, status: status)

                            if day < 28 {
                                // Connection line
                                Rectangle()
                                    .fill(
                                        session.checkIns.contains(where: { $0.day == day })
                                            ? LinearGradient.skinLabPrimaryGradient
                                            : LinearGradient(
                                                colors: [Color.gray.opacity(0.2)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                    )
                                    .frame(height: 3)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.skinLabCardBackground)
                )
                .shadow(color: .black.opacity(0.05), radius: 10, y: 4)

                // View Details hint
                HStack(spacing: 6) {
                    Text("点击查看详情")
                        .font(.skinLabSubheadline)
                        .foregroundColor(.skinLabSubtext)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.skinLabPrimary)
                        .accessibilityHidden(true)
                }
                .padding(.top, 4)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("28天追踪进行中，第\(session.duration)天，已打卡\(session.checkIns.count)次")
        .accessibilityHint("双击查看详情")
    }

    // MARK: - Past Sessions

    private var pastSessionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            DisclosureGroup(isExpanded: $showPastSessions) {
                LazyVStack(spacing: 12) {
                    ForEach(
                        Array(pastSessions.prefix(displayedPastSessionsCount).enumerated()),
                        id: \.element.id
                    ) { index, session in
                        PastSessionRow(session: session)
                            .onAppear {
                                loadMorePastSessionsIfNeeded(currentIndex: index)
                            }
                    }

                    // Loading indicator when more sessions available
                    if displayedPastSessionsCount < pastSessions.count {
                        HStack {
                            Spacer()
                            ProgressView()
                                .onAppear {
                                    loadMorePastSessions()
                                }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
            } label: {
                HStack {
                    Text("历史追踪")
                        .font(.skinLabHeadline)
                        .foregroundColor(.skinLabText)
                    Spacer()
                    Text("\(pastSessions.count)次")
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                }
            }
        }
    }

    // MARK: - Pagination Helpers

    /// Load more past sessions when approaching the end of the displayed list
    private func loadMorePastSessionsIfNeeded(currentIndex: Int) {
        // Load more when user is 5 items from the end
        let threshold = displayedPastSessionsCount - 5
        if currentIndex >= threshold {
            loadMorePastSessions()
        }
    }

    /// Increment the displayed count to show more sessions
    private func loadMorePastSessions() {
        guard displayedPastSessionsCount < pastSessions.count else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedPastSessionsCount = min(
                displayedPastSessionsCount + Self.pageSize,
                pastSessions.count
            )
        }
    }

    private struct PastSessionRow: View {
        let session: TrackingSession

        private var isCompleted: Bool {
            session.status == .completed
        }

        private var statusGradient: LinearGradient {
            if isCompleted {
                return LinearGradient.skinLabPrimaryGradient
            }
            return LinearGradient(
                colors: [Color.gray.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        private var statusOpacity: Double {
            isCompleted ? 0.15 : 1.0
        }

        var body: some View {
            NavigationLink(destination: TrackingDetailView(session: session)) {
                HStack(spacing: 16) {
                    // Status icon
                    ZStack {
                        Circle()
                            .fill(statusGradient)
                            .opacity(statusOpacity)
                            .frame(width: 44, height: 44)

                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(isCompleted ? .skinLabSuccess : .skinLabSubtext)
                    }
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(session.startDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.skinLabSubheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.skinLabText)

                        HStack(spacing: 8) {
                            Label("\(session.checkIns.count)次打卡", systemImage: "camera.fill")
                            Text("·")
                            Text(isCompleted ? "已完成" : "已放弃")
                        }
                        .font(.skinLabCaption)
                        .foregroundColor(.skinLabSubtext)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.skinLabPrimary.opacity(0.5))
                        .accessibilityHidden(true)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.skinLabCardBackground)
                )
                .shadow(color: .black.opacity(0.03), radius: 8, y: 3)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "历史追踪：\(session.startDate.formatted(date: .abbreviated, time: .omitted))，\(isCompleted ? "已完成" : "已放弃")，\(session.checkIns.count)次打卡"
            )
            .accessibilityHint("双击查看详情")
        }
    }
}

// MARK: - New Tracking Session View

struct NewTrackingSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedProducts: [String] = []
    @State private var notes: String = ""
    @State private var showProductPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.skinLabPrimary.opacity(0.06),
                        Color.skinLabSecondary.opacity(0.04),
                        Color.skinLabBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Hero section with icon
                        ZStack {
                            Circle()
                                .fill(LinearGradient.skinLabPrimaryGradient.opacity(0.12))
                                .frame(width: 110, height: 110)

                            Circle()
                                .fill(LinearGradient.skinLabPrimaryGradient.opacity(0.2))
                                .frame(width: 80, height: 80)

                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 38))
                                .foregroundStyle(LinearGradient.skinLabPrimaryGradient)

                            SparkleView(size: 14)
                                .offset(x: 40, y: -35)
                        }
                        .padding(.top, 16)

                        VStack(spacing: 10) {
                            Text("28天皮肤追踪")
                                .font(.skinLabTitle2)
                                .foregroundColor(.skinLabText)

                            Text("记录你的护肤旅程\n见证皮肤的真实变化")
                                .font(.skinLabBody)
                                .foregroundColor(.skinLabSubtext)
                                .multilineTextAlignment(.center)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("默认28天追踪")
                                .font(.skinLabHeadline)
                                .foregroundColor(.skinLabText)
                            Text("按第0/7/14/21/28天打卡，自动生成对比报告")
                                .font(.skinLabCaption)
                                .foregroundColor(.skinLabSubtext)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.skinLabCardBackground)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)

                        // Products section
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("追踪产品")
                                    .font(.skinLabHeadline)
                                    .foregroundColor(.skinLabText)
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

                            Text("可不填，稍后也能补充")
                                .font(.skinLabCaption)
                                .foregroundColor(.skinLabSubtext)

                            if !selectedProducts.isEmpty {
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
                                            .fill(LinearGradient.skinLabPrimaryGradient.opacity(0.15))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "plus")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(LinearGradient.skinLabPrimaryGradient)
                                    }
                                    Text("添加产品")
                                        .font(.skinLabSubheadline)
                                        .foregroundColor(.skinLabPrimary)
                                }
                            }
                            .accessibilityLabel("添加产品")
                            .accessibilityHint("选择要追踪的护肤产品")
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.skinLabCardBackground)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("备注")
                                .font(.skinLabHeadline)
                                .foregroundColor(.skinLabText)
                            TextField("记录使用感受或想关注的问题", text: $notes, axis: .vertical)
                                .font(.skinLabBody)
                                .foregroundColor(.skinLabText)
                                .lineLimit(3, reservesSpace: true)
                                .padding(12)
                                .background(Color.skinLabBackground)
                                .cornerRadius(12)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.skinLabCardBackground)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)

                        // Start Button
                        Button {
                            startSession()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14))
                                Text("开始追踪")
                                    .font(.skinLabHeadline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient.skinLabPrimaryGradient
                            )
                            .cornerRadius(28)
                            .shadow(color: .skinLabPrimary.opacity(0.35), radius: 12, y: 6)
                        }
                        .accessibilityLabel("开始追踪")
                        .accessibilityHint("创建28天皮肤追踪周期")
                    }
                    .padding()
                }
            }
            .navigationTitle("新建追踪")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.skinLabPrimary)
                        .accessibilityLabel("取消")
                        .accessibilityHint("返回上一页面")
                }
            }
            .sheet(isPresented: $showProductPicker) {
                ProductPickerView(selectedProducts: $selectedProducts)
            }
        }
    }

    private func startSession() {
        let session = TrackingSession(targetProducts: selectedProducts)
        if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            session.notes = notes
        }
        modelContext.insert(session)

        // Track feature discovery - first tracking session
        AnalyticsEvents.featureDiscovered(featureName: "28_day_tracking")

        dismiss()
    }
}

// MARK: - Tracking Feature Row (Beautiful)

struct TrackingFeatureRow: View {
    let icon: String
    let text: String
    var gradient: LinearGradient = .skinLabPrimaryGradient

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(gradient)
            }

            Text(text)
                .font(.skinLabSubheadline)
                .foregroundColor(.skinLabText)
        }
    }
}

// MARK: - Beautiful Check In Node

struct BeautifulCheckInNode: View {
    let day: Int
    let status: CheckInStatus

    enum CheckInStatus {
        case completed, upcoming, missed
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(statusBackground)
                    .frame(width: 36, height: 36)

                if status == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else if status == .missed {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(day)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.skinLabSubtext)
                }
            }

            Text("Day \(day)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(status == .completed ? .skinLabPrimary : .skinLabSubtext)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("第\(day)天，\(statusLabel)")
    }

    private var statusLabel: String {
        switch status {
        case .completed: "已完成"
        case .upcoming: "待打卡"
        case .missed: "已错过"
        }
    }

    var statusBackground: LinearGradient {
        switch status {
        case .completed:
            LinearGradient.skinLabPrimaryGradient
        case .upcoming:
            LinearGradient(colors: [Color.gray.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .missed:
            LinearGradient(colors: [Color.skinLabError], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

#Preview {
    TrackingView()
}
