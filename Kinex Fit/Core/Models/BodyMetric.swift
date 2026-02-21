import Foundation
import GRDB

struct BodyMetric: Identifiable, Codable, Equatable, Hashable, Sendable {
    var id: String
    var weight: Double
    var date: Date
    var notes: String?
}

// MARK: - GRDB Conformance

extension BodyMetric: FetchableRecord, PersistableRecord {
    static let databaseTableName = "bodyMetrics"
}

// MARK: - Factory

extension BodyMetric {
    static func new(
        weight: Double,
        date: Date = Date(),
        notes: String? = nil
    ) -> BodyMetric {
        BodyMetric(
            id: UUID().uuidString,
            weight: weight,
            date: date,
            notes: notes
        )
    }
}
