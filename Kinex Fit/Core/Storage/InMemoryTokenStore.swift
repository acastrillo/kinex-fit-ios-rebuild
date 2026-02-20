import Foundation

/// In-memory token store for Xcode previews and unit tests.
final class InMemoryTokenStore: TokenStore, @unchecked Sendable {
    private let lock = NSLock()
    private var _accessToken: String?
    private var _refreshToken: String?

    var accessToken: String? {
        lock.lock()
        defer { lock.unlock() }
        return _accessToken
    }

    var refreshToken: String? {
        lock.lock()
        defer { lock.unlock() }
        return _refreshToken
    }

    func save(accessToken: String, refreshToken: String) {
        lock.lock()
        defer { lock.unlock() }
        _accessToken = accessToken
        _refreshToken = refreshToken
    }

    func clearTokens() {
        lock.lock()
        defer { lock.unlock() }
        _accessToken = nil
        _refreshToken = nil
    }

    /// Convenience initializer for previews with pre-set tokens.
    convenience init(accessToken: String? = nil, refreshToken: String? = nil) {
        self.init()
        if let accessToken, let refreshToken {
            save(accessToken: accessToken, refreshToken: refreshToken)
        }
    }
}
