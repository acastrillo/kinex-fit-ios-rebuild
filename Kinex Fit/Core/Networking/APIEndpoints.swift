import Foundation

/// Centralized API endpoint definitions.
/// All paths are relative to `AppConfig.apiBaseURL`.
enum APIEndpoints {

    // MARK: - Auth

    enum Auth {
        static let signIn = "/api/mobile/auth/signin"
        static let refresh = "/api/mobile/auth/refresh"
        static let signOut = "/api/mobile/auth/signout"
    }

    // MARK: - Workouts

    enum Workouts {
        static let base = "/api/mobile/workouts"

        static func single(_ id: String) -> String {
            "\(base)/\(id)"
        }
    }

    // MARK: - OCR

    enum OCR {
        static let process = "/api/mobile/ocr/process"
    }

    // MARK: - User

    enum UserProfile {
        static let profile = "/api/mobile/user/profile"
    }

    // MARK: - Subscriptions

    enum Subscriptions {
        static let checkoutSession = "/api/mobile/subscriptions/checkout-session"
        static let verify = "/api/mobile/subscriptions/verify"
    }
}

// MARK: - Auth Request/Response Models

struct SignInRequest: Encodable, Sendable {
    let provider: String
    let identityToken: String
    let name: String?
    let email: String?
}

struct SignInResponse: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let user: User
}

struct RefreshRequest: Encodable, Sendable {
    let refreshToken: String
}

// MARK: - OCR Response

struct OCRResponse: Decodable, Sendable {
    let title: String?
    let content: String
}

// MARK: - Subscription Models

struct CheckoutSessionRequest: Encodable, Sendable {
    let tier: String
    let userId: String
}

struct CheckoutSessionResponse: Decodable, Sendable {
    let url: URL
    let sessionId: String
}

struct VerifySubscriptionRequest: Encodable, Sendable {
    let sessionId: String
}
