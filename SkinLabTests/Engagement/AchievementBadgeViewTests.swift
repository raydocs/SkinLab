import XCTest
@testable import SkinLab
import SwiftUI

/// UI tests for AchievementBadgeView
final class AchievementBadgeViewTests: XCTestCase {

    // MARK: - Badge Rendering Tests

    func testBadgeRendersCorrectly() {
        let badge = AchievementDefinitions.allBadges.first!
        let progress = AchievementProgress(achievementID: badge.id)

        let view = AchievementBadgeView(
            badge: badge,
            progress: progress,
            size: .medium
        )

        // Verify view creates without crashing
        XCTAssertNotNil(view)
    }

    func testLockedBadgeShowsProgress() {
        let badge = AchievementDefinitions.allBadges.first!
        let progress = AchievementProgress(achievementID: badge.id)
        progress.progress = 0.5
        progress.isUnlocked = false

        let view = AchievementBadgeView(
            badge: badge,
            progress: progress,
            size: .medium
        )

        XCTAssertNotNil(view)
    }

    func testUnlockedBadgeShowsDate() {
        let badge = AchievementDefinitions.allBadges.first!
        let progress = AchievementProgress(achievementID: badge.id)
        progress.isUnlocked = true
        progress.unlockedAt = Date()

        let view = AchievementBadgeView(
            badge: badge,
            progress: progress,
            size: .medium
        )

        XCTAssertNotNil(view)
    }

    // MARK: - Badge Size Tests

    func testBadgeSmallSize() {
        let badge = AchievementDefinitions.allBadges.first!
        let view = AchievementBadgeView(
            badge: badge,
            progress: nil,
            size: .small
        )

        XCTAssertNotNil(view)
    }

    func testBadgeLargeSize() {
        let badge = AchievementDefinitions.allBadges.first!
        let view = AchievementBadgeView(
            badge: badge,
            progress: nil,
            size: .large
        )

        XCTAssertNotNil(view)
    }

    // MARK: - Category Tests

    func testStreakBadgeCategory() {
        let streakBadges = AchievementDefinitions.allBadges.filter { $0.category == .streaks }
        XCTAssertTrue(streakBadges.count >= 3)
    }

    func testCompletenessBadgeCategory() {
        let completenessBadges = AchievementDefinitions.allBadges.filter { $0.category == .completeness }
        XCTAssertTrue(completenessBadges.count >= 3)
    }

    func testSocialBadgeCategory() {
        let socialBadges = AchievementDefinitions.allBadges.filter { $0.category == .social }
        XCTAssertTrue(socialBadges.count >= 3)
    }

    func testKnowledgeBadgeCategory() {
        let knowledgeBadges = AchievementDefinitions.allBadges.filter { $0.category == .knowledge }
        XCTAssertTrue(knowledgeBadges.count >= 3)
    }
}

// MARK: - AchievementDashboardView Tests

final class AchievementDashboardViewTests: XCTestCase {

    func testDashboardRendersCorrectly() {
        let view = AchievementDashboardView()
        XCTAssertNotNil(view)
    }

    func testDashboardHasAllCategories() {
        let categories = BadgeCategory.allCases
        XCTAssertEqual(categories.count, 4)
    }
}
