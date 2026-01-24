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
}
