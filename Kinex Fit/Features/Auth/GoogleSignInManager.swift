import Foundation
import UIKit
// TODO: Uncomment when GoogleSignIn SPM package is added
// import GoogleSignIn

/// Wraps the Google Sign-In SDK for authentication.
/// Returns the identity token needed to authenticate with the backend.
///
/// **Setup required:**
/// 1. Add GoogleSignIn SPM package: `https://github.com/google/GoogleSignIn-iOS`
/// 2. Add your Google OAuth Client ID to Info.plist under `GIDClientID`
/// 3. Add the reversed client ID as a URL scheme in Info.plist
/// 4. Uncomment the `import GoogleSignIn` and implementation below
@MainActor
final class GoogleSignInManager {

    /// Initiates the Google Sign-In flow.
    func signIn() async throws -> GoogleSignInResult {
        // TODO: Uncomment when GoogleSignIn SPM package is added
        /*
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AuthError.providerError("No root view controller available")
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.providerError("Missing Google ID token")
        }

        return GoogleSignInResult(
            identityToken: idToken,
            email: result.user.profile?.email,
            fullName: result.user.profile?.name
        )
        */

        // Placeholder until SDK is added
        throw AuthError.providerError("Google Sign-In SDK not yet configured. Add the GoogleSignIn SPM package and uncomment the implementation.")
    }

    /// Handles the OAuth callback URL from Google.
    /// Call this from `AppDelegate.application(_:open:options:)`.
    func handleURL(_ url: URL) -> Bool {
        // TODO: Uncomment when GoogleSignIn SPM package is added
        // return GIDSignIn.sharedInstance.handle(url)
        return false
    }
}

// MARK: - Result

struct GoogleSignInResult: Sendable {
    let identityToken: String
    let email: String?
    let fullName: String?
}
