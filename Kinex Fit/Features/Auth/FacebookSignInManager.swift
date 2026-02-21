import Foundation
import UIKit
// TODO: Uncomment when Facebook SDK SPM package is added
// import FacebookLogin

/// Wraps the Facebook Login SDK for authentication.
/// Returns the access token needed to authenticate with the backend.
///
/// **Setup required:**
/// 1. Add Facebook SDK SPM package: `https://github.com/facebook/facebook-ios-sdk`
/// 2. Add your Facebook App ID to Info.plist (`FacebookAppID`, `FacebookClientToken`, `FacebookDisplayName`)
/// 3. Add the Facebook URL scheme (`fb{APP_ID}`) to Info.plist
/// 4. Uncomment the `import FacebookLogin` and implementation below
@MainActor
final class FacebookSignInManager {

    /// Initiates the Facebook Login flow.
    func signIn() async throws -> FacebookSignInResult {
        // TODO: Uncomment when Facebook SDK SPM package is added
        /*
        let loginManager = LoginManager()

        return try await withCheckedThrowingContinuation { continuation in
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                continuation.resume(throwing: AuthError.providerError("No root view controller available"))
                return
            }

            loginManager.logIn(
                permissions: ["public_profile", "email"],
                from: rootViewController
            ) { result, error in
                if let error {
                    continuation.resume(throwing: AuthError.providerError(error.localizedDescription))
                    return
                }

                guard let result, !result.isCancelled else {
                    continuation.resume(throwing: AuthError.userCancelled)
                    return
                }

                guard let token = result.token?.tokenString else {
                    continuation.resume(throwing: AuthError.providerError("Missing Facebook access token"))
                    return
                }

                continuation.resume(returning: FacebookSignInResult(
                    accessToken: token,
                    email: nil,  // Fetched separately via Graph API if needed
                    fullName: nil
                ))
            }
        }
        */

        // Placeholder until SDK is added
        throw AuthError.providerError("Facebook Login SDK not yet configured. Add the facebook-ios-sdk SPM package and uncomment the implementation.")
    }

    /// Handles the OAuth callback URL from Facebook.
    /// Call this from `AppDelegate.application(_:open:options:)`.
    func handleURL(_ url: URL) -> Bool {
        // TODO: Uncomment when Facebook SDK SPM package is added
        // return ApplicationDelegate.shared.application(
        //     UIApplication.shared,
        //     open: url,
        //     options: [:]
        // )
        return false
    }
}

// MARK: - Result

struct FacebookSignInResult: Sendable {
    let accessToken: String
    let email: String?
    let fullName: String?
}
