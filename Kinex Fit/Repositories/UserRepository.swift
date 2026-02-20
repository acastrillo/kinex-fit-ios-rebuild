import Foundation
import GRDB

/// Repository for managing the authenticated user in the local database.
final class UserRepository: Sendable {
    private let database: AppDatabase

    init(database: AppDatabase) {
        self.database = database
    }

    // MARK: - CRUD

    /// Fetches the current user (there should be at most one).
    func getCurrentUser() throws -> User? {
        try database.reader.read { db in
            try User.fetchOne(db)
        }
    }

    /// Saves or updates the user record.
    func save(_ user: User) throws {
        try database.writer.write { db in
            try user.save(db)
        }
    }

    /// Deletes the user record (used on sign-out).
    func deleteCurrentUser() throws {
        try database.writer.write { db in
            _ = try User.deleteAll(db)
        }
    }

    /// Updates specific user fields.
    func update(_ user: User) throws {
        try database.writer.write { db in
            try user.update(db)
        }
    }

    // MARK: - Observation

    /// Observes the current user for real-time UI updates.
    /// Returns a cancellable that stops observation when deallocated.
    func observeCurrentUser(
        onChange: @escaping @Sendable (User?) -> Void
    ) -> AnyDatabaseCancellable {
        let observation = ValueObservation.tracking { db in
            try User.fetchOne(db)
        }
        return observation.start(
            in: database.reader,
            scheduling: .immediate,
            onError: { error in
                print("UserRepository observation error: \(error)")
            },
            onChange: onChange
        )
    }
}
