import AuthenticationServices
import Foundation

/// Wraps Apple's `ASAuthorizationController` for Sign in with Apple.
/// Returns the identity token and user info needed to authenticate with the backend.
@MainActor
final class AppleSignInManager: NSObject {
    private var continuation: CheckedContinuation<AppleSignInResult, Error>?

    /// Initiates the Sign in with Apple flow.
    func signIn() async throws -> AppleSignInResult {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInManager: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                continuation?.resume(throwing: AuthError.providerError("Invalid Apple credential type"))
                continuation = nil
                return
            }

            guard let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                continuation?.resume(throwing: AuthError.providerError("Missing Apple identity token"))
                continuation = nil
                return
            }

            let fullName: String? = {
                guard let nameComponents = credential.fullName else { return nil }
                let parts = [nameComponents.givenName, nameComponents.familyName].compactMap { $0 }
                return parts.isEmpty ? nil : parts.joined(separator: " ")
            }()

            let result = AppleSignInResult(
                identityToken: identityToken,
                email: credential.email,
                fullName: fullName,
                userIdentifier: credential.user
            )

            continuation?.resume(returning: result)
            continuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            if let authError = error as? ASAuthorizationError,
               authError.code == .canceled {
                continuation?.resume(throwing: AuthError.userCancelled)
            } else {
                continuation?.resume(throwing: AuthError.providerError(error.localizedDescription))
            }
            continuation = nil
        }
    }
}

// MARK: - Result

struct AppleSignInResult: Sendable {
    let identityToken: String
    let email: String?
    let fullName: String?
    let userIdentifier: String
}
