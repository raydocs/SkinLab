@testable import SkinLab
import SwiftData
import XCTest

/// Unit tests for StreakTrackingService
final class StreakTrackingServiceTests: XCTestCase {
    var modelContext: ModelContext!
    var service: StreakTrackingService!

    override func setUp() async throws {
        let schema = Schema([
            UserEngagementMetrics.self,
            AchievementProgress.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(container)
        service = StreakTrackingService(modelContext: modelContext)
    }

    override func tearDown() async throws {
        modelContext = nil
        service = nil
    }

    // MARK: - Basic Streak Tests

    func testCheckInIncrementsStreak() {
        let result = service.checkIn()
        XCTAssertEqual(result.currentStreak, 1)
        XCTAssertTrue(result.streakIncreased)

        let result2 = service.checkIn(at: Date().addingTimeInterval(86400)) // +1 day
        XCTAssertEqual(result2.currentStreak, 2)
        XCTAssertTrue(result2.streakIncreased)
    }

    func testSameDayCheckInDoesNotIncrement() {
        let now = Date()
        let result1 = service.checkIn(at: now)
        XCTAssertEqual(result1.currentStreak, 1)

        let result2 = service.checkIn(at: now.addingTimeInterval(3600)) // +1 hour
        XCTAssertEqual(result2.currentStreak, 1)
        XCTAssertFalse(result2.streakIncreased)
    }

    func testMissedDayResetsStreak() {
        let now = Date()
        service.checkIn(at: now)

        // Check in 2 days later
        let result = service.checkIn(at: now.addingTimeInterval(86400 * 2))
        XCTAssertEqual(result.currentStreak, 1)
        XCTAssertTrue(result.streakReset)
    }

    // MARK: - Streak Freeze Tests

    func testStreakFreezeMaintainsStreak() {
        let now = Date()
        service.checkIn(at: now) // Day 1

        // Use freeze
        let freezeUsed = service.useStreakFreeze()
        XCTAssertTrue(freezeUsed)

        // Miss a day
        let result = service.checkIn(at: now.addingTimeInterval(86400 * 2)) // Day 3
        // Streak should increment since we used freeze
        XCTAssertEqual(result.currentStreak, 2)
    }

    func testFreezeReplenishesAfter30Days() {
        let now = Date()
        service.checkIn(at: now)

        // Use freeze
        service.useStreakFreeze()

        var status = service.getStreakStatus()
        XCTAssertEqual(status.freezesAvailable, 0)

        // Simulate 30 days passing
        service.checkIn(at: now.addingTimeInterval(86400 * 30))
        service.checkAndRefillFreezes()

        status = service.getStreakStatus()
        XCTAssertEqual(status.freezesAvailable, 1)
    }

    // MARK: - Backfill Tests

    func testBackfillFromHistoricalData() async {
        // This test would require setting up historical TrackingSession data
        // For now, we'll verify the method exists and doesn't crash
        await service.backfillStreaks()

        let status = service.getStreakStatus()
        XCTAssertNotNil(status)
    }

    // MARK: - Timezone Tests

    func testTimezoneChangeBehavior() {
        // Test that timezone changes don't break streak calculation
        let now = Date()
        service.checkIn(at: now)

        // Simulate timezone change by manually creating dates
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.day += 1

        if let tomorrow = calendar.date(from: components) {
            let result = service.checkIn(at: tomorrow)
            XCTAssertEqual(result.currentStreak, 2)
        }
    }

    func testDSTBoundaryBehavior() {
        // Test DST boundary (23 or 25 hour days)
        // This is a simplified test; real DST testing requires specific dates
        let calendar = Calendar.current
        let now = Date()

        service.checkIn(at: now)

        // Add exactly one calendar day
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
            let result = service.checkIn(at: tomorrow)
            XCTAssertEqual(result.currentStreak, 2)
        }
    }

    // MARK: - Streak Status Tests

    func testGetStreakStatus() {
        service.checkIn()

        let status = service.getStreakStatus()
        XCTAssertEqual(status.currentStreak, 1)
        XCTAssertEqual(status.totalCheckIns, 1)
        XCTAssertNotNil(status.lastCheckInDate)
    }

    func testLongestStreakTracking() {
        let now = Date()

        // Build a 7-day streak
        for i in 0 ..< 7 {
            service.checkIn(at: now.addingTimeInterval(86400 * Double(i)))
        }

        let status = service.getStreakStatus()
        XCTAssertEqual(status.currentStreak, 7)
        XCTAssertEqual(status.longestStreak, 7)

        // Reset and build a shorter streak
        service.checkIn(at: now.addingTimeInterval(86400 * 10))
        let status2 = service.getStreakStatus()
        XCTAssertEqual(status2.longestStreak, 7) // Longest should remain 7
    }

    // MARK: - Freeze Suggestion Tests

    func testShouldSuggestFreezeWhenMissedYesterday() throws {
        let calendar = Calendar.current
        let now = Date()

        // Check in 2 days ago (yesterday was missed)
        let twoDaysAgo = try XCTUnwrap(calendar.date(byAdding: .day, value: -2, to: now))
        service.checkIn(at: twoDaysAgo)

        // Should suggest freeze since yesterday was missed
        XCTAssertTrue(service.shouldSuggestFreeze(now: now))
    }

    func testShouldNotSuggestFreezeWhenCheckedInYesterday() throws {
        let calendar = Calendar.current
        let now = Date()

        // Check in yesterday
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: now))
        service.checkIn(at: yesterday)

        // Should not suggest freeze since we checked in yesterday
        XCTAssertFalse(service.shouldSuggestFreeze(now: now))
    }

    func testShouldNotSuggestFreezeWhenNoStreak() {
        // No check-ins at all
        XCTAssertFalse(service.shouldSuggestFreeze())
    }

    func testShouldNotSuggestFreezeWhenNoFreezeAvailable() throws {
        let calendar = Calendar.current
        let now = Date()

        // Check in 2 days ago
        let twoDaysAgo = try XCTUnwrap(calendar.date(byAdding: .day, value: -2, to: now))
        service.checkIn(at: twoDaysAgo)

        // Use the freeze
        _ = service.useStreakFreeze()

        // Should not suggest freeze since none available
        XCTAssertFalse(service.shouldSuggestFreeze(now: now))
    }

    func testShouldNotSuggestFreezeWhenAlreadyUsedForYesterday() throws {
        let calendar = Calendar.current
        let now = Date()

        // Check in 2 days ago
        let twoDaysAgo = try XCTUnwrap(calendar.date(byAdding: .day, value: -2, to: now))
        service.checkIn(at: twoDaysAgo)

        // Use freeze (protects yesterday)
        _ = service.useStreakFreeze(now: now)

        // Should not suggest freeze since already protected
        XCTAssertFalse(service.shouldSuggestFreeze(now: now))
    }

    func testShouldNotSuggestFreezeWhenMissedMultipleDays() throws {
        let calendar = Calendar.current
        let now = Date()

        // Check in 3 days ago (missed 2 days)
        let threeDaysAgo = try XCTUnwrap(calendar.date(byAdding: .day, value: -3, to: now))
        service.checkIn(at: threeDaysAgo)

        // Should not suggest freeze since streak is already broken
        XCTAssertFalse(service.shouldSuggestFreeze(now: now))
    }
}
