import Foundation

/// Manages the profile screen state including user info, settings, and sign out.
@Observable
@MainActor
final class ProfileViewModel {
    // MARK: - State

    var showPaywall = false
    var showSignOutConfirmation = false
    var isSigningOut = false
    var error: String?

    // MARK: - Dependencies

    private let environment: AppEnvironment
    private let authService: AuthService

    init(environment: AppEnvironment) {
        self.environment = environment
        self.authService = AuthService(apiClient: environment.apiClient)
    }

    // MARK: - Computed

    var user: User? { environment.currentUser }

    var userName: String { user?.name ?? "User" }
    var userEmail: String { user?.email ?? "" }
    var tierName: String { user?.subscriptionTier.displayName ?? "Free" }
    var provider: String { user?.provider.capitalized ?? "" }

    var scanUsageText: String {
        guard let user else { return "" }
        if user.subscriptionTier.isUnlimited { return "Unlimited" }
        return "\(user.scanQuotaUsed) / \(user.subscriptionTier.scanQuotaLimit)"
    }

    var aiUsageText: String {
        guard let user else { return "" }
        if user.subscriptionTier.isUnlimited { return "Unlimited" }
        return "\(user.aiQuotaUsed) / \(user.subscriptionTier.aiQuotaLimit)"
    }

    var isFreeUser: Bool {
        user?.subscriptionTier == .free
    }

    // MARK: - Actions

    func signOut() async {
        isSigningOut = true

        // Attempt to revoke refresh token on backend (best-effort)
        if let refreshToken = environment.tokenStore.refreshToken {
            try? await authService.signOut(refreshToken: refreshToken)
        }

        // Clear local state
        try? environment.handleSignOut()
        isSigningOut = false
    }

    func refreshProfile() async {
        do {
            let user = try await authService.fetchUserProfile()
            try environment.userRepository.save(user)
            environment.currentUser = user
        } catch {
            self.error = "Failed to refresh profile: \(error.localizedDescription)"
        }
    }
}
