import Foundation

/// Handles all authentication API calls to the backend.
final class AuthService: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Sign In

    /// Signs in with a provider identity token.
    /// The backend validates the token with the provider and returns JWT tokens + user.
    func signIn(
        provider: String,
        identityToken: String,
        name: String? = nil,
        email: String? = nil
    ) async throws -> SignInResponse {
        let request = try APIRequest.post(
            APIEndpoints.Auth.signIn,
            body: SignInRequest(
                provider: provider,
                identityToken: identityToken,
                name: name,
                email: email
            )
        )
        return try await apiClient.send(request)
    }

    // MARK: - Sign Out

    /// Signs out by revoking the refresh token on the backend.
    func signOut(refreshToken: String) async throws {
        let request = try APIRequest.post(
            APIEndpoints.Auth.signOut,
            body: ["refreshToken": refreshToken]
        )
        try await apiClient.sendNoContent(request)
    }

    // MARK: - User Profile

    /// Fetches the current user profile from the backend.
    func fetchUserProfile() async throws -> User {
        let request = APIRequest.get(APIEndpoints.UserProfile.profile)
        return try await apiClient.send(request)
    }
}
