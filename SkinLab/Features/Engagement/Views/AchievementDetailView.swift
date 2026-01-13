import SwiftUI

/// Achievement detail view
struct AchievementDetailView: View {
    let badge: AchievementDefinition
    let progress: AchievementProgress?

    @Environment(\.dismiss) private var dismiss
    @State private var isSharing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Badge preview
                    badgePreview

                    // Title and category
                    titleSection

                    // Description
                    descriptionSection

                    // Progress section
                    progressSection

                    // Requirements
                    requirementsSection

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("成就详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }

                if isUnlocked {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            isSharing = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $isSharing) {
                AchievementShareSheet(activityItems: shareItems)
            }
        }
        .accessibilityIdentifier("achievement_detail")
    }

    // MARK: - Badge Preview

    private var badgePreview: some View {
        VStack(spacing: 16) {
            ZStack {
                // Glow effect for unlocked badges
                if isUnlocked {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [categoryColors.first!.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 40,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                }

                AchievementBadgeView(
                    badge: badge,
                    progress: progress,
                    size: .large
                ) {}
            }

            // Unlock status
            Text(isUnlocked ? "已解锁" : "未解锁")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isUnlocked ? categoryColors.first : .secondary)

            if let unlockedAt = progress?.unlockedAt {
                Text("解锁于 \(unlockedAt, style: .date)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text(badge.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            Text(badge.category.rawValue)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("描述")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            Text(badge.description)
                .font(.system(size: 16))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("进度")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                // Progress bar
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))

                            // Progress
                            RoundedRectangle(cornerRadius: 8)
                                .fill(categoryColors.first ?? .blue)
                                .frame(width: geometry.size.width * progressPercentage)
                        }
                    }
                    .frame(height: 12)

                    // Progress text
                    HStack {
                        Text("\(currentValue)/\(badge.requirementValue)")
                            .font(.system(size: 14, weight: .semibold))

                        Spacer()

                        Text("\(Int(progressPercentage * 100))%")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // How to unlock hint
            if !isUnlocked {
                VStack(alignment: .leading, spacing: 4) {
                    Text("如何解锁")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)

                    Text(unlockHint)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Requirements Section

    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("要求")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: requirementIcon)
                    .foregroundColor(categoryColors.first)

                Text(requirementText)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Computed Properties

    private var isUnlocked: Bool {
        progress?.isUnlocked == true
    }

    private var categoryColors: [Color] {
        switch badge.category {
        case .streaks:
            return [.orange, .red]
        case .completeness:
            return [.blue, .purple]
        case .social:
            return [.green, .mint]
        case .knowledge:
            return [.yellow, .orange]
        }
    }

    private var progressPercentage: Double {
        min(1.0, progress?.progress ?? 0)
    }

    private var currentValue: Int {
        Int(Double(badge.requirementValue) * progressPercentage)
    }

    private var unlockHint: String {
        switch badge.requirementType {
        case .streakDays:
            return "连续打卡\(badge.requirementValue)天"
        case .totalCheckIns:
            return "完成\(badge.requirementValue)次打卡"
        case .skinTwinMatches:
            return "匹配\(badge.requirementValue)位护肤双胞胎"
        case .productAnalysisCompleted:
            return "分析\(badge.requirementValue)个护肤产品"
        }
    }

    private var requirementIcon: String {
        switch badge.requirementType {
        case .streakDays:
            return "flame.fill"
        case .totalCheckIns:
            return "checkmark.circle.fill"
        case .skinTwinMatches:
            return "person.2.fill"
        case .productAnalysisCompleted:
            return "chart.bar.doc.horizontal"
        }
    }

    private var requirementText: String {
        switch badge.requirementType {
        case .streakDays:
            return "连续打卡 \(badge.requirementValue) 天"
        case .totalCheckIns:
            return "完成 \(badge.requirementValue) 次打卡"
        case .skinTwinMatches:
            return "匹配 \(badge.requirementValue) 位护肤双胞胎"
        case .productAnalysisCompleted:
            return "分析 \(badge.requirementValue) 个护肤产品"
        }
    }

    private var shareItems: [Any] {
        var items: [Any] = []

        let text = "我在 SkinLab 解锁了「\(badge.title)」成就！\(badge.description)"
        items.append(text)

        // TODO: Add share image generation
        // items.append(shareImage)

        return items
    }
}

// MARK: - Share Sheet

struct AchievementShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    AchievementDetailView(
        badge: AchievementDefinitions.allBadges[0],
        progress: {
            let p = AchievementProgress(achievementID: "test")
            p.isUnlocked = true
            p.progress = 1.0
            return p
        }()
    )
}
