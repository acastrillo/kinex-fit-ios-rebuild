import Foundation
import AuthenticationServices

/// Manages authentication state and handles all sign-in provider flows.
@Observable
@MainActor
final class AuthViewModel {
    // MARK: - State

    var isLoading = false
    var error: AuthError?
    var showEmailSignIn = false

    // Email/password form fields
    var emailText = ""
    var passwordText = ""

    // MARK: - Dependencies

    private let authService: AuthService
    private let environment: AppEnvironment
    private let appleSignInManager = AppleSignInManager()
    private let googleSignInManager = GoogleSignInManager()
    private let facebookSignInManager = FacebookSignInManager()

    init(authService: AuthService, environment: AppEnvironment) {
        self.authService = authService
        self.environment = environment
    }

    // MARK: - Sign In Methods

    /// Sign in with Apple.
    func signInWithApple() async {
        await performSignIn {
            let result = try await self.appleSignInManager.signIn()
            return try await self.authService.signIn(
                provider: "apple",
                identityToken: result.identityToken,
                name: result.fullName,
                email: result.email
            )
        }
    }

    /// Sign in with Google.
    func signInWithGoogle() async {
        await performSignIn {
            let result = try await self.googleSignInManager.signIn()
            return try await self.authService.signIn(
                provider: "google",
                identityToken: result.identityToken,
                name: result.fullName,
                email: result.email
            )
        }
    }

    /// Sign in with Facebook.
    func signInWithFacebook() async {
        await performSignIn {
            let result = try await self.facebookSignInManager.signIn()
            return try await self.authService.signIn(
                provider: "facebook",
                identityToken: result.accessToken,
                name: result.fullName,
                email: result.email
            )
        }
    }

    /// Sign in with email and password.
    func signInWithEmail() async {
        let email = emailText.trimmed
        let password = passwordText

        guard !email.isEmpty, !password.isEmpty else {
            error = .invalidCredentials
            return
        }

        await performSignIn {
            // For email/password, we send both as the "identity token"
            // The backend distinguishes by provider type
            return try await self.authService.signIn(
                provider: "email",
                identityToken: password,
                name: nil,
                email: email
            )
        }
    }

    /// Dev mode bypass — DEBUG only.
    #if DEBUG
    func signInDevMode() async {
        isLoading = true
        error = nil

        do {
            try environment.handleSignIn(
                user: .devModeUser,
                accessToken: "dev-access-token",
                refreshToken: "dev-refresh-token"
            )
        } catch {
            self.error = .unknown(error.localizedDescription)
        }

        isLoading = false
    }
    #endif

    // MARK: - OAuth URL Handling

    /// Forwards OAuth callback URLs to the appropriate sign-in manager.
    /// Called from AppDelegate when a deep link is received.
    func handleOAuthURL(_ url: URL) -> Bool {
        if googleSignInManager.handleURL(url) { return true }
        if facebookSignInManager.handleURL(url) { return true }
        return false
    }

    // MARK: - Private

    private func performSignIn(
        _ signInAction: @escaping () async throws -> SignInResponse
    ) async {
        isLoading = true
        error = nil

        do {
            let response = try await signInAction()
            try environment.handleSignIn(
                user: response.user,
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
        } catch let authError as AuthError {
            // Don't show error for user cancellations
            if !authError.isUserCancellation {
                self.error = authError
            }
        } catch let apiError as APIError {
            if apiError.isUnauthorized {
                self.error = .invalidCredentials
            } else {
                self.error = .networkError(apiError)
            }
        } catch {
            self.error = .unknown(error.localizedDescription)
        }

        isLoading = false
    }
}
