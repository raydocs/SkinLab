@testable import SkinLab
import XCTest

/// Unit tests for AnalyticsService and AnalyticsEvents
final class AnalyticsServiceTests: XCTestCase {
    // MARK: - Mock Analytics Provider

    /// Mock provider for testing analytics calls
    final class MockAnalyticsProvider: AnalyticsProvider {
        var loggedEvents: [(name: String, parameters: [String: Any]?)] = []
        var userProperties: [(name: String, value: String?)] = []
        var userId: String?

        func logEvent(_ name: String, parameters: [String: Any]?) {
            loggedEvents.append((name: name, parameters: parameters))
        }

        func setUserProperty(_ value: String?, forName name: String) {
            userProperties.append((name: name, value: value))
        }

        func setUserId(_ userId: String?) {
            self.userId = userId
        }

        func reset() {
            loggedEvents.removeAll()
            userProperties.removeAll()
            userId = nil
        }
    }

    // MARK: - Properties

    private var mockProvider: MockAnalyticsProvider!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockProvider = MockAnalyticsProvider()
        // Inject mock provider
        AnalyticsService.shared.setProvider(mockProvider)
    }

    override func tearDown() {
        mockProvider = nil
        super.tearDown()
    }

    // MARK: - AnalyticsService Tests

    func testLogEvent() {
        // When
        AnalyticsService.shared.logEvent("test_event", parameters: ["key": "value"])

        // Then
        XCTAssertEqual(mockProvider.loggedEvents.count, 1)
        XCTAssertEqual(mockProvider.loggedEvents[0].name, "test_event")
        XCTAssertEqual(mockProvider.loggedEvents[0].parameters?["key"] as? String, "value")
    }

    func testLogEventWithoutParameters() {
        // When
        AnalyticsService.shared.logEvent("simple_event")

        // Then
        XCTAssertEqual(mockProvider.loggedEvents.count, 1)
        XCTAssertEqual(mockProvider.loggedEvents[0].name, "simple_event")
        XCTAssertNil(mockProvider.loggedEvents[0].parameters)
    }

    func testLogEventWithMultipleParameters() {
        // When
        AnalyticsService.shared.logEvent("complex_event", parameters: [
            "string_param": "hello",
            "int_param": 42,
            "bool_param": true,
            "double_param": 3.14
        ])

        // Then
        XCTAssertEqual(mockProvider.loggedEvents.count, 1)
        let params = mockProvider.loggedEvents[0].parameters
        XCTAssertEqual(params?["string_param"] as? String, "hello")
        XCTAssertEqual(params?["int_param"] as? Int, 42)
        XCTAssertEqual(params?["bool_param"] as? Bool, true)
        XCTAssertEqual(params?["double_param"] as? Double, 3.14)
    }

    func testSetUserProperty() {
        // When
        AnalyticsService.shared.setUserProperty("premium", forName: "subscription_type")

        // Then
        XCTAssertEqual(mockProvider.userProperties.count, 1)
        XCTAssertEqual(mockProvider.userProperties[0].name, "subscription_type")
        XCTAssertEqual(mockProvider.userProperties[0].value, "premium")
    }

    func testSetUserPropertyNil() {
        // When
        AnalyticsService.shared.setUserProperty(nil, forName: "subscription_type")

        // Then
        XCTAssertEqual(mockProvider.userProperties.count, 1)
        XCTAssertNil(mockProvider.userProperties[0].value)
    }

    func testSetUserId() {
        // When
        AnalyticsService.shared.setUserId("user_123")

        // Then
        XCTAssertEqual(mockProvider.userId, "user_123")
    }

    func testSetUserIdNil() {
        // Given
        mockProvider.userId = "existing_user"

        // When
        AnalyticsService.shared.setUserId(nil)

        // Then
        XCTAssertNil(mockProvider.userId)
    }

    // MARK: - AnalyticsEvents Facade Tests

    func testAnalyticsEventsLogEvent() {
        // When
        AnalyticsEvents.logEvent(name: "facade_event", parameters: ["source": "test"])

        // Then
        XCTAssertEqual(mockProvider.loggedEvents.count, 1)
        XCTAssertEqual(mockProvider.loggedEvents[0].name, "facade_event")
        XCTAssertEqual(mockProvider.loggedEvents[0].parameters?["source"] as? String, "test")
    }

    func testAnalyticsEventsSetUserProperty() {
        // When
        AnalyticsEvents.setUserProperty("dark", forName: "theme")

        // Then
        XCTAssertEqual(mockProvider.userProperties.count, 1)
        XCTAssertEqual(mockProvider.userProperties[0].name, "theme")
        XCTAssertEqual(mockProvider.userProperties[0].value, "dark")
    }

    func testAnalyticsEventsSetUserId() {
        // When
        AnalyticsEvents.setUserId("facade_user")

        // Then
        XCTAssertEqual(mockProvider.userId, "facade_user")
    }

    // MARK: - DebugAnalyticsProvider Tests

    func testDebugProviderDoesNotCrash() {
        // Given
        let debugProvider = DebugAnalyticsProvider()

        // When/Then - should not crash
        debugProvider.logEvent("debug_event", parameters: ["key": "value"])
        debugProvider.setUserProperty("value", forName: "name")
        debugProvider.setUserId("user_123")

        XCTAssertTrue(true) // If we reach here, test passes
    }

    // MARK: - Multiple Events Tests

    func testMultipleEventsInSequence() {
        // When
        AnalyticsEvents.logEvent(name: "event_1")
        AnalyticsEvents.logEvent(name: "event_2", parameters: ["param": "value"])
        AnalyticsEvents.logEvent(name: "event_3")

        // Then
        XCTAssertEqual(mockProvider.loggedEvents.count, 3)
        XCTAssertEqual(mockProvider.loggedEvents[0].name, "event_1")
        XCTAssertEqual(mockProvider.loggedEvents[1].name, "event_2")
        XCTAssertEqual(mockProvider.loggedEvents[2].name, "event_3")
    }

    // MARK: - Engagement Events Extension Tests

    func testCelebrationShownEvent() {
        // When
        AnalyticsEvents.celebrationShown(milestone: 7, type: .streakMilestone)

        // Then
        XCTAssertEqual(mockProvider.loggedEvents.count, 1)
        XCTAssertEqual(mockProvider.loggedEvents[0].name, "celebration_shown")
        XCTAssertEqual(mockProvider.loggedEvents[0].parameters?["milestone"] as? Int, 7)
        XCTAssertEqual(mockProvider.loggedEvents[0].parameters?["type"] as? String, "streak_milestone")
    }

    func testAchievementSharedEvent() {
        // When
        AnalyticsEvents.achievementShared(achievementId: "ach_001", platform: "instagram")

        // Then
        XCTAssertEqual(mockProvider.loggedEvents.count, 1)
        XCTAssertEqual(mockProvider.loggedEvents[0].name, "achievement_shared")
        XCTAssertEqual(mockProvider.loggedEvents[0].parameters?["achievement_id"] as? String, "ach_001")
        XCTAssertEqual(mockProvider.loggedEvents[0].parameters?["platform"] as? String, "instagram")
    }

    func testAchievementSharedEventWithoutPlatform() {
        // When
        AnalyticsEvents.achievementShared(achievementId: "ach_002")

        // Then
        XCTAssertEqual(mockProvider.loggedEvents.count, 1)
        XCTAssertEqual(mockProvider.loggedEvents[0].name, "achievement_shared")
        XCTAssertNil(mockProvider.loggedEvents[0].parameters?["platform"])
    }

    func testMilestoneReachedEvent() {
        // When
        AnalyticsEvents.milestoneReached(milestone: 30, type: .streak)

        // Then
        XCTAssertEqual(mockProvider.loggedEvents.count, 1)
        XCTAssertEqual(mockProvider.loggedEvents[0].name, "milestone_reached")
        XCTAssertEqual(mockProvider.loggedEvents[0].parameters?["milestone"] as? Int, 30)
        XCTAssertEqual(mockProvider.loggedEvents[0].parameters?["type"] as? String, "streak")
    }
}
