import UIKit

/// UIKit App Delegate for handling system-level callbacks that SwiftUI doesn't support directly:
/// - OAuth deep link callbacks
/// - Push notification registration
/// - Background fetch
class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - App Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        return true
    }

    // MARK: - Deep Links / URL Handling

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        handleDeepLink(url)
    }

    private func handleDeepLink(_ url: URL) -> Bool {
        guard url.scheme == AppConfig.urlScheme else { return false }

        // Post notification so any interested view model can handle it
        NotificationCenter.default.post(
            name: .didReceiveDeepLink,
            object: nil,
            userInfo: ["url": url]
        )

        return true
    }

    // MARK: - Push Notifications

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("AppDelegate: Push notification token: \(token)")

        // Post notification so NotificationManager can handle registration
        NotificationCenter.default.post(
            name: .didRegisterPushToken,
            object: nil,
            userInfo: ["token": token]
        )
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("AppDelegate: Failed to register for push notifications: \(error)")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when the app receives a deep link URL.
    static let didReceiveDeepLink = Notification.Name("didReceiveDeepLink")

    /// Posted when push notification device token is received.
    static let didRegisterPushToken = Notification.Name("didRegisterPushToken")
}
