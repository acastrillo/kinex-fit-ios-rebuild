import Foundation

enum OCRError: LocalizedError, Equatable, Sendable {
    case quotaExceeded
    case imageProcessingFailed
    case noTextDetected
    case uploadFailed(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .quotaExceeded:
            "You've reached your scan limit for this month. Upgrade your plan for more scans."
        case .imageProcessingFailed:
            "Failed to process the image. Please try a clearer photo."
        case .noTextDetected:
            "No text was detected in the image. Please try a different photo."
        case .uploadFailed(let message):
            "Failed to upload image: \(message)"
        case .networkError(let message):
            "Network error: \(message)"
        }
    }
}
