import Foundation

/// Manages the paywall and subscription upgrade flow.
@Observable
@MainActor
final class PaywallViewModel {
    // MARK: - State

    var isLoading = false
    var error: String?
    var checkoutURL: URL?
    var showCheckout = false
    var didUpgrade = false

    // MARK: - Dependencies

    private let apiClient: APIClient
    private let environment: AppEnvironment

    init(apiClient: APIClient, environment: AppEnvironment) {
        self.apiClient = apiClient
        self.environment = environment
    }

    // MARK: - Computed

    var currentTier: SubscriptionTier {
        environment.currentUser?.subscriptionTier ?? .free
    }

    var availableUpgrades: [SubscriptionTier] {
        SubscriptionTier.allCases.filter { $0 != .free && $0 != currentTier }
    }

    // MARK: - Actions

    /// Starts the Stripe checkout flow for the selected tier.
    func startCheckout(for tier: SubscriptionTier) async {
        guard let userId = environment.currentUser?.id else {
            error = "Please sign in first."
            return
        }

        isLoading = true
        error = nil

        do {
            let request = CheckoutSessionRequest(tier: tier.rawValue, userId: userId)
            let response: CheckoutSessionResponse = try await apiClient.send(
                .post(APIEndpoints.Subscriptions.checkoutSession, body: request)
            )
            checkoutURL = response.url
            showCheckout = true
        } catch {
            self.error = "Failed to start checkout: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Verifies the subscription after Stripe checkout completes.
    func verifySubscription(sessionId: String) async {
        isLoading = true

        do {
            let request = VerifySubscriptionRequest(sessionId: sessionId)
            let user: User = try await apiClient.send(
                .post(APIEndpoints.Subscriptions.verify, body: request)
            )
            try environment.userRepository.save(user)
            environment.currentUser = user
            didUpgrade = true
        } catch {
            self.error = "Failed to verify subscription: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Refreshes the user profile to check for subscription changes (fallback).
    func refreshUserProfile() async {
        do {
            let authService = AuthService(apiClient: apiClient)
            let user = try await authService.fetchUserProfile()
            try environment.userRepository.save(user)
            environment.currentUser = user
            if user.subscriptionTier != .free {
                didUpgrade = true
            }
        } catch {
            // Silently fail — this is a fallback check
        }
    }
}
