import Foundation
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

// MARK: - Analytics Provider Protocol

/// Protocol for analytics providers to enable testing and provider switching
protocol AnalyticsProvider {
    func logEvent(_ name: String, parameters: [String: Any]?)
    func setUserProperty(_ value: String?, forName name: String)
    func setUserId(_ userId: String?)
}

// MARK: - Firebase Analytics Provider

#if canImport(FirebaseAnalytics)
/// Firebase Analytics implementation
final class FirebaseAnalyticsProvider: AnalyticsProvider {
    func logEvent(_ name: String, parameters: [String: Any]?) {
        Analytics.logEvent(name, parameters: parameters)
    }

    func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }

    func setUserId(_ userId: String?) {
        Analytics.setUserID(userId)
    }
}
#endif

// MARK: - Debug Analytics Provider

/// Debug provider that only logs to console
final class DebugAnalyticsProvider: AnalyticsProvider {
    func logEvent(_ name: String, parameters: [String: Any]?) {
        // Debug logging is handled in AnalyticsService
    }

    func setUserProperty(_ value: String?, forName name: String) {
        // No-op for debug
    }

    func setUserId(_ userId: String?) {
        // No-op for debug
    }
}

// MARK: - Analytics Service

/// Central analytics service that manages provider and event logging
/// Thread-safe singleton using actor isolation pattern
final class AnalyticsService: @unchecked Sendable {
    /// Shared instance
    static let shared = AnalyticsService()

    /// Lock for thread-safe access
    private let lock = NSLock()

    /// The underlying analytics provider
    private var _provider: AnalyticsProvider

    /// Whether analytics has been configured
    private var _isConfigured = false

    var isConfigured: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isConfigured
    }

    private init() {
        // Start with debug provider until configure() is called
        self._provider = DebugAnalyticsProvider()
    }

    /// Configure analytics with the appropriate provider
    /// Call this in app initialization after Firebase is configured
    func configure() {
        lock.lock()
        defer { lock.unlock() }

        #if canImport(FirebaseAnalytics)
        self._provider = FirebaseAnalyticsProvider()
        self._isConfigured = true
        #if DEBUG
        print("[Analytics] Configured with Firebase Analytics")
        #endif
        #else
        self._provider = DebugAnalyticsProvider()
        self._isConfigured = true
        #if DEBUG
        print("[Analytics] Configured with Debug provider (Firebase not available)")
        #endif
        #endif
    }

    /// Log an analytics event
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        // Always log to console in DEBUG mode
        #if DEBUG
        print("[Analytics] \(name): \(parameters ?? [:])")
        #endif

        // Forward to the configured provider
        lock.lock()
        let provider = _provider
        lock.unlock()

        provider.logEvent(name, parameters: parameters)
    }

    /// Set a user property
    func setUserProperty(_ value: String?, forName name: String) {
        #if DEBUG
        print("[Analytics] User property '\(name)': \(value ?? "nil")")
        #endif

        lock.lock()
        let provider = _provider
        lock.unlock()

        provider.setUserProperty(value, forName: name)
    }

    /// Set the user ID for analytics
    func setUserId(_ userId: String?) {
        #if DEBUG
        print("[Analytics] User ID: \(userId ?? "nil")")
        #endif

        lock.lock()
        let provider = _provider
        lock.unlock()

        provider.setUserId(userId)
    }

    /// Set a custom provider (primarily for testing)
    func setProvider(_ provider: AnalyticsProvider) {
        lock.lock()
        defer { lock.unlock() }
        self._provider = provider
    }
}

// MARK: - Analytics Events

/// Analytics event logging facade
/// Provides convenient static methods that delegate to AnalyticsService
struct AnalyticsEvents {
    /// Log an analytics event
    static func logEvent(name: String, parameters: [String: Any]? = nil) {
        AnalyticsService.shared.logEvent(name, parameters: parameters)
    }

    /// Set a user property
    static func setUserProperty(_ value: String?, forName name: String) {
        AnalyticsService.shared.setUserProperty(value, forName: name)
    }

    /// Set the user ID
    static func setUserId(_ userId: String?) {
        AnalyticsService.shared.setUserId(userId)
    }

    // MARK: - Core Feature Events

    /// Source of skin analysis
    enum AnalysisSource: String {
        case camera = "camera"
        case library = "library"
        case homeButton = "home_button"
    }

    /// Log analysis started event
    static func analysisStarted(source: AnalysisSource) {
        logEvent(
            name: "analysis_started",
            parameters: [
                "source": source.rawValue
            ]
        )
    }

    /// Log analysis completed event
    static func analysisCompleted(skinType: String, score: Int, durationSeconds: Double) {
        logEvent(
            name: "analysis_completed",
            parameters: [
                "skin_type": skinType,
                "score": score,
                "duration_seconds": durationSeconds
            ]
        )
    }

    /// Log check-in completed event
    static func checkInCompleted(day: Int, sessionId: String, streakCount: Int) {
        logEvent(
            name: "check_in_completed",
            parameters: [
                "check_in_day": day,
                "session_id": sessionId,
                "streak_count": streakCount
            ]
        )
    }

    // MARK: - Feature Usage Events

    /// Source of product addition
    enum ProductAddSource: String {
        case manual = "manual"
        case scan = "scan"
        case search = "search"
    }

    /// Log product added event
    static func productAdded(name: String, brand: String? = nil, source: ProductAddSource = .manual) {
        var params: [String: Any] = [
            "product_name": name,
            "source": source.rawValue
        ]
        if let brand = brand {
            params["product_brand"] = brand
        }
        logEvent(name: "product_added", parameters: params)
    }

    /// Log product scanned event
    static func productScanned(success: Bool) {
        logEvent(
            name: "product_scanned",
            parameters: [
                "success": success
            ]
        )
    }

    /// Log report viewed event
    static func reportViewed(analysisId: String, score: Int) {
        logEvent(
            name: "report_viewed",
            parameters: [
                "analysis_id": analysisId,
                "score": score
            ]
        )
    }

    /// Log scenario selected event
    static func scenarioSelected(scenario: String) {
        logEvent(
            name: "scenario_selected",
            parameters: [
                "scenario": scenario
            ]
        )
    }

    // MARK: - Engagement Events

    /// Log badge earned event
    static func badgeEarned(achievementId: String, badgeName: String) {
        logEvent(
            name: "badge_earned",
            parameters: [
                "achievement_id": achievementId,
                "badge_name": badgeName
            ]
        )
    }

    /// Log freeze used event
    static func freezeUsed(streakCount: Int, freezesRemaining: Int) {
        logEvent(
            name: "freeze_used",
            parameters: [
                "streak_count": streakCount,
                "freezes_remaining": freezesRemaining
            ]
        )
    }

    // MARK: - Navigation Events

    /// Log feature discovered event (first time user interacts with a feature)
    /// Uses UserDefaults to ensure it only fires once per feature
    static func featureDiscovered(featureName: String) {
        let key = "analytics.feature_discovered.\(featureName)"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        logEvent(
            name: "feature_discovered",
            parameters: [
                "feature_name": featureName
            ]
        )
    }
}
