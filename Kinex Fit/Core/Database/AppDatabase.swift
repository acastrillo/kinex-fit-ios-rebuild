import Foundation
import GRDB

/// Central database manager for the app.
/// Wraps a GRDB `DatabaseWriter` (DatabasePool for production, DatabaseQueue for previews).
final class AppDatabase: Sendable {
    /// The database writer (DatabasePool or DatabaseQueue).
    let writer: any DatabaseWriter

    /// A reader for read-only operations.
    var reader: any DatabaseReader { writer }

    /// Creates a new AppDatabase and runs all migrations.
    private init(writer: any DatabaseWriter) throws {
        self.writer = writer
        var migrator = AppDatabaseMigrations.migrator
        try migrator.migrate(writer)
    }

    // MARK: - Factories

    /// Production database stored in Application Support.
    static func live() throws -> AppDatabase {
        let folderURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dbURL = folderURL.appendingPathComponent("kinexfit.sqlite")
        let pool = try DatabasePool(path: dbURL.path)
        return try AppDatabase(writer: pool)
    }

    /// In-memory database for Xcode previews and unit tests.
    static func inMemory() -> AppDatabase {
        // swiftlint:disable:next force_try
        try! AppDatabase(writer: DatabaseQueue())
    }
}
