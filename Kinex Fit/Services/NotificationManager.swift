import Foundation
import UserNotifications

/// Manages push notification permissions, registration, and local notification scheduling.
@Observable
@MainActor
final class NotificationManager: @unchecked Sendable {
    static let shared = NotificationManager()

    var isAuthorized = false
    var deviceToken: String?

    private init() {
        checkStatus()
    }

    // MARK: - Permission

    /// Requests notification permission from the user.
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { [weak self] granted, error in
            Task { @MainActor in
                self?.isAuthorized = granted
                if granted {
                    self?.registerForRemoteNotifications()
                }
                if let error {
                    print("NotificationManager: Permission error: \(error)")
                }
            }
        }
    }

    /// Checks the current authorization status.
    func checkStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    /// Registers for remote push notifications.
    private func registerForRemoteNotifications() {
        Task { @MainActor in
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    // MARK: - Token Management

    /// Called when the device token is received (from AppDelegate).
    func handleDeviceToken(_ token: String) {
        deviceToken = token
        // TODO: Send token to backend for push notification targeting
    }

    // MARK: - Local Notifications

    /// Schedules a local reminder notification.
    func scheduleWorkoutReminder(at hour: Int = 9, minute: Int = 0) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to Work Out"
        content.body = "Don't forget to log today's workout in Kinex Fit!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "workout-reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("NotificationManager: Failed to schedule reminder: \(error)")
            }
        }
    }

    /// Cancels all pending notification requests.
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Clears the badge count.
    func clearBadge() {
        Task { @MainActor in
            UNUserNotificationCenter.current().setBadgeCount(0)
        }
    }
}
