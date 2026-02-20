import Foundation
import GRDB

/// Repository for managing workouts in the local database.
final class WorkoutRepository: Sendable {
    private let database: AppDatabase

    init(database: AppDatabase) {
        self.database = database
    }

    // MARK: - CRUD

    /// Fetches all workouts, sorted by most recently updated.
    func fetchAll() throws -> [Workout] {
        try database.reader.read { db in
            try Workout
                .order(Column("updatedAt").desc)
                .fetchAll(db)
        }
    }

    /// Fetches a single workout by ID.
    func fetch(id: String) throws -> Workout? {
        try database.reader.read { db in
            try Workout.fetchOne(db, key: id)
        }
    }

    /// Searches workouts by title or content.
    func search(query: String) throws -> [Workout] {
        let pattern = "%\(query)%"
        return try database.reader.read { db in
            try Workout
                .filter(
                    Column("title").like(pattern) ||
                    Column("content").like(pattern)
                )
                .order(Column("updatedAt").desc)
                .fetchAll(db)
        }
    }

    /// Saves a new workout or updates an existing one.
    func save(_ workout: Workout) throws {
        try database.writer.write { db in
            try workout.save(db)
        }
    }

    /// Deletes a workout by ID.
    func delete(id: String) throws {
        try database.writer.write { db in
            _ = try Workout.deleteOne(db, key: id)
        }
    }

    /// Replaces all local workouts with server data (for full sync).
    func replaceAll(with workouts: [Workout]) throws {
        try database.writer.write { db in
            try Workout.deleteAll(db)
            for workout in workouts {
                try workout.insert(db)
            }
        }
    }

    // MARK: - Observation

    /// Observes all workouts for real-time UI updates.
    func observeAll(
        onChange: @escaping @Sendable ([Workout]) -> Void
    ) -> AnyDatabaseCancellable {
        let observation = ValueObservation.tracking { db in
            try Workout
                .order(Column("updatedAt").desc)
                .fetchAll(db)
        }
        return observation.start(
            in: database.reader,
            scheduling: .immediate,
            onError: { error in
                print("WorkoutRepository observation error: \(error)")
            },
            onChange: onChange
        )
    }

    /// Observes workouts filtered by search query.
    func observeSearch(
        query: String,
        onChange: @escaping @Sendable ([Workout]) -> Void
    ) -> AnyDatabaseCancellable {
        let pattern = "%\(query)%"
        let observation = ValueObservation.tracking { db in
            try Workout
                .filter(
                    Column("title").like(pattern) ||
                    Column("content").like(pattern)
                )
                .order(Column("updatedAt").desc)
                .fetchAll(db)
        }
        return observation.start(
            in: database.reader,
            scheduling: .immediate,
            onError: { error in
                print("WorkoutRepository search observation error: \(error)")
            },
            onChange: onChange
        )
    }
}
