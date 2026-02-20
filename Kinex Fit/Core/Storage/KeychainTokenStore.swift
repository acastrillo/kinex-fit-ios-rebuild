import Foundation
import Security

/// Production token storage using the iOS Keychain.
final class KeychainTokenStore: TokenStore, @unchecked Sendable {
    private let accessTokenKey = "com.kinexfit.accessToken"
    private let refreshTokenKey = "com.kinexfit.refreshToken"
    private let lock = NSLock()

    var accessToken: String? {
        read(key: accessTokenKey)
    }

    var refreshToken: String? {
        read(key: refreshTokenKey)
    }

    func save(accessToken: String, refreshToken: String) {
        lock.lock()
        defer { lock.unlock() }
        write(key: accessTokenKey, value: accessToken)
        write(key: refreshTokenKey, value: refreshToken)
    }

    func clearTokens() {
        lock.lock()
        defer { lock.unlock() }
        delete(key: accessTokenKey)
        delete(key: refreshTokenKey)
    }

    // MARK: - Private Keychain Helpers

    private func write(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Delete existing item first
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    private func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
