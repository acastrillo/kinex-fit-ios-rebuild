import Foundation

enum SubscriptionTier: String, Codable, CaseIterable, Sendable {
    case free
    case core
    case pro
    case elite

    var displayName: String {
        switch self {
        case .free: "Free"
        case .core: "Core"
        case .pro: "Pro"
        case .elite: "Elite"
        }
    }

    var scanQuotaLimit: Int {
        switch self {
        case .free: 8
        case .core: 12
        case .pro: 60
        case .elite: .max
        }
    }

    var aiQuotaLimit: Int {
        switch self {
        case .free: 5
        case .core: 20
        case .pro: 100
        case .elite: .max
        }
    }

    var isUnlimited: Bool {
        self == .elite
    }
}
