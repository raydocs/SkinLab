import Foundation

/// Engagement-related analytics events
extension AnalyticsEvents {
    /// Celebration shown event
    static func celebrationShown(milestone: Int, type: CelebrationType) {
        logEvent(
            name: "celebration_shown",
            parameters: [
                "milestone": milestone,
                "type": type.rawValue
            ]
        )
    }

    /// Achievement shared event
    static func achievementShared(achievementId: String, platform: String? = nil) {
        var parameters: [String: Any] = [
            "achievement_id": achievementId
        ]

        if let platform {
            parameters["platform"] = platform
        }

        logEvent(
            name: "achievement_shared",
            parameters: parameters
        )
    }

    /// Milestone reached event
    static func milestoneReached(milestone: Int, type: MilestoneType) {
        logEvent(
            name: "milestone_reached",
            parameters: [
                "milestone": milestone,
                "type": type.rawValue
            ]
        )
    }

    // MARK: - Helper Types

    enum CelebrationType: String {
        case streakMilestone = "streak_milestone"
        case badgeUnlock = "badge_unlock"
        case streakFreeze = "streak_freeze"
    }

    enum MilestoneType: String {
        case streak
        case totalCheckIns = "total_check_ins"
        case longestStreak = "longest_streak"
    }
}
