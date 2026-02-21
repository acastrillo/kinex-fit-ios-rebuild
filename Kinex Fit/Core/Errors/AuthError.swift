import Foundation

enum AuthError: LocalizedError, Sendable {
    case invalidCredentials
    case tokenExpired
    case refreshFailed
    case providerError(String)
    case networkError(Error)
    case userCancelled
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            "Invalid email or password. Please try again."
        case .tokenExpired:
            "Your session has expired. Please sign in again."
        case .refreshFailed:
            "Unable to refresh your session. Please sign in again."
        case .providerError(let message):
            "Sign-in provider error: \(message)"
        case .networkError:
            "Network error. Please check your connection and try again."
        case .userCancelled:
            nil // Don't show an error for user-initiated cancellation
        case .unknown(let message):
            "An unexpected error occurred: \(message)"
        }
    }

    var isUserCancellation: Bool {
        if case .userCancelled = self { return true }
        return false
    }
}

// Make AuthError equatable for testing (ignoring associated error values)
extension AuthError: Equatable {
    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCredentials, .invalidCredentials),
             (.tokenExpired, .tokenExpired),
             (.refreshFailed, .refreshFailed),
             (.userCancelled, .userCancelled):
            true
        case (.providerError(let a), .providerError(let b)):
            a == b
        case (.unknown(let a), .unknown(let b)):
            a == b
        default:
            false
        }
    }
}
