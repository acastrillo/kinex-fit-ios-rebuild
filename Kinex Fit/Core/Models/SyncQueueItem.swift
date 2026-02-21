import Foundation
import GRDB

struct SyncQueueItem: Identifiable, Codable, Equatable, Sendable {
    var id: String
    var entity: String
    var operation: String
    var entityId: String
    var payload: String
    var createdAt: Date
    var retryCount: Int
    var lastError: String?
    var nextAttemptAt: Date?

    var isPending: Bool {
        retryCount < 5 && (nextAttemptAt == nil || nextAttemptAt! <= Date())
    }

    var isFailed: Bool {
        retryCount >= 5
    }
}

// MARK: - GRDB Conformance

extension SyncQueueItem: FetchableRecord, PersistableRecord {
    static let databaseTableName = "syncQueue"
}

// MARK: - Operations & Entities

enum SyncOperation: String, Codable, Sendable {
    case create
    case update
    case delete
}

enum SyncEntity: String, Codable, Sendable {
    case workout
    case bodyMetric
    case user
}

// MARK: - Factory

extension SyncQueueItem {
    static func new(
        entity: SyncEntity,
        operation: SyncOperation,
        entityId: String,
        payload: String
    ) -> SyncQueueItem {
        SyncQueueItem(
            id: UUID().uuidString,
            entity: entity.rawValue,
            operation: operation.rawValue,
            entityId: entityId,
            payload: payload,
            createdAt: Date(),
            retryCount: 0,
            lastError: nil,
            nextAttemptAt: nil
        )
    }
}
