import Foundation
import GRDB

/// Repository for managing body metrics in the local database.
final class BodyMetricRepository: Sendable {
    private let database: AppDatabase

    init(database: AppDatabase) {
        self.database = database
    }

    // MARK: - CRUD

    /// Fetches all body metrics, sorted by most recent date.
    func fetchAll() throws -> [BodyMetric] {
        try database.reader.read { db in
            try BodyMetric
                .order(Column("date").desc)
                .fetchAll(db)
        }
    }

    /// Fetches a single body metric by ID.
    func fetch(id: String) throws -> BodyMetric? {
        try database.reader.read { db in
            try BodyMetric.fetchOne(db, key: id)
        }
    }

    /// Saves a new body metric or updates an existing one.
    func save(_ metric: BodyMetric) throws {
        try database.writer.write { db in
            try metric.save(db)
        }
    }

    /// Deletes a body metric by ID.
    func delete(id: String) throws {
        try database.writer.write { db in
            _ = try BodyMetric.deleteOne(db, key: id)
        }
    }

    // MARK: - Queries

    /// Fetches the most recent body metric entry.
    func fetchLatest() throws -> BodyMetric? {
        try database.reader.read { db in
            try BodyMetric
                .order(Column("date").desc)
                .fetchOne(db)
        }
    }

    /// Fetches body metrics within a date range (for charts).
    func fetch(from startDate: Date, to endDate: Date) throws -> [BodyMetric] {
        try database.reader.read { db in
            try BodyMetric
                .filter(Column("date") >= startDate && Column("date") <= endDate)
                .order(Column("date").asc)
                .fetchAll(db)
        }
    }

    // MARK: - Observation

    /// Observes all body metrics for real-time UI updates.
    func observeAll(
        onChange: @escaping @Sendable ([BodyMetric]) -> Void
    ) -> AnyDatabaseCancellable {
        let observation = ValueObservation.tracking { db in
            try BodyMetric
                .order(Column("date").desc)
                .fetchAll(db)
        }
        return observation.start(
            in: database.reader,
            scheduling: .immediate,
            onError: { error in
                print("BodyMetricRepository observation error: \(error)")
            },
            onChange: onChange
        )
    }
}
