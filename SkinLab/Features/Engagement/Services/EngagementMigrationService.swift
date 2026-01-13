import Foundation
import SwiftData

/// Service for migrating existing user data to engagement system
@MainActor
final class EngagementMigrationService {
    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let streakService: StreakTrackingService

    // MARK: - Migration Keys
    private let migrationCompletedKey = "engagement_migration_completed"

    // MARK: - Initialization
    init(modelContext: ModelContext, streakService: StreakTrackingService) {
        self.modelContext = modelContext
        self.streakService = streakService
    }

    // MARK: - Public Methods

    /// Check if migration has been completed
    var hasCompletedMigration: Bool {
        UserDefaults.standard.bool(forKey: migrationCompletedKey)
    }

    /// Run one-time migration for existing users
    /// - Parameter maxDays: Maximum days to look back for historical data (default 90)
    func migrate(maxDays: Int = 90) async {
        guard !hasCompletedMigration else { return }

        // Run backfill (error handling is internal to backfillStreaks)
        await streakService.backfillStreaks(maxDays: maxDays)

        // Mark migration as complete
        UserDefaults.standard.set(true, forKey: migrationCompletedKey)
    }
}
