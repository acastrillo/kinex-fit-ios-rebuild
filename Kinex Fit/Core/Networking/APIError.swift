import Foundation

enum APIError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    case encodingError(Error)
    case unauthorized
    case networkError(Error)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid URL."
        case .invalidResponse:
            "Invalid server response."
        case .httpError(let statusCode, _):
            "Server error (HTTP \(statusCode))."
        case .decodingError:
            "Failed to parse server response."
        case .encodingError:
            "Failed to prepare request data."
        case .unauthorized:
            "Authentication required. Please sign in again."
        case .networkError:
            "Network error. Please check your connection."
        case .unknown(let message):
            message
        }
    }

    /// Attempts to decode a server error message from the response data.
    var serverMessage: String? {
        guard case .httpError(_, let data) = self else { return nil }
        struct ServerError: Decodable {
            let message: String?
            let error: String?
        }
        let decoded = try? JSONDecoder().decode(ServerError.self, from: data)
        return decoded?.message ?? decoded?.error
    }

    var isUnauthorized: Bool {
        switch self {
        case .unauthorized: true
        case .httpError(let statusCode, _): statusCode == 401
        default: false
        }
    }

    var isNetworkError: Bool {
        if case .networkError = self { return true }
        return false
    }
}

// Equatable conformance (ignoring associated Error values)
extension APIError: Equatable {
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidResponse, .invalidResponse),
             (.unauthorized, .unauthorized):
            true
        case (.httpError(let a, _), .httpError(let b, _)):
            a == b
        case (.unknown(let a), .unknown(let b)):
            a == b
        default:
            false
        }
    }
}
