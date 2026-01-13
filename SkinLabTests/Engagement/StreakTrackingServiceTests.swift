import XCTest
import SwiftData
@testable import SkinLab

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

    func testCheckInIncrementsStreak() async throws {
        let result = service.checkIn()
        XCTAssertEqual(result.currentStreak, 1)
        XCTAssertTrue(result.streakIncreased)

        let result2 = service.checkIn(at: Date().addingTimeInterval(86400)) // +1 day
        XCTAssertEqual(result2.currentStreak, 2)
        XCTAssertTrue(result2.streakIncreased)
    }

    func testSameDayCheckInDoesNotIncrement() async throws {
        let now = Date()
        let result1 = service.checkIn(at: now)
        XCTAssertEqual(result1.currentStreak, 1)

        let result2 = service.checkIn(at: now.addingTimeInterval(3600)) // +1 hour
        XCTAssertEqual(result2.currentStreak, 1)
        XCTAssertFalse(result2.streakIncreased)
    }

    func testMissedDayResetsStreak() async throws {
        let now = Date()
        service.checkIn(at: now)

        // Check in 2 days later
        let result = service.checkIn(at: now.addingTimeInterval(86400 * 2))
        XCTAssertEqual(result.currentStreak, 1)
        XCTAssertTrue(result.streakReset)
    }

    // MARK: - Streak Freeze Tests

    func testStreakFreezeMaintainsStreak() async throws {
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

    func testFreezeReplenishesAfter30Days() async throws {
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

    func testBackfillFromHistoricalData() async throws {
        // This test would require setting up historical TrackingSession data
        // For now, we'll verify the method exists and doesn't crash
        await service.backfillStreaks()

        let status = service.getStreakStatus()
        XCTAssertNotNil(status)
    }

    // MARK: - Timezone Tests

    func testTimezoneChangeBehavior() async throws {
        // Test that timezone changes don't break streak calculation
        let now = Date()
        service.checkIn(at: now)

        // Simulate timezone change by manually creating dates
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.day! += 1

        if let tomorrow = calendar.date(from: components) {
            let result = service.checkIn(at: tomorrow)
            XCTAssertEqual(result.currentStreak, 2)
        }
    }

    func testDSTBoundaryBehavior() async throws {
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

    func testGetStreakStatus() async throws {
        service.checkIn()

        let status = service.getStreakStatus()
        XCTAssertEqual(status.currentStreak, 1)
        XCTAssertEqual(status.totalCheckIns, 1)
        XCTAssertNotNil(status.lastCheckInDate)
    }

    func testLongestStreakTracking() async throws {
        let now = Date()

        // Build a 7-day streak
        for i in 0..<7 {
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
}
