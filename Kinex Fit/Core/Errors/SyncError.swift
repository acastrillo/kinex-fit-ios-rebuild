import Foundation

enum SyncError: LocalizedError, Equatable, Sendable {
    case networkUnavailable
    case serverError(statusCode: Int)
    case encodingFailed
    case maxRetriesExceeded
    case conflict(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            "No internet connection. Changes will sync when you're back online."
        case .serverError(let statusCode):
            "Server error (code \(statusCode)). Will retry automatically."
        case .encodingFailed:
            "Failed to prepare data for sync."
        case .maxRetriesExceeded:
            "Sync failed after multiple attempts. Please try again manually."
        case .conflict(let message):
            "Sync conflict: \(message)"
        case .unknown(let message):
            "Sync error: \(message)"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .serverError:
            true
        case .encodingFailed, .maxRetriesExceeded, .conflict, .unknown:
            false
        }
    }
}
