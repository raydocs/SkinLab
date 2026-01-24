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
    init(modelContext: ModelContext, calendar: Calendar = .current) {
        self.modelContext = modelContext
        self.calendar = calendar
    }

    // MARK: - Public Methods

    /// Record a check-in (completed tracking session)
    /// - Parameter checkInDate: The date of the check-in (defaults to now)
    /// - Returns: StreakResult with updated streak information
    func checkIn(at checkInDate: Date = Date()) -> StreakResult {
        let metrics = getOrCreateMetrics()
        let previousStreak = metrics.streakCount

        // Normalize to calendar days
        let checkInDay = dayKey(for: checkInDate)
        let lastCheckInDay = metrics.lastCheckInDate.map { dayKey(for: $0) }

        // Check if this is a same-day check-in
        if let lastDay = lastCheckInDay,
           calendar.isDate(checkInDay, inSameDayAs: lastDay) {
            // Same day check-in, don't increment streak
            return StreakResult(
                currentStreak: metrics.streakCount,
                longestStreak: metrics.longestStreak,
                streakIncreased: false,
                streakReset: false,
                freezeUsed: false
            )
        }

        // Calculate days since last check-in
        let daysSince = deltaDays(from: lastCheckInDay, to: checkInDay)

        // Check if a freeze was used for the missed day (retroactive)
        let missedDay = lastCheckInDay.map { calendar.date(byAdding: .day, value: 1, to: $0)! }
        let freezeWasUsed = missedDay != nil && metrics.lastFreezeUsedForDay != nil &&
                              calendar.isDate(metrics.lastFreezeUsedForDay!, inSameDayAs: missedDay!)

        // Determine if streak is maintained (with freeze or consecutive)
        let streakMaintained: Bool
        if daysSince == 1 {
            // Consecutive day - increment streak
            streakMaintained = true
        } else if daysSince == 2 && freezeWasUsed {
            // Missed one day but freeze was used
            streakMaintained = true
        } else if daysSince >= 2 {
            // Missed multiple days or no freeze - reset streak
            streakMaintained = false
        } else {
            // Same day or first check-in
            streakMaintained = true
        }

        // Update streak count
        if streakMaintained {
            if daysSince > 0 {
                metrics.streakCount += 1
            }
        } else {
            // Reset to 1 (starting fresh streak)
            metrics.streakCount = 1
        }

        // Update longest streak
        if metrics.streakCount > metrics.longestStreak {
            metrics.longestStreak = metrics.streakCount
        }

        // Update check-in metadata
        metrics.lastCheckInDate = checkInDate
        metrics.totalCheckIns += 1

        // Clear freeze usage flag if it was consumed
        if freezeWasUsed && daysSince == 2 {
            metrics.lastFreezeUsedForDay = nil
        }

        // Save changes
        modelContext.insert(metrics)

        return StreakResult(
            currentStreak: metrics.streakCount,
            longestStreak: metrics.longestStreak,
            streakIncreased: metrics.streakCount > previousStreak,
            streakReset: metrics.streakCount == 1 && previousStreak > 1 && !streakMaintained,
            freezeUsed: freezeWasUsed
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
    /// - Parameter now: Current date (defaults to now)
    /// - Returns: True if freeze was successfully used
    func useStreakFreeze(now: Date = Date()) -> Bool {
        let metrics = getOrCreateMetrics()

        guard metrics.streakFreezesAvailable > 0 else {
            return false
        }

        // Mark the day after last check-in as protected
        // If no previous check-in, protect tomorrow
        let nowDay = dayKey(for: now)
        let dayToProtect: Date
        if let lastCheckIn = metrics.lastCheckInDate {
            let lastCheckInDay = dayKey(for: lastCheckIn)
            dayToProtect = calendar.date(byAdding: .day, value: 1, to: lastCheckInDay) ?? nowDay
        } else {
            dayToProtect = calendar.date(byAdding: .day, value: 1, to: nowDay) ?? nowDay
        }

        metrics.streakFreezesAvailable -= 1
        metrics.lastFreezeUsedForDay = dayToProtect
        modelContext.insert(metrics)

        return true
    }

    /// Check if user should be suggested to use a freeze
    /// Returns true if: yesterday was missed, user has freezes available, and has an active streak
    /// - Parameter now: Current date (defaults to now)
    /// - Returns: True if freeze suggestion should be shown
    func shouldSuggestFreeze(now: Date = Date()) -> Bool {
        let metrics = getOrCreateMetrics()

        // Must have freezes available
        guard metrics.streakFreezesAvailable > 0 else {
            return false
        }

        // Must have an active streak worth protecting
        guard metrics.streakCount > 0 else {
            return false
        }

        // Check if yesterday was missed (no check-in yesterday)
        guard let lastCheckIn = metrics.lastCheckInDate else {
            return false
        }

        let lastCheckInDay = dayKey(for: lastCheckIn)
        let today = dayKey(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        // Last check-in was before yesterday (missed at least one day)
        let daysSinceLastCheckIn = deltaDays(from: lastCheckInDay, to: today)

        // Only suggest if exactly 1 day was missed (yesterday)
        // If more days were missed, streak is already broken
        if daysSinceLastCheckIn == 2 {
            // Check if freeze was already used for yesterday
            if let freezeUsedDay = metrics.lastFreezeUsedForDay,
               calendar.isDate(freezeUsedDay, inSameDayAs: yesterday) {
                return false // Already protected
            }
            return true
        }

        return false
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
        let cutoffDate = calendar.date(byAdding: .day, value: -maxDays, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<TrackingSession>(
            predicate: #Predicate<TrackingSession> { session in
                session.startDate >= cutoffDate && session.statusRaw == "completed"
            },
            sortBy: [SortDescriptor(\.startDate, order: .forward)]
        )

        let sessions: [TrackingSession]
        do {
            sessions = try modelContext.fetch(descriptor)
        } catch {
            // Fallback: start from 0
            let metrics = getOrCreateMetrics()
            metrics.streakCount = 0
            metrics.longestStreak = 0
            metrics.totalCheckIns = 0
            return
        }

        guard !sessions.isEmpty else {
            // No sessions, start from 0
            let metrics = getOrCreateMetrics()
            metrics.streakCount = 0
            metrics.longestStreak = 0
            metrics.totalCheckIns = 0
            return
        }

        // Group sessions by calendar day (unique check-in days)
        var checkInDays = Set<String>()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.calendar = calendar

        for session in sessions {
            let dateString = dateFormatter.string(from: session.startDate)
            checkInDays.insert(dateString)
        }

        // Sort all check-in days
        let sortedDates = checkInDays.compactMap { dateFormatter.date(from: $0) }
                                     .sorted()

        // Calculate streaks from consecutive days
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        var previousDate: Date?
        let today = dayKey(for: Date())

        // First pass: find longest streak
        for date in sortedDates {
            if let prev = previousDate {
                if deltaDays(from: prev, to: date) == 1 {
                    tempStreak += 1
                } else {
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
            }
            longestStreak = max(longestStreak, tempStreak)
            previousDate = date
        }

        // Second pass: find current streak (streak leading up to today or closest past day)
        // Work backwards from the most recent check-in day
        currentStreak = 1
        if let lastDate = sortedDates.last {
            let daysFromLast = deltaDays(from: lastDate, to: today)
            if daysFromLast > 1 {
                // Last check-in was too long ago, current streak is 0
                currentStreak = 0
            } else {
                // Count consecutive days backwards from last check-in
                for i in stride(from: sortedDates.count - 1, through: 1, by: -1) {
                    let laterDate = sortedDates[i]
                    let earlierDate = sortedDates[i - 1]
                    if deltaDays(from: earlierDate, to: laterDate) == 1 {
                        currentStreak += 1
                    } else {
                        break
                    }
                }
            }
        }

        // Update metrics
        let metrics = getOrCreateMetrics()
        metrics.streakCount = max(0, currentStreak)
        metrics.longestStreak = max(currentStreak, longestStreak)
        metrics.totalCheckIns = checkInDays.count  // Unique check-in days
        if let lastSession = sessions.last {
            metrics.lastCheckInDate = lastSession.startDate
        }
    }

    // MARK: - Private Helper Methods

    /// Get or create UserEngagementMetrics
    private func getOrCreateMetrics() -> UserEngagementMetrics {
        let descriptor = FetchDescriptor<UserEngagementMetrics>()

        do {
            if let metrics = try modelContext.fetch(descriptor).first {
                return metrics
            }
        } catch {
            AppLogger.data(operation: .fetch, entity: "UserEngagementMetrics", success: false, error: error)
        }

        // Create new metrics
        let metrics = UserEngagementMetrics()
        modelContext.insert(metrics)
        return metrics
    }

    /// Normalize a date to its calendar day (start of day)
    /// This ensures DST and time-of-day don't affect streak calculations
    private func dayKey(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Calculate the number of calendar days between two dates
    private func deltaDays(from start: Date?, to end: Date) -> Int {
        guard let start = start else {
            return 1 // First check-in
        }

        let startOfDay = calendar.startOfDay(for: start)
        let endOfDay = calendar.startOfDay(for: end)
        let components = calendar.dateComponents([.day], from: startOfDay, to: endOfDay)
        return components.day ?? 1
    }

    /// Check if two dates are on the same calendar day
    private func isSameDay(_ date1: Date, date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }

    /// Check if two dates represent consecutive days
    private func isConsecutiveDay(lastDate: Date?, newDate: Date) -> Bool {
        deltaDays(from: lastDate, to: newDate) == 1
    }

    /// Calculate number of days between two dates
    private func daysBetween(_ date1: Date, and date2: Date) -> Int? {
        let components = calendar.dateComponents([.day], from: date1, to: date2)
        return components.day
    }
}
