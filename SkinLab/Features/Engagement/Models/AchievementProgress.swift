import Foundation
import SwiftData

/// Progress tracking for each achievement (persisted separately from badge definitions)
@Model
final class AchievementProgress {
    /// Unique identifier for the achievement (matches AchievementDefinition.id)
    var achievementID: String

    /// Whether the achievement has been unlocked
    var isUnlocked: Bool = false

    /// When the achievement was unlocked
    var unlockedAt: Date?

    /// Progress percentage (0.0 to 1.0)
    var progress: Double = 0.0

    /// Last time progress was updated
    var lastUpdated: Date = Date()

    init(achievementID: String) {
        self.achievementID = achievementID
    }
}
