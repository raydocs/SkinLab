import Foundation

/// Centralized constants for the Tracking feature
enum TrackingConstants {
    /// Standard check-in schedule days: Day 0 (baseline), then weekly at days 7, 14, 21, and 28
    static let checkInDays: [Int] = [0, 7, 14, 21, 28]

    /// Total duration of a tracking session in days
    static let sessionDurationDays: Int = 28

    /// Total number of check-in points
    static let totalCheckInCount: Int = checkInDays.count
}
