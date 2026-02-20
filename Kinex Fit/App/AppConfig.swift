import Foundation

/// Environment-specific app configuration.
enum AppConfig {
    /// Base URL for the backend API.
    static let apiBaseURL: URL = {
        #if DEBUG
        // In debug, check for environment variable override (useful for local development)
        if let override = ProcessInfo.processInfo.environment["API_BASE_URL"],
           let url = URL(string: override) {
            return url
        }
        #endif
        // Production API
        return URL(string: "https://kinexfit.com")!
    }()

    /// App Group identifier shared between main app and share extension.
    static let appGroupIdentifier = "group.com.kinexfit.shared"

    /// URL scheme for deep links (OAuth callbacks, Stripe redirects).
    static let urlScheme = "kinexfit"

    /// Bundle identifier.
    static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.kinexfit.app"

    /// App version string.
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// Build number string.
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// Full version display string.
    static var versionDisplay: String {
        "v\(appVersion) (\(buildNumber))"
    }
}
