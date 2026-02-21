import Foundation
import GRDB

/// Repository for managing the sync queue in the local database.
final class SyncQueueRepository: Sendable {
    private let database: AppDatabase

    init(database: AppDatabase) {
        self.database = database
    }

    // MARK: - CRUD

    /// Saves a sync queue item (insert or update).
    func save(_ item: SyncQueueItem) throws {
        try database.writer.write { db in
            try item.save(db)
        }
    }

    /// Deletes a sync queue item (after successful sync).
    func delete(_ item: SyncQueueItem) throws {
        try database.writer.write { db in
            _ = try item.delete(db)
        }
    }

    /// Deletes a sync queue item by ID.
    func delete(id: String) throws {
        try database.writer.write { db in
            _ = try SyncQueueItem.deleteOne(db, key: id)
        }
    }

    // MARK: - Queries

    /// Fetches all pending items that are ready to be processed.
    /// Items must be under the retry limit and past their next attempt time.
    func fetchPending() throws -> [SyncQueueItem] {
        try database.reader.read { db in
            try SyncQueueItem
                .filter(Column("retryCount") < 5)
                .filter(
                    Column("nextAttemptAt") == nil ||
                    Column("nextAttemptAt") <= Date()
                )
                .order(Column("createdAt").asc)
                .fetchAll(db)
        }
    }

    /// Fetches all items (including failed) for display purposes.
    func fetchAll() throws -> [SyncQueueItem] {
        try database.reader.read { db in
            try SyncQueueItem
                .order(Column("createdAt").asc)
                .fetchAll(db)
        }
    }

    /// Returns the count of pending items.
    func pendingCount() throws -> Int {
        try database.reader.read { db in
            try SyncQueueItem
                .filter(Column("retryCount") < 5)
                .fetchCount(db)
        }
    }

    /// Returns the count of failed items (max retries exceeded).
    func failedCount() throws -> Int {
        try database.reader.read { db in
            try SyncQueueItem
                .filter(Column("retryCount") >= 5)
                .fetchCount(db)
        }
    }

    /// Removes all items from the queue.
    func clearAll() throws {
        try database.writer.write { db in
            _ = try SyncQueueItem.deleteAll(db)
        }
    }

    /// Removes only failed items from the queue.
    func clearFailed() throws {
        try database.writer.write { db in
            _ = try SyncQueueItem
                .filter(Column("retryCount") >= 5)
                .deleteAll(db)
        }
    }

    // MARK: - Observation

    /// Observes the pending item count for sync status display.
    func observePendingCount(
        onChange: @escaping @Sendable (Int) -> Void
    ) -> AnyDatabaseCancellable {
        let observation = ValueObservation.tracking { db in
            try SyncQueueItem
                .filter(Column("retryCount") < 5)
                .fetchCount(db)
        }
        return observation.start(
            in: database.reader,
            scheduling: .immediate,
            onError: { error in
                print("SyncQueueRepository observation error: \(error)")
            },
            onChange: onChange
        )
    }
}
