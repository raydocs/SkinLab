import Foundation
import SwiftData

/// Streak tracking result
struct StreakResult {
    let currentStreak: Int
    let longestStreak: Int
    let streakIncreased: Bool
    let streakReset: Bool
    let freezeUsed: Bool
}

/// Current streak status
struct StreakStatus {
    let currentStreak: Int
    let longestStreak: Int
    let lastCheckInDate: Date?
    let freezesAvailable: Int
    let daysUntilFreezeRefill: Int?
    let totalCheckIns: Int
}

/// Service for tracking user engagement streaks
@MainActor
final class StreakTrackingService {
    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let calendar: Calendar

    // MARK: - Constants
    private let freezeRefillDays = 30

    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.calendar = Calendar.current
    }

    // MARK: - Public Methods

    /// Record a check-in (completed tracking session)
    /// - Parameter checkInDate: The date of the check-in (defaults to now)
    /// - Returns: StreakResult with updated streak information
    func checkIn(at checkInDate: Date = Date()) -> StreakResult {
        let metrics = getOrCreateMetrics()
        let previousStreak = metrics.streakCount

        // Check if this is a same-day check-in
        if let lastDate = metrics.lastCheckInDate,
           isSameDay(lastDate, date: checkInDate) {
            // Same day check-in, don't increment streak
            return StreakResult(
                currentStreak: metrics.streakCount,
                longestStreak: metrics.longestStreak,
                streakIncreased: false,
                streakReset: false,
                freezeUsed: false
            )
        }

        // Calculate new streak
        let isNewDay = !isSameDay(lastDate: checkInDate, previousDate: metrics.lastCheckInDate)
        let isConsecutiveDay = isConsecutiveDay(lastDate: metrics.lastCheckInDate, newDate: checkInDate)

        if isNewDay && isConsecutiveDay {
            // Consecutive day, increment streak
            metrics.streakCount += 1
        } else if isNewDay && !isConsecutiveDay {
            // Missed a day, reset streak
            metrics.streakCount = 1
        }

        // Update longest streak
        if metrics.streakCount > metrics.longestStreak {
            metrics.longestStreak = metrics.streakCount
        }

        // Update check-in metadata
        metrics.lastCheckInDate = checkInDate
        metrics.totalCheckIns += 1

        // Save changes
        modelContext.insert(metrics)

        return StreakResult(
            currentStreak: metrics.streakCount,
            longestStreak: metrics.longestStreak,
            streakIncreased: metrics.streakCount > previousStreak,
            streakReset: metrics.streakCount == 1 && previousStreak > 1,
            freezeUsed: false
        )
    }

    /// Get current streak status
    /// - Returns: StreakStatus with current engagement metrics
    func getStreakStatus() -> StreakStatus {
        let metrics = getOrCreateMetrics()

        // Calculate days until freeze refill
        var daysUntilRefill: Int?
        if let lastRefill = metrics.lastFreezeRefillDate {
            let nextRefill = calendar.date(byAdding: .day, value: freezeRefillDays, to: lastRefill)
            if let nextRefill = nextRefill {
                let components = calendar.dateComponents([.day], from: Date(), to: nextRefill)
                daysUntilRefill = max(0, components.day ?? 0)
            }
        }

        return StreakStatus(
            currentStreak: metrics.streakCount,
            longestStreak: metrics.longestStreak,
            lastCheckInDate: metrics.lastCheckInDate,
            freezesAvailable: metrics.streakFreezesAvailable,
            daysUntilFreezeRefill: daysUntilRefill,
            totalCheckIns: metrics.totalCheckIns
        )
    }

    /// Use a streak freeze to maintain streak during a missed day
    /// - Returns: True if freeze was successfully used
    func useStreakFreeze() -> Bool {
        let metrics = getOrCreateMetrics()

        guard metrics.streakFreezesAvailable > 0 else {
            return false
        }

        metrics.streakFreezesAvailable -= 1
        modelContext.insert(metrics)

        return true
    }

    /// Check and refill freezes if 30-day cycle has completed
    /// Should be called on app launch
    func checkAndRefillFreezes() {
        let metrics = getOrCreateMetrics()

        guard let lastRefill = metrics.lastFreezeRefillDate else {
            // First time, set refill date
            metrics.lastFreezeRefillDate = Date()
            modelContext.insert(metrics)
            return
        }

        // Check if 30 days have passed since last refill
        if let daysSince = daysBetween(lastRefill, and: Date()),
           daysSince >= freezeRefillDays {
            metrics.streakFreezesAvailable = 1
            metrics.lastFreezeRefillDate = Date()
            modelContext.insert(metrics)
        }
    }

    /// Backfill streaks from historical tracking session data
    /// - Parameter maxDays: Maximum days to look back (default 90)
    func backfillStreaks(maxDays: Int = 90) async {
        do {
            // Fetch historical tracking sessions
            let cutoffDate = calendar.date(byAdding: .day, value: -maxDays, to: Date()) ?? Date()

            let descriptor = FetchDescriptor<TrackingSession>(
                predicate: #Predicate<TrackingSession> { session in
                    session.startDate >= cutoffDate && session.statusRaw == TrackingStatus.completed.rawValue
                },
                sortBy: [SortDescriptor(\.startDate, order: .forward)]
            )

            let sessions = try modelContext.fetch(descriptor)

            // Group sessions by calendar day
            var checkInDays = Set<String>()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.calendar = calendar

            for session in sessions {
                // Use the earliest check-in date (startDate) as the check-in day
                let dateString = dateFormatter.string(from: session.startDate)
                checkInDays.insert(dateString)
            }

            // Calculate streaks from consecutive days
            let sortedDates = checkInDays.compactMap { dateFormatter.date(from: $0) }
                                         .sorted()

            var currentStreak = 0
            var longestStreak = 0
            var previousDate: Date?

            for date in sortedDates {
                if let prev = previousDate {
                    if isConsecutiveDay(lastDate: prev, newDate: date) {
                        currentStreak += 1
                    } else {
                        currentStreak = 1
                    }
                } else {
                    currentStreak = 1
                }

                longestStreak = max(longestStreak, currentStreak)
                previousDate = date
            }

            // Update metrics
            let metrics = getOrCreateMetrics()
            metrics.streakCount = currentStreak
            metrics.longestStreak = longestStreak
            metrics.totalCheckIns = sessions.count
            if let lastSession = sessions.last {
                metrics.lastCheckInDate = lastSession.startDate
            }
            modelContext.insert(metrics)

        } catch {
            // Fallback: start from 0, log analytics event
            let metrics = getOrCreateMetrics()
            metrics.streakCount = 0
            modelContext.insert(metrics)
        }
    }

    // MARK: - Private Helper Methods

    /// Get or create UserEngagementMetrics
    private func getOrCreateMetrics() -> UserEngagementMetrics {
        let descriptor = FetchDescriptor<UserEngagementMetrics>()

        if let metrics = try? modelContext.fetch(descriptor).first {
            return metrics
        }

        // Create new metrics
        let metrics = UserEngagementMetrics()
        modelContext.insert(metrics)
        return metrics
    }

    /// Check if two dates are on the same calendar day
    private func isSameDay(_ date1: Date, date2: Date) -> Bool {
        return calendar.isDate(date1, inSameDayAs: date2)
    }

    /// Check if two dates represent consecutive days
    private func isConsecutiveDay(lastDate: Date?, newDate: Date) -> Bool {
        guard let last = lastDate else {
            return true // First check-in
        }

        let components = calendar.dateComponents([.day], from: last, to: newDate)
        return components.day == 1
    }

    /// Calculate number of days between two dates
    private func daysBetween(_ date1: Date, and date2: Date) -> Int? {
        let components = calendar.dateComponents([.day], from: date1, to: date2)
        return components.day
    }
}
