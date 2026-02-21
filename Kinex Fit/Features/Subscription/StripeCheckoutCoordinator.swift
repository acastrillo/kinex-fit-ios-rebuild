import SwiftUI
import SafariServices

/// Presents a Stripe checkout session in SFSafariViewController.
///
/// Flow:
/// 1. Opens the Stripe-hosted checkout URL
/// 2. User completes payment in Stripe
/// 3. Stripe redirects to `kinexfit://subscription/success?session_id=xyz`
/// 4. Deep link handler catches the redirect and calls `onComplete`
struct StripeCheckoutCoordinator: UIViewControllerRepresentable {
    let url: URL
    let onComplete: (String) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safari = SFSafariViewController(url: url)
        safari.delegate = context.coordinator
        safari.preferredControlScheme = .automatic
        safari.dismissButtonStyle = .cancel
        return safari
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete, onCancel: onCancel)
    }

    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let onComplete: (String) -> Void
        let onCancel: () -> Void
        private var deepLinkObserver: NSObjectProtocol?

        init(onComplete: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
            self.onComplete = onComplete
            self.onCancel = onCancel
            super.init()

            // Listen for deep link callback from Stripe redirect
            deepLinkObserver = NotificationCenter.default.addObserver(
                forName: .didReceiveDeepLink,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let url = notification.userInfo?["url"] as? URL else { return }
                self?.handleDeepLink(url)
            }
        }

        deinit {
            if let observer = deepLinkObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        private func handleDeepLink(_ url: URL) {
            // Expected: kinexfit://subscription/success?session_id=xyz
            guard url.host == "subscription",
                  url.path.contains("success"),
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let sessionId = components.queryItems?.first(where: { $0.name == "session_id" })?.value else {
                return
            }
            onComplete(sessionId)
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            onCancel()
        }
    }
}
