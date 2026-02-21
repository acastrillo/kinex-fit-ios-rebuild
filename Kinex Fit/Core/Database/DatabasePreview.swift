import Foundation
import GRDB

/// Helpers for creating pre-populated in-memory databases for Xcode Previews.
enum DatabasePreview {
    /// Creates an in-memory database pre-loaded with sample data.
    static func populated() -> AppDatabase {
        let db = AppDatabase.inMemory()

        do {
            try db.writer.write { database in
                // Sample user
                try User.devModeUser.insert(database)

                // Sample workouts
                for workout in MockData.workouts {
                    try workout.insert(database)
                }

                // Sample body metrics
                for metric in MockData.bodyMetrics {
                    try metric.insert(database)
                }
            }
        } catch {
            print("DatabasePreview: Failed to populate sample data: \(error)")
        }

        return db
    }
}
