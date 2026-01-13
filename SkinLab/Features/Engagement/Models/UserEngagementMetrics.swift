import SwiftData
import Foundation

/// User engagement metrics for streak tracking and achievement system
@Model
final class UserEngagementMetrics {
    /// Current consecutive day streak count
    var streakCount: Int = 0

    /// Longest streak achieved by the user
    var longestStreak: Int = 0

    /// Last check-in date (completed tracking session)
    var lastCheckInDate: Date?

    /// Number of streak freezes currently available
    var streakFreezesAvailable: Int = 1

    /// Tracks the 30-day cycle for freeze replenishment
    var lastFreezeRefillDate: Date?

    /// Total number of check-ins completed
    var totalCheckIns: Int = 0

    /// IDs of unlocked achievements (SwiftData-compatible string array)
    @Attribute(.externalStorage) var unlockedAchievementIDs: [String] = []

    init() {
        // Initialize with first freeze available
        self.lastFreezeRefillDate = Date()
    }
}
