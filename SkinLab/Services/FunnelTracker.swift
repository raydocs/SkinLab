import Foundation
import SwiftUI

// MARK: - Funnel Tracker

/// Tracks conversion funnels for user activation and retention analytics.
/// Uses UserDefaults to ensure first-time events only fire once per user.
final class FunnelTracker: @unchecked Sendable {
    /// Shared instance
    static let shared = FunnelTracker()

    /// Lock for thread-safe access
    private let lock = NSLock()

    /// Keys for tracking first-time events
    private enum FirstTimeKey: String {
        case firstOpen = "analytics.funnel.first_open"
        case profileStarted = "analytics.funnel.profile_started"
        case profileCompleted = "analytics.funnel.profile_completed"
        case firstAnalysisCompleted = "analytics.funnel.first_analysis_completed"
        case firstCheckInCompleted = "analytics.funnel.first_checkin_completed"
        case firstProductAdded = "analytics.funnel.first_product_added"
        case firstReportViewed = "analytics.funnel.first_report_viewed"
        case firstScenarioUsed = "analytics.funnel.first_scenario_used"
        case firstWeatherViewed = "analytics.funnel.first_weather_viewed"
        case firstPredictionUsed = "analytics.funnel.first_prediction_used"
    }

    /// User property names for Firebase Analytics
    enum UserPropertyName: String {
        case skinType = "skin_type"
        case ageGroup = "age_group"
        case daysActive = "days_active"
        case concernsCount = "concerns_count"
        case totalAnalyses = "total_analyses"
        case hasCompletedProfile = "has_completed_profile"
    }

    private init() {}

    // MARK: - New User Activation Funnel

    /// Track first app open event
    /// Funnel: App安装 → 打开App
    func trackFirstOpen() {
        trackFirstTimeEvent(
            key: .firstOpen,
            eventName: "first_open",
            parameters: [
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            ]
        )
    }

    /// Track when user starts creating their profile
    /// Funnel: 打开App → 开始Profile
    func trackProfileStarted() {
        trackFirstTimeEvent(
            key: .profileStarted,
            eventName: "profile_started",
            parameters: nil
        )
    }

    /// Track when user completes their profile
    /// Funnel: 开始Profile → 完成Profile
    func trackProfileCompleted(skinType: String?, ageGroup: String, concernsCount: Int) {
        var params: [String: Any] = [
            "age_group": ageGroup,
            "concerns_count": concernsCount
        ]
        if let skinType = skinType {
            params["skin_type"] = skinType
        }

        trackFirstTimeEvent(
            key: .profileCompleted,
            eventName: "profile_completed",
            parameters: params
        )

        // Also set user properties
        setUserProperty(skinType, forName: .skinType)
        setUserProperty(ageGroup, forName: .ageGroup)
        setUserProperty("\(concernsCount)", forName: .concernsCount)
        setUserProperty("true", forName: .hasCompletedProfile)
    }

    /// Track first skin analysis completed
    /// Funnel: 完成Profile → 首次分析
    func trackFirstAnalysisCompleted(skinType: String, score: Int) {
        trackFirstTimeEvent(
            key: .firstAnalysisCompleted,
            eventName: "first_analysis_completed",
            parameters: [
                "skin_type": skinType,
                "score": score
            ]
        )
    }

    /// Track first check-in completed
    /// Funnel: 首次分析 → 首次打卡
    func trackFirstCheckInCompleted(day: Int, sessionId: String) {
        trackFirstTimeEvent(
            key: .firstCheckInCompleted,
            eventName: "first_checkin_completed",
            parameters: [
                "check_in_day": day,
                "session_id": sessionId
            ]
        )
    }

    // MARK: - Feature Usage Depth

    /// Track first product added
    func trackFirstProductAdded(productName: String, source: String) {
        trackFirstTimeEvent(
            key: .firstProductAdded,
            eventName: "first_product_added",
            parameters: [
                "product_name": productName,
                "source": source
            ]
        )
    }

    /// Track first report viewed
    func trackFirstReportViewed(analysisId: String) {
        trackFirstTimeEvent(
            key: .firstReportViewed,
            eventName: "first_report_viewed",
            parameters: [
                "analysis_id": analysisId
            ]
        )
    }

    /// Track first scenario mode used
    func trackFirstScenarioUsed(scenario: String) {
        trackFirstTimeEvent(
            key: .firstScenarioUsed,
            eventName: "first_scenario_used",
            parameters: [
                "scenario": scenario
            ]
        )
    }

    /// Track first weather suggestion viewed
    func trackFirstWeatherViewed() {
        trackFirstTimeEvent(
            key: .firstWeatherViewed,
            eventName: "first_weather_viewed",
            parameters: nil
        )
    }

    /// Track first prediction feature used
    func trackFirstPredictionUsed() {
        trackFirstTimeEvent(
            key: .firstPredictionUsed,
            eventName: "first_prediction_used",
            parameters: nil
        )
    }

    // MARK: - User Properties

    /// Set a user property for analytics segmentation
    func setUserProperty(_ value: String?, forName name: UserPropertyName) {
        AnalyticsService.shared.setUserProperty(value, forName: name.rawValue)
    }

    /// Update user properties based on profile data
    func updateUserProperties(
        skinType: String?,
        ageGroup: String,
        concernsCount: Int,
        daysActive: Int
    ) {
        setUserProperty(skinType, forName: .skinType)
        setUserProperty(ageGroup, forName: .ageGroup)
        setUserProperty("\(concernsCount)", forName: .concernsCount)
        setUserProperty("\(daysActive)", forName: .daysActive)
    }

    /// Update total analyses count
    func updateTotalAnalyses(_ count: Int) {
        setUserProperty("\(count)", forName: .totalAnalyses)
    }

    // MARK: - DAU/WAU Session Tracking

    /// Track daily active session start
    /// Call this when app becomes active
    func trackSessionStart() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastSessionKey = "analytics.funnel.last_session_date"

        lock.lock()
        let lastSessionTimestamp = UserDefaults.standard.double(forKey: lastSessionKey)
        lock.unlock()

        let lastSessionDate = Date(timeIntervalSince1970: lastSessionTimestamp)
        let lastSessionDay = Calendar.current.startOfDay(for: lastSessionDate)

        // Only log if this is the first session of the day
        if lastSessionTimestamp == 0 || lastSessionDay < today {
            AnalyticsEvents.logEvent(
                name: "session_start",
                parameters: [
                    "is_new_day": true,
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ]
            )

            lock.lock()
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastSessionKey)
            lock.unlock()

            // Update days active count
            incrementDaysActive()
        }
    }

    /// Increment the days active counter
    private func incrementDaysActive() {
        let daysActiveKey = "analytics.funnel.days_active"

        lock.lock()
        let currentDays = UserDefaults.standard.integer(forKey: daysActiveKey)
        let newDays = currentDays + 1
        UserDefaults.standard.set(newDays, forKey: daysActiveKey)
        lock.unlock()

        setUserProperty("\(newDays)", forName: .daysActive)
    }

    /// Get the current days active count
    func getDaysActive() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return UserDefaults.standard.integer(forKey: "analytics.funnel.days_active")
    }

    // MARK: - Private Helpers

    /// Track a first-time event (only fires once per user)
    private func trackFirstTimeEvent(
        key: FirstTimeKey,
        eventName: String,
        parameters: [String: Any]?
    ) {
        lock.lock()
        let alreadyTracked = UserDefaults.standard.bool(forKey: key.rawValue)
        lock.unlock()

        guard !alreadyTracked else {
            #if DEBUG
            print("[FunnelTracker] Event '\(eventName)' already tracked, skipping")
            #endif
            return
        }

        // Mark as tracked before logging to prevent race conditions
        lock.lock()
        UserDefaults.standard.set(true, forKey: key.rawValue)
        lock.unlock()

        // Log the event
        AnalyticsEvents.logEvent(name: eventName, parameters: parameters)

        #if DEBUG
        print("[FunnelTracker] First-time event tracked: \(eventName)")
        #endif
    }

    // MARK: - Testing Support

    /// Reset all first-time tracking (for testing only)
    #if DEBUG
    func resetAllTracking() {
        lock.lock()
        defer { lock.unlock() }

        let keysToReset: [FirstTimeKey] = [
            .firstOpen, .profileStarted, .profileCompleted,
            .firstAnalysisCompleted, .firstCheckInCompleted,
            .firstProductAdded, .firstReportViewed,
            .firstScenarioUsed, .firstWeatherViewed, .firstPredictionUsed
        ]

        for key in keysToReset {
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }

        UserDefaults.standard.removeObject(forKey: "analytics.funnel.last_session_date")
        UserDefaults.standard.removeObject(forKey: "analytics.funnel.days_active")

        print("[FunnelTracker] All tracking reset")
    }
    #endif
}

// MARK: - SwiftUI View Modifier for Tracking

/// View modifier to track when a view appears (for funnel tracking)
struct FunnelTrackingModifier: ViewModifier {
    let onAppear: () -> Void

    func body(content: Content) -> some View {
        content.onAppear(perform: onAppear)
    }
}

extension View {
    /// Track first open when this view appears
    func trackFirstOpen() -> some View {
        modifier(FunnelTrackingModifier {
            FunnelTracker.shared.trackFirstOpen()
        })
    }

    /// Track profile started when this view appears
    func trackProfileStarted() -> some View {
        modifier(FunnelTrackingModifier {
            FunnelTracker.shared.trackProfileStarted()
        })
    }
}
