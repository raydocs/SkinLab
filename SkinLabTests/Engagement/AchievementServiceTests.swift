@testable import SkinLab
import SwiftData
import XCTest

/// Unit tests for AchievementService
final class AchievementServiceTests: XCTestCase {
    var modelContext: ModelContext!
    var streakService: StreakTrackingService!
    var achievementService: AchievementService!

    override func setUp() async throws {
        let schema = Schema([
            UserEngagementMetrics.self,
            AchievementProgress.self,
            MatchResultRecord.self,
            SkinAnalysisRecord.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(container)
        streakService = StreakTrackingService(modelContext: modelContext)
        achievementService = AchievementService(
            modelContext: modelContext,
            streakService: streakService
        )
    }

    override func tearDown() async throws {
        modelContext = nil
        streakService = nil
        achievementService = nil
    }

    // MARK: - Badge Progress Tests

    func testBadgeProgressCalculation() {
        streakService.checkIn()

        // Check first analysis badge (requires 1 check-in)
        let firstAnalysisBadge = AchievementDefinitions.allBadges.first { $0.id == "first_analysis" }
        XCTAssertNotNil(firstAnalysisBadge)

        if let badge = firstAnalysisBadge {
            let progress = achievementService.getProgress(for: badge)
            XCTAssertEqual(progress, 1.0) // Should be complete with 1 check-in
        }

        // Check 3-day streak badge
        let streak3Badge = AchievementDefinitions.allBadges.first { $0.id == "streak_3" }
        XCTAssertNotNil(streak3Badge)

        if let badge = streak3Badge {
            let progress = achievementService.getProgress(for: badge)
            XCTAssertEqual(progress, 1.0 / 3.0) // 1 day out of 3
        }
    }

    func testBadgeUnlockOnThreshold() {
        let now = Date()

        // Build a 3-day streak
        for i in 0 ..< 3 {
            streakService.checkIn(at: now.addingTimeInterval(86400 * Double(i)))
        }

        let result = achievementService.checkAchievements()
        let unlockedIds = result.unlockedBadges.map(\.id)

        // Should have unlocked 3-day streak badge
        XCTAssertTrue(unlockedIds.contains("streak_3"))

        // Should have unlocked first analysis badge
        XCTAssertTrue(unlockedIds.contains("first_analysis"))
    }

    func testMultipleBadgeUnlocks() {
        let now = Date()

        // Build a 7-day streak
        for i in 0 ..< 7 {
            streakService.checkIn(at: now.addingTimeInterval(86400 * Double(i)))
        }

        let result = achievementService.checkAchievements()
        let unlockedIds = result.unlockedBadges.map(\.id)

        // Should unlock multiple streak badges
        XCTAssertTrue(unlockedIds.contains("streak_3"))
        XCTAssertTrue(unlockedIds.contains("streak_7"))
    }

    func testBadgeProgressPersistence() {
        let now = Date()
        streakService.checkIn(at: now)

        // Check achievements
        achievementService.checkAchievements()

        // Get progress records
        let allProgress = achievementService.getAllProgress()

        // Verify progress was saved
        XCTAssertTrue(allProgress["first_analysis"]?.isUnlocked == true)
        XCTAssertTrue(allProgress["first_analysis"]?.progress == 1.0)
    }

    // MARK: - Manual Unlock Tests

    func testManualUnlockAchievement() {
        achievementService.unlockAchievement("streak_3")

        let allProgress = achievementService.getAllProgress()
        let progress = allProgress["streak_3"]

        XCTAssertNotNil(progress)
        XCTAssertTrue(progress?.isUnlocked == true)
        XCTAssertEqual(progress?.progress, 1.0)
    }

    // MARK: - Utility Tests

    func testGetUnlockedCount() {
        XCTAssertEqual(achievementService.getUnlockedCount(), 0)

        let now = Date()
        streakService.checkIn(at: now)

        achievementService.checkAchievements()

        let count = achievementService.getUnlockedCount()
        XCTAssertGreaterThan(count, 0)
    }

    func testCheckAchievementsReturnsProgress() {
        streakService.checkIn()

        let result = achievementService.checkAchievements()

        XCTAssertFalse(result.progressUpdates.isEmpty)

        // Verify progress updates contain expected badges
        let badgeIds = result.progressUpdates.map(\.achievement.id)
        XCTAssertTrue(badgeIds.contains("first_analysis"))
        XCTAssertTrue(badgeIds.contains("streak_3"))
    }

    // MARK: - Category Tests

    func testBadgeCategories() {
        let allBadges = AchievementDefinitions.allBadges

        // Verify we have badges in each category
        let streakBadges = allBadges.filter { $0.category == .streaks }
        let completenessBadges = allBadges.filter { $0.category == .completeness }
        let socialBadges = allBadges.filter { $0.category == .social }
        let knowledgeBadges = allBadges.filter { $0.category == .knowledge }

        XCTAssertEqual(streakBadges.count, 3)
        XCTAssertEqual(completenessBadges.count, 3)
        XCTAssertEqual(socialBadges.count, 3)
        XCTAssertEqual(knowledgeBadges.count, 3)
    }

    func testBadgeRequirementTypes() {
        let allBadges = AchievementDefinitions.allBadges

        let streakDaysBadges = allBadges.filter { $0.requirementType == .streakDays }
        let checkInsBadges = allBadges.filter { $0.requirementType == .totalCheckIns }
        let twinBadges = allBadges.filter { $0.requirementType == .skinTwinMatches }
        let productBadges = allBadges.filter { $0.requirementType == .productAnalysisCompleted }

        // Verify all requirement types are present
        XCTAssertTrue(streakDaysBadges.count > 0)
        XCTAssertTrue(checkInsBadges.count > 0)
        XCTAssertTrue(twinBadges.count > 0)
        XCTAssertTrue(productBadges.count > 0)
    }
}
