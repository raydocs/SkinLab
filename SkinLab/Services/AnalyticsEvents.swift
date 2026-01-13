import Foundation

/// Analytics event logging
struct AnalyticsEvents {
    /// Log an analytics event
    static func logEvent(name: String, parameters: [String: Any]? = nil) {
        // TODO: Integrate with analytics provider (Firebase, Mixpanel, etc.)
        #if DEBUG
        print("[Analytics] \(name): \(parameters ?? [:])")
        #endif
    }
}
