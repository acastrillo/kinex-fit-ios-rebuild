import Foundation
import GRDB

struct User: Identifiable, Codable, Equatable, Hashable, Sendable {
    var id: String
    var name: String
    var email: String
    var provider: String
    var subscriptionTier: SubscriptionTier
    var scanQuotaUsed: Int
    var aiQuotaUsed: Int
    var onboardingCompleted: Bool

    var canScan: Bool {
        subscriptionTier.isUnlimited || scanQuotaUsed < subscriptionTier.scanQuotaLimit
    }

    var canUseAI: Bool {
        subscriptionTier.isUnlimited || aiQuotaUsed < subscriptionTier.aiQuotaLimit
    }

    var remainingScans: Int {
        guard !subscriptionTier.isUnlimited else { return .max }
        return max(0, subscriptionTier.scanQuotaLimit - scanQuotaUsed)
    }

    var remainingAIOperations: Int {
        guard !subscriptionTier.isUnlimited else { return .max }
        return max(0, subscriptionTier.aiQuotaLimit - aiQuotaUsed)
    }
}

// MARK: - GRDB Conformance

extension User: FetchableRecord, PersistableRecord {
    static let databaseTableName = "users"
}

// MARK: - Defaults

extension User {
    static func new(
        id: String = UUID().uuidString,
        name: String,
        email: String,
        provider: String
    ) -> User {
        User(
            id: id,
            name: name,
            email: email,
            provider: provider,
            subscriptionTier: .free,
            scanQuotaUsed: 0,
            aiQuotaUsed: 0,
            onboardingCompleted: false
        )
    }

    #if DEBUG
    static let devModeUser = User(
        id: "dev-user-001",
        name: "Dev User",
        email: "dev@kinexfit.com",
        provider: "dev",
        subscriptionTier: .elite,
        scanQuotaUsed: 0,
        aiQuotaUsed: 0,
        onboardingCompleted: true
    )
    #endif
}
