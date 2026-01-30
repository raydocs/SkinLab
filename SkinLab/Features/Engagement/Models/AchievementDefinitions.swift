import Foundation

/// Achievement badge definition (CODE, not persisted in SwiftData)
struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let description: String
    let category: BadgeCategory
    let requirementType: AchievementRequirementType
    let requirementValue: Int
    let iconName: String
}

/// Badge categories
enum BadgeCategory: String, CaseIterable, Codable {
    case streaks = "连续打卡"
    case completeness = "完整性"
    case social = "社交互动"
    case knowledge = "产品知识"
}

/// Achievement requirement types
enum AchievementRequirementType: String, Codable {
    case streakDays
    case totalCheckIns
    case skinTwinMatches
    case productAnalysisCompleted
    case shares
}

/// All achievement badge definitions
enum AchievementDefinitions {
    static let allBadges: [AchievementDefinition] = [
        // MARK: - Streaks (3 badges)

        AchievementDefinition(
            id: "streak_3",
            title: "三日坚持",
            description: "连续打卡3天",
            category: .streaks,
            requirementType: .streakDays,
            requirementValue: 3,
            iconName: "flame.fill"
        ),
        AchievementDefinition(
            id: "streak_7",
            title: "一周达人",
            description: "连续打卡7天",
            category: .streaks,
            requirementType: .streakDays,
            requirementValue: 7,
            iconName: "flame.fill"
        ),
        AchievementDefinition(
            id: "streak_28",
            title: "二十八天完成",
            description: "完成28天护肤周期",
            category: .streaks,
            requirementType: .streakDays,
            requirementValue: 28,
            iconName: "star.fill"
        ),

        // MARK: - Completeness (3 badges)

        AchievementDefinition(
            id: "first_analysis",
            title: "新手入门",
            description: "完成首次皮肤分析",
            category: .completeness,
            requirementType: .totalCheckIns,
            requirementValue: 1,
            iconName: "sparkles"
        ),
        AchievementDefinition(
            id: "checkin_10",
            title: "打卡达人",
            description: "完成10次打卡",
            category: .completeness,
            requirementType: .totalCheckIns,
            requirementValue: 10,
            iconName: "checkmark.circle.fill"
        ),
        AchievementDefinition(
            id: "cycle_complete",
            title: "完美周期",
            description: "完成一个完整的28天护肤周期",
            category: .completeness,
            requirementType: .streakDays,
            requirementValue: 28,
            iconName: "trophy.fill"
        ),

        // MARK: - Social (3 badges)

        AchievementDefinition(
            id: "first_twin",
            title: "初次匹配",
            description: "找到第一位护肤双胞胎",
            category: .social,
            requirementType: .skinTwinMatches,
            requirementValue: 1,
            iconName: "person.2.fill"
        ),
        AchievementDefinition(
            id: "twin_5",
            title: "社交达人",
            description: "匹配到5位护肤双胞胎",
            category: .social,
            requirementType: .skinTwinMatches,
            requirementValue: 5,
            iconName: "person.3.fill"
        ),
        AchievementDefinition(
            id: "share_achievement",
            title: "乐于分享",
            description: "分享成就到社交媒体",
            category: .social,
            requirementType: .shares,
            requirementValue: 1,
            iconName: "square.and.arrow.up"
        ),

        // MARK: - Knowledge (3 badges)

        AchievementDefinition(
            id: "analyze_5_products",
            title: "产品分析家",
            description: "分析5个护肤产品",
            category: .knowledge,
            requirementType: .productAnalysisCompleted,
            requirementValue: 5,
            iconName: "chart.bar.doc.horizontal"
        ),
        AchievementDefinition(
            id: "analyze_10_products",
            title: "产品专家",
            description: "分析10个护肤产品",
            category: .knowledge,
            requirementType: .productAnalysisCompleted,
            requirementValue: 10,
            iconName: "book.fill"
        ),
        AchievementDefinition(
            id: "knowledge_master",
            title: "护肤大师",
            description: "分析20个护肤产品",
            category: .knowledge,
            requirementType: .productAnalysisCompleted,
            requirementValue: 20,
            iconName: "graduationcap.fill"
        )
    ]
}
