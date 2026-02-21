import Foundation

/// Manages the app's root navigation state.
/// Determines whether to show auth, onboarding, or the main app.
@Observable
@MainActor
final class RootViewModel {
    // MARK: - State

    enum RootState: Equatable {
        case loading
        case signedOut
        case onboarding
        case signedIn
    }

    var state: RootState = .loading

    // MARK: - Dependencies

    private let environment: AppEnvironment
    private let authService: AuthService

    init(environment: AppEnvironment) {
        self.environment = environment
        self.authService = AuthService(apiClient: environment.apiClient)
    }

    // MARK: - Lifecycle

    /// Called on app launch to determine initial state.
    /// Checks for existing tokens and attempts silent re-authentication.
    func checkAuthState() async {
        state = .loading

        // Check if we have a stored user and valid tokens
        guard let user = environment.currentUser,
              environment.tokenStore.accessToken != nil else {
            state = .signedOut
            return
        }

        // Attempt to refresh user profile from backend (validates token)
        do {
            let freshUser = try await authService.fetchUserProfile()
            try environment.userRepository.save(freshUser)
            environment.currentUser = freshUser

            if !freshUser.onboardingCompleted {
                state = .onboarding
            } else {
                state = .signedIn
            }
        } catch {
            // If token refresh fails (401), the APIClient will clear tokens
            // Check if we're still authenticated after the attempt
            if environment.tokenStore.accessToken != nil {
                // Token still valid, use cached user
                if !user.onboardingCompleted {
                    state = .onboarding
                } else {
                    state = .signedIn
                }
            } else {
                // Tokens were cleared — need to sign in again
                environment.currentUser = nil
                state = .signedOut
            }
        }
    }

    /// Called when AppEnvironment.currentUser changes (e.g., after sign-in).
    func handleUserChange() {
        guard let user = environment.currentUser else {
            state = .signedOut
            return
        }

        if !user.onboardingCompleted {
            state = .onboarding
        } else {
            state = .signedIn
        }
    }

    /// Called when onboarding completes.
    func completeOnboarding() {
        guard var user = environment.currentUser else { return }
        user.onboardingCompleted = true
        try? environment.userRepository.save(user)
        environment.currentUser = user
        state = .signedIn
    }

    /// Signs out the current user.
    func signOut() async {
        // Attempt to revoke refresh token on backend (best-effort)
        if let refreshToken = environment.tokenStore.refreshToken {
            try? await authService.signOut(refreshToken: refreshToken)
        }

        // Clear local state regardless of backend response
        try? environment.handleSignOut()
        state = .signedOut
    }
}
