import Foundation
import SwiftData

/// Achievement unlock result
struct AchievementUnlockResult {
    let unlockedBadges: [AchievementDefinition]
    let progressUpdates: [(achievement: AchievementDefinition, progress: Double)]
}

/// Service for managing achievement badges and progress
@MainActor
final class AchievementService {
    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let streakService: StreakTrackingService

    // MARK: - Initialization

    init(modelContext: ModelContext, streakService: StreakTrackingService) {
        self.modelContext = modelContext
        self.streakService = streakService
    }

    // MARK: - Public Methods

    /// Check for newly unlocked achievements based on current metrics
    /// - Returns: AchievementUnlockResult with newly unlocked badges and progress updates
    func checkAchievements() -> AchievementUnlockResult {
        let streakStatus = streakService.getStreakStatus()
        let allBadges = AchievementDefinitions.allBadges

        var newlyUnlocked: [AchievementDefinition] = []
        var progressUpdates: [(AchievementDefinition, Double)] = []

        for badge in allBadges {
            let progress = getProgress(for: badge, streakStatus: streakStatus)

            // Get or create progress record
            let progressRecord = getOrCreateProgress(for: badge.id)

            // Update progress
            progressRecord.progress = progress
            progressRecord.lastUpdated = Date()

            // Check for unlock
            if progress >= 1.0, !progressRecord.isUnlocked {
                progressRecord.isUnlocked = true
                progressRecord.unlockedAt = Date()
                newlyUnlocked.append(badge)

                // Add to metrics
                let metrics = getOrCreateMetrics()
                if !metrics.unlockedAchievementIDs.contains(badge.id) {
                    metrics.unlockedAchievementIDs.append(badge.id)
                }

                // Track badge earned for analytics
                AnalyticsEvents.badgeEarned(
                    achievementId: badge.id,
                    badgeName: badge.title
                )
            }

            progressUpdates.append((badge, progress))
        }

        return AchievementUnlockResult(
            unlockedBadges: newlyUnlocked,
            progressUpdates: progressUpdates
        )
    }

    /// Get progress for a specific achievement
    /// - Parameter achievement: The achievement definition
    /// - Returns: Progress value (0.0 to 1.0)
    func getProgress(for achievement: AchievementDefinition) -> Double {
        let streakStatus = streakService.getStreakStatus()
        return getProgress(for: achievement, streakStatus: streakStatus)
    }

    /// Get progress for a specific achievement (internal)
    private func getProgress(for achievement: AchievementDefinition, streakStatus: StreakStatus) -> Double {
        let currentValue: Int = switch achievement.requirementType {
        case .streakDays:
            streakStatus.currentStreak
        case .totalCheckIns:
            streakStatus.totalCheckIns
        case .skinTwinMatches:
            getSkinTwinMatchCount()
        case .productAnalysisCompleted:
            getProductAnalysisCount()
        case .shares:
            getShareCount()
        }

        return min(1.0, Double(currentValue) / Double(achievement.requirementValue))
    }

    /// Manually unlock an achievement
    /// - Parameter id: Achievement ID
    func unlockAchievement(_ id: String) {
        let progressRecord = getOrCreateProgress(for: id)
        guard !progressRecord.isUnlocked else { return }

        progressRecord.isUnlocked = true
        progressRecord.unlockedAt = Date()
        progressRecord.progress = 1.0

        // Add to metrics
        let metrics = getOrCreateMetrics()
        if !metrics.unlockedAchievementIDs.contains(id) {
            metrics.unlockedAchievementIDs.append(id)
        }
    }

    /// Share an achievement to social media
    /// - Parameter id: Achievement ID
    /// - Returns: True if share sheet was presented successfully
    func shareAchievement(_ id: String) async -> Bool {
        // Find the achievement
        guard let achievement = AchievementDefinitions.allBadges.first(where: { $0.id == id }),
              let progressRecord = getProgressRecord(for: id),
              progressRecord.isUnlocked else {
            return false
        }

        // Track the share
        let metrics = getOrCreateMetrics()
        metrics.totalShares += 1

        // Generate share image (to be implemented in UI layer)
        // For now, return true to indicate share capability
        // The actual sharing will be handled by UI components

        return true
    }

    /// Get all achievement progress records
    /// - Returns: Dictionary mapping achievement IDs to progress records
    func getAllProgress() -> [String: AchievementProgress] {
        let descriptor = FetchDescriptor<AchievementProgress>()
        let records: [AchievementProgress]

        do {
            records = try modelContext.fetch(descriptor)
            AppLogger.data(operation: .fetch, entity: "AchievementProgress", success: true, count: records.count)
        } catch {
            AppLogger.data(operation: .fetch, entity: "AchievementProgress", success: false, error: error)
            records = []
        }

        var dict: [String: AchievementProgress] = [:]
        for record in records {
            dict[record.achievementID] = record
        }

        return dict
    }

    /// Get unlocked badges count
    /// - Returns: Number of unlocked badges
    func getUnlockedCount() -> Int {
        let metrics = getOrCreateMetrics()
        return metrics.unlockedAchievementIDs.count
    }

    // MARK: - Private Helper Methods

    /// Get or create achievement progress record
    private func getOrCreateProgress(for achievementID: String) -> AchievementProgress {
        if let record = getProgressRecord(for: achievementID) {
            return record
        }

        // Create new progress record
        let progress = AchievementProgress(achievementID: achievementID)
        modelContext.insert(progress)
        return progress
    }

    /// Get existing progress record
    private func getProgressRecord(for achievementID: String) -> AchievementProgress? {
        let descriptor = FetchDescriptor<AchievementProgress>(
            predicate: #Predicate<AchievementProgress> { record in
                record.achievementID == achievementID
            }
        )

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            AppLogger.data(operation: .fetch, entity: "AchievementProgress", success: false, error: error)
            return nil
        }
    }

    /// Get or create UserEngagementMetrics
    private func getOrCreateMetrics() -> UserEngagementMetrics {
        let descriptor = FetchDescriptor<UserEngagementMetrics>()

        do {
            if let metrics = try modelContext.fetch(descriptor).first {
                return metrics
            }
        } catch {
            AppLogger.data(operation: .fetch, entity: "UserEngagementMetrics", success: false, error: error)
        }

        // Create new metrics
        let metrics = UserEngagementMetrics()
        modelContext.insert(metrics)
        return metrics
    }

    /// Get count of skin twin matches
    private func getSkinTwinMatchCount() -> Int {
        // Query MatchResultRecord
        let descriptor = FetchDescriptor<MatchResultRecord>()
        do {
            let records = try modelContext.fetch(descriptor)
            return records.count
        } catch {
            AppLogger.data(operation: .fetch, entity: "MatchResultRecord", success: false, error: error)
            return 0
        }
    }

    /// Get count of product analyses completed
    private func getProductAnalysisCount() -> Int {
        // Query skin analysis records
        let descriptor = FetchDescriptor<SkinAnalysisRecord>()
        let records: [SkinAnalysisRecord]

        do {
            records = try modelContext.fetch(descriptor)
        } catch {
            AppLogger.data(operation: .fetch, entity: "SkinAnalysisRecord", success: false, error: error)
            return 0
        }

        // Count unique products analyzed
        var productIDs = Set<String>()
        for record in records {
            // Extract product IDs from analysis (implementation depends on data structure)
            // For now, return the count of analyses
            productIDs.insert(record.id.uuidString)
        }

        return productIDs.count
    }

    /// Get count of achievement shares
    private func getShareCount() -> Int {
        let metrics = getOrCreateMetrics()
        return metrics.totalShares
    }
}
