import Foundation
import SwiftData

/// Centralized orchestrator for all engagement features
/// Coordinates streak tracking, achievements, and notifications
@MainActor
final class EngagementOrchestrator {
    // MARK: - Dependencies
    private let streakService: StreakTrackingService
    private let achievementService: AchievementService
    private let notificationService: StreakNotificationService
    private let migrationService: EngagementMigrationService

    // MARK: - Initialization
    init(
        modelContext: ModelContext,
        calendar: Calendar = .current
    ) {
        let streak = StreakTrackingService(modelContext: modelContext, calendar: calendar)
        let achievement = AchievementService(modelContext: modelContext, streakService: streak)
        let notification = StreakNotificationService(streakService: streak)
        let migration = EngagementMigrationService(modelContext: modelContext, streakService: streak)

        self.streakService = streak
        self.achievementService = achievement
        self.notificationService = notification
        self.migrationService = migration
    }

    // MARK: - Public Methods

    /// Called on app launch
    /// Runs migration and schedules notifications if needed
    func onAppLaunch() async {
        // Run one-time migration for existing users
        await migrationService.migrate()

        // Check and refill streak freezes if 30-day cycle completed
        streakService.checkAndRefillFreezes()

        // Schedule streak at-risk notifications
        await notificationService.checkAndScheduleNotifications()
    }

    /// Called when user completes a tracking session
    /// - Parameter checkInDate: The date of the check-in (defaults to now)
    /// - Returns: StreakResult and any newly unlocked achievements
    func onTrackingSessionCompleted(at checkInDate: Date = Date()) async -> (
        streakResult: StreakResult,
        unlockedBadges: [AchievementDefinition]
    ) {
        // Record check-in
        let streakResult = streakService.checkIn(at: checkInDate)

        // Check for achievements
        let achievementResult = achievementService.checkAchievements()

        // Schedule notifications
        await notificationService.checkAndScheduleNotifications()

        return (streakResult, achievementResult.unlockedBadges)
    }

    /// Called when user uses a streak freeze
    /// - Returns: True if freeze was successfully used
    func onStreakFreezeUsed() -> Bool {
        streakService.useStreakFreeze()
    }

    /// Called when user shares an achievement
    /// - Parameter achievementId: The ID of the achievement being shared
    /// - Returns: True if share was tracked successfully
    func onAchievementShared(_ achievementId: String) async -> Bool {
        let success = await achievementService.shareAchievement(achievementId)

        // Check if sharing unlocked the "乐于分享" badge
        if success {
            let achievementResult = achievementService.checkAchievements()
            // Return true if new badges were unlocked
            return !achievementResult.unlockedBadges.isEmpty
        }

        return false
    }

    /// Get current streak status
    func getStreakStatus() -> StreakStatus {
        streakService.getStreakStatus()
    }

    /// Get all achievement progress
    func getAllAchievementProgress() -> [String: AchievementProgress] {
        achievementService.getAllProgress()
    }

    /// Get unlocked badges count
    func getUnlockedBadgesCount() -> Int {
        achievementService.getUnlockedCount()
    }
}
