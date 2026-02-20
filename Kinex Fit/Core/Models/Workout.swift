import Foundation
import GRDB

struct Workout: Identifiable, Codable, Equatable, Hashable, Sendable {
    var id: String
    var title: String
    var content: String?
    var source: WorkoutSource
    var createdAt: Date
    var updatedAt: Date
}

// MARK: - GRDB Conformance

extension Workout: FetchableRecord, PersistableRecord {
    static let databaseTableName = "workouts"
}

// MARK: - Factory

extension Workout {
    static func new(
        title: String,
        content: String? = nil,
        source: WorkoutSource = .manual
    ) -> Workout {
        let now = Date()
        return Workout(
            id: UUID().uuidString,
            title: title,
            content: content,
            source: source,
            createdAt: now,
            updatedAt: now
        )
    }
}
