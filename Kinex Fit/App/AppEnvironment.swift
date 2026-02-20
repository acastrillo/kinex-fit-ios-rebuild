import Foundation
import SwiftUI
import GRDB

/// Central dependency injection container for the app.
/// Holds all shared services, repositories, and state.
/// Injected into SwiftUI's environment at the root and accessed via `@Environment(\.appEnvironment)`.
@Observable
final class AppEnvironment {
    // MARK: - Infrastructure

    let database: AppDatabase
    let apiClient: APIClient
    let tokenStore: TokenStore

    // MARK: - Repositories

    let userRepository: UserRepository
    let workoutRepository: WorkoutRepository
    let bodyMetricRepository: BodyMetricRepository
    let syncQueueRepository: SyncQueueRepository

    // MARK: - Shared State

    /// The currently authenticated user. Nil when signed out.
    var currentUser: User?

    /// Whether the user is authenticated.
    var isAuthenticated: Bool { currentUser != nil }

    // MARK: - Initialization

    init(database: AppDatabase, tokenStore: TokenStore) {
        self.database = database
        self.tokenStore = tokenStore
        self.apiClient = APIClient(
            tokenStore: tokenStore,
            baseURL: AppConfig.apiBaseURL
        )
        self.userRepository = UserRepository(database: database)
        self.workoutRepository = WorkoutRepository(database: database)
        self.bodyMetricRepository = BodyMetricRepository(database: database)
        self.syncQueueRepository = SyncQueueRepository(database: database)

        // Load persisted user on init
        self.currentUser = try? userRepository.getCurrentUser()
    }

    // MARK: - Factories

    /// Production environment with file-based database and Keychain storage.
    static func live() throws -> AppEnvironment {
        let database = try AppDatabase.live()
        let tokenStore = KeychainTokenStore()
        return AppEnvironment(database: database, tokenStore: tokenStore)
    }

    /// Preview/testing environment with in-memory database.
    static func preview() -> AppEnvironment {
        let database = DatabasePreview.populated()
        let tokenStore = InMemoryTokenStore(
            accessToken: "preview-token",
            refreshToken: "preview-refresh"
        )
        let env = AppEnvironment(database: database, tokenStore: tokenStore)
        #if DEBUG
        env.currentUser = User.devModeUser
        #endif
        return env
    }

    // MARK: - Auth State Management

    /// Called after successful sign-in to persist user and tokens.
    func handleSignIn(user: User, accessToken: String, refreshToken: String) throws {
        tokenStore.save(accessToken: accessToken, refreshToken: refreshToken)
        try userRepository.save(user)
        currentUser = user
    }

    /// Called on sign-out to clear all local state.
    func handleSignOut() throws {
        tokenStore.clearTokens()
        try userRepository.deleteCurrentUser()
        currentUser = nil
    }

    /// Refreshes the current user from the local database.
    func refreshCurrentUser() {
        currentUser = try? userRepository.getCurrentUser()
    }
}

// MARK: - SwiftUI Environment Key

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppEnvironment = .preview()
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
