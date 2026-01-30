import SwiftData
import SwiftUI

/// Achievement dashboard with badge grid and category filtering
struct AchievementDashboardView: View {
    @Query private var achievementProgress: [AchievementProgress]
    @State private var selectedCategory: BadgeCategory?
    @State private var searchText = ""
    @State private var selectedBadge: AchievementDefinition?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerView

                // Category filter tabs
                categoryFilterView

                // Badges grid
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredBadges, id: \.id) { badge in
                        AchievementBadgeView(
                            badge: badge,
                            progress: getProgress(for: badge),
                            size: .medium
                        ) {
                            selectedBadge = badge
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(item: $selectedBadge) { badge in
            AchievementDetailView(
                badge: badge,
                progress: getProgress(for: badge)
            )
        }
        .navigationTitle("成就")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "搜索成就")
        .accessibilityIdentifier("achievement_dashboard")
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: 12) {
            // Stats
            HStack(spacing: 24) {
                AchievementStatItem(
                    icon: "trophy.fill",
                    title: "已解锁",
                    value: "\(unlockedCount)",
                    color: .yellow
                )

                AchievementStatItem(
                    icon: "lock.fill",
                    title: "未解锁",
                    value: "\(lockedCount)",
                    color: .gray
                )

                AchievementStatItem(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "完成率",
                    value: "\(completionPercentage)%",
                    color: .blue
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }

    // MARK: - Category Filter View

    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryFilterButton(
                    title: "全部",
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = nil
                    }
                }

                ForEach(BadgeCategory.allCases, id: \.self) { category in
                    CategoryFilterButton(
                        title: category.rawValue,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Computed Properties

    private var filteredBadges: [AchievementDefinition] {
        var badges = AchievementDefinitions.allBadges

        // Filter by category
        if let category = selectedCategory {
            badges = badges.filter { $0.category == category }
        }

        // Filter by search text
        if !searchText.isEmpty {
            badges = badges.filter { badge in
                badge.title.localizedCaseInsensitiveContains(searchText) ||
                    badge.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Sort: unlocked first, then by progress
        return badges.sorted { badge1, badge2 in
            let progress1 = getProgress(for: badge1)
            let progress2 = getProgress(for: badge2)

            // Unlocked badges first
            if progress1?.isUnlocked != progress2?.isUnlocked {
                return progress1?.isUnlocked == true
            }

            // Then by progress (descending)
            guard let p1 = progress1?.progress, let p2 = progress2?.progress else {
                return false
            }
            return p1 > p2
        }
    }

    private var unlockedCount: Int {
        achievementProgress.filter(\.isUnlocked).count
    }

    private var lockedCount: Int {
        AchievementDefinitions.allBadges.count - unlockedCount
    }

    private var completionPercentage: Int {
        let total = AchievementDefinitions.allBadges.count
        guard total > 0 else { return 0 }
        return Int((Double(unlockedCount) / Double(total)) * 100)
    }

    // MARK: - Helper Methods

    private func getProgress(for badge: AchievementDefinition) -> AchievementProgress? {
        achievementProgress.first { $0.achievementID == badge.id }
    }
}

// MARK: - Category Filter Button

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .clipShape(Capsule())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Stat Item

struct AchievementStatItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)

            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)\(value)")
    }
}

#Preview {
    NavigationStack {
        AchievementDashboardView()
    }
}
