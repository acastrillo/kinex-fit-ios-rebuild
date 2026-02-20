import Foundation

/// Protocol for storing and retrieving JWT authentication tokens.
/// Implementations: `KeychainTokenStore` (production), `InMemoryTokenStore` (previews/tests).
protocol TokenStore: Sendable {
    var accessToken: String? { get }
    var refreshToken: String? { get }
    func save(accessToken: String, refreshToken: String)
    func clearTokens()
}
