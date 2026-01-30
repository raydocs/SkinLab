import Foundation
import UserNotifications

/// Service for scheduling predictive skincare alert notifications
/// Only high severity alerts trigger push notifications; others are in-app only
@MainActor
final class PredictiveAlertNotificationService {
    // MARK: - Notification Identifiers

    private let notificationIdentifierPrefix = "predictive_alert_"
    private let categoryIdentifier = "PREDICTIVE_ALERT"

    // MARK: - Initialization

    init() {
        setupNotificationCategory()
    }

    // MARK: - Public Methods

    /// Schedule a notification for a predictive alert
    /// Only schedules push notifications for high severity alerts
    /// - Parameter alert: The predictive alert to schedule
    func scheduleAlertNotification(alert: PredictiveAlert) async {
        // Only push notifications for high severity alerts
        guard alert.severity == .high else {
            return
        }

        // Request permission
        let granted = await requestNotificationPermission()
        guard granted else { return }

        let identifier = notificationIdentifierPrefix + alert.id.uuidString

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "[\(alert.severity.rawValue)] \(alert.metric)预警"
        content.body = "\(alert.message)\n\(alert.actionSuggestion)"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = categoryIdentifier

        // Add user info for handling
        content.userInfo = [
            "alertId": alert.id.uuidString,
            "metric": alert.metric,
            "severity": alert.severity.rawValue
        ]

        // Schedule for morning of predicted date (8 AM)
        if let trigger = getTriggerForDate(alert.predictedDate, hour: 8, minute: 0) {
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            do {
                try await UNUserNotificationCenter.current().add(request)
                AppLogger.info("Scheduled predictive alert notification: \(alert.title)")
            } catch {
                AppLogger.error("Failed to schedule predictive alert notification", error: error)
            }
        }
    }

    /// Cancel all pending predictive alert notifications
    func cancelAllPredictiveAlerts() {
        let center = UNUserNotificationCenter.current()

        // Get all pending notifications and remove those with our prefix
        center.getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }

            let predictiveAlertIds = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(self.notificationIdentifierPrefix) }

            if !predictiveAlertIds.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: predictiveAlertIds)
            }
        }
    }

    /// Cancel a specific alert notification
    /// - Parameter alertId: The UUID of the alert to cancel
    func cancelAlertNotification(alertId: UUID) {
        let identifier = notificationIdentifierPrefix + alertId.uuidString
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Private Methods

    /// Setup notification category with action buttons
    private func setupNotificationCategory() {
        let openAction = UNNotificationAction(
            identifier: "OPEN_APP",
            title: "查看详情",
            options: .foreground
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "稍后提醒",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [openAction, dismissAction],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    /// Request notification permission
    /// - Returns: Whether permission was granted
    private func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()

        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .authorized {
            return true
        }

        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Get trigger for a specific date and time
    /// - Parameters:
    ///   - date: The target date
    ///   - hour: Hour of the day (0-23)
    ///   - minute: Minute of the hour (0-59)
    /// - Returns: Calendar notification trigger, or nil if date is in the past
    private func getTriggerForDate(_ date: Date, hour: Int, minute: Int) -> UNCalendarNotificationTrigger? {
        let calendar = Calendar.current

        // Create target date with specified time
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = hour
        dateComponents.minute = minute

        guard let targetDate = calendar.date(from: dateComponents) else {
            return nil
        }

        // If target date is in the past, don't schedule
        if targetDate <= Date() {
            return nil
        }

        return UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
    }
}
