import Foundation

/// Parses and routes deep links received by the app.
///
/// URL scheme: `kinexfit://`
/// Supported routes:
/// - `kinexfit://subscription/success?session_id=xyz` — Stripe checkout completed
/// - `kinexfit://oauth/callback?provider=google&code=abc` — OAuth callback
@Observable
@MainActor
final class DeepLinkHandler {
    // MARK: - State

    enum PendingAction: Equatable {
        case subscriptionVerification(sessionId: String)
        case oauthCallback(provider: String, code: String)
    }

    var pendingAction: PendingAction?

    // MARK: - Routing

    /// Parses a deep link URL and sets the pending action.
    func handle(_ url: URL) {
        guard url.scheme == AppConfig.urlScheme else { return }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let host = url.host ?? ""
        let path = url.path

        switch host {
        case "subscription":
            if path.contains("success"),
               let sessionId = components?.queryItems?.first(where: { $0.name == "session_id" })?.value {
                pendingAction = .subscriptionVerification(sessionId: sessionId)
            }

        case "oauth":
            if path.contains("callback"),
               let provider = components?.queryItems?.first(where: { $0.name == "provider" })?.value,
               let code = components?.queryItems?.first(where: { $0.name == "code" })?.value {
                pendingAction = .oauthCallback(provider: provider, code: code)
            }

        default:
            break
        }
    }

    /// Clears the pending action after it's been handled.
    func clearPendingAction() {
        pendingAction = nil
    }
}
