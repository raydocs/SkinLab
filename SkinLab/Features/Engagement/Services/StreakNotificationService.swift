import Foundation
import UserNotifications

/// Service for scheduling streak at-risk notifications
@MainActor
final class StreakNotificationService {
    // MARK: - Dependencies
    private let streakService: StreakTrackingService

    // MARK: - Notification Identifiers
    private let notificationIdentifierBase = "streak_at_risk_"

    // MARK: - Initialization
    init(streakService: StreakTrackingService) {
        self.streakService = streakService
    }

    // MARK: - Public Methods

    /// Check and schedule streak at-risk notifications
    /// Should be called after each check-in
    func checkAndScheduleNotifications() async {
        let status = streakService.getStreakStatus()
        let currentStreak = status.currentStreak

        // Only schedule for streaks at risk (5+ days)
        guard currentStreak >= 5 else {
            // Cancel existing notifications
            await cancelAllNotifications()
            return
        }

        // Schedule notifications for day 5, 7, 14
        let riskDays = [5, 7, 14]

        for day in riskDays {
            if currentStreak == day {
                await scheduleNotification(for: day)
            } else if currentStreak > day {
                // Cancel notification for past day
                await cancelNotification(for: day)
            }
        }
    }

    /// Schedule a streak at-risk notification
    private func scheduleNotification(for day: Int) async {
        let identifier = notificationIdentifierBase + "\(day)"

        // Request permission
        let granted = await requestNotificationPermission()
        guard granted else { return }

        // Create content
        let content = UNMutableNotificationContent()
        content.title = "保持你的连续打卡！"
        content.body = "你已经连续打卡\(day)天了，别忘了今天打卡哦！"
        content.sound = .default
        content.badge = 1

        // Add action button
        let action = UNNotificationAction(
            identifier: "OPEN_APP",
            title: "打开 SkinLab",
            options: .foreground
        )
        let category = UNNotificationCategory(
            identifier: "STREAK_AT_RISK",
            actions: [action],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "STREAK_AT_RISK"

        // Schedule for 8 PM tomorrow (remind user to check in tomorrow)
        if let trigger = getTriggerForTomorrowAt(hour: 20, minute: 0) {
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    /// Cancel notification for specific day
    private func cancelNotification(for day: Int) async {
        let identifier = notificationIdentifierBase + "\(day)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Cancel all streak notifications
    private func cancelAllNotifications() async {
        let allIdentifiers = (1...30).map { notificationIdentifierBase + "\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: allIdentifiers)
    }

    // MARK: - Helper Methods

    /// Request notification permission
    private func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()

        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .authorized {
            return true
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    /// Get trigger for tomorrow at specific time
    private func getTriggerForTomorrowAt(hour: Int, minute: Int) -> UNCalendarNotificationTrigger? {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()

        var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: tomorrow)
        dateComponents.hour = hour
        dateComponents.minute = minute

        return UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
    }
}
