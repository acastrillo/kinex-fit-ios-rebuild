import Foundation

/// Offline-first sync engine that processes a local queue of pending mutations
/// against the backend API with exponential backoff retry.
///
/// **Flow:**
/// 1. Local mutation (create/update/delete) saves to GRDB immediately
/// 2. Mutation enqueued in `syncQueue` table via `enqueue()`
/// 3. `processQueue()` picks up pending items and sends to backend
/// 4. On success: item removed from queue
/// 5. On failure: retry count incremented, next attempt scheduled with backoff
///
/// **Triggers:** enqueue, app foreground, pull-to-refresh, network reachability change
@Observable
@MainActor
final class SyncEngine {
    // MARK: - State

    enum Status: Equatable {
        case idle
        case syncing
        case success
        case error(String)

        var isActive: Bool {
            if case .syncing = self { return true }
            return false
        }
    }

    var status: Status = .idle
    var pendingCount: Int = 0

    // MARK: - Configuration

    private let maxRetries = 5
    private let baseDelay: TimeInterval = 60 // 1 minute

    // MARK: - Dependencies

    private let apiClient: APIClient
    private let syncQueueRepository: SyncQueueRepository
    private var processingTask: Task<Void, Never>?

    init(apiClient: APIClient, syncQueueRepository: SyncQueueRepository) {
        self.apiClient = apiClient
        self.syncQueueRepository = syncQueueRepository
        refreshPendingCount()
    }

    // MARK: - Enqueue

    /// Enqueues a mutation for background sync.
    /// Call this after saving to the local database.
    func enqueue(
        operation: SyncOperation,
        entity: SyncEntity,
        entityId: String,
        payload: Data
    ) {
        let payloadString = String(data: payload, encoding: .utf8) ?? "{}"
        let item = SyncQueueItem.new(
            entity: entity,
            operation: operation,
            entityId: entityId,
            payload: payloadString
        )

        do {
            try syncQueueRepository.save(item)
            refreshPendingCount()
            processQueue()
        } catch {
            print("SyncEngine: Failed to enqueue: \(error)")
        }
    }

    /// Convenience for enqueuing an Encodable payload.
    func enqueue<T: Encodable>(
        operation: SyncOperation,
        entity: SyncEntity,
        entityId: String,
        object: T
    ) {
        do {
            let data = try JSONEncoder.apiEncoder.encode(object)
            enqueue(operation: operation, entity: entity, entityId: entityId, payload: data)
        } catch {
            print("SyncEngine: Failed to encode payload: \(error)")
        }
    }

    // MARK: - Process Queue

    /// Triggers queue processing. Safe to call multiple times — concurrent calls are coalesced.
    func processQueue() {
        guard processingTask == nil else { return }

        processingTask = Task { [weak self] in
            guard let self else { return }
            await self.runProcessing()
            self.processingTask = nil
        }
    }

    private func runProcessing() async {
        status = .syncing

        do {
            let items = try syncQueueRepository.fetchPending()

            guard !items.isEmpty else {
                status = .success
                refreshPendingCount()
                return
            }

            var allSucceeded = true

            for item in items {
                guard !Task.isCancelled else { break }

                // Skip items that aren't ready for retry yet
                if let nextAttempt = item.nextAttemptAt, nextAttempt > Date() {
                    allSucceeded = false
                    continue
                }

                // Skip items that exceeded max retries
                if item.retryCount >= maxRetries {
                    continue
                }

                do {
                    try await executeSync(item)
                    try syncQueueRepository.delete(item)
                } catch {
                    allSucceeded = false
                    var updated = item
                    updated.retryCount += 1
                    updated.lastError = error.localizedDescription
                    updated.nextAttemptAt = Date().addingTimeInterval(
                        baseDelay * pow(2.0, Double(updated.retryCount - 1))
                    )
                    try? syncQueueRepository.save(updated)
                }
            }

            refreshPendingCount()

            if allSucceeded {
                status = .success
            } else {
                let remaining = try syncQueueRepository.pendingCount()
                let failed = try syncQueueRepository.failedCount()
                if failed > 0 {
                    status = .error("\(failed) item(s) failed to sync")
                } else {
                    status = .error("\(remaining) item(s) pending retry")
                }
            }
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    // MARK: - Execute Individual Sync

    private func executeSync(_ item: SyncQueueItem) async throws {
        guard let operation = SyncOperation(rawValue: item.operation),
              let entity = SyncEntity(rawValue: item.entity) else {
            throw SyncError.encodingFailed
        }

        let request = try buildRequest(operation: operation, entity: entity, item: item)

        switch operation {
        case .delete:
            try await apiClient.sendNoContent(request)
        case .create, .update:
            // We discard the response for now — the local DB is source of truth
            let _: EmptyResponse = try await apiClient.send(request)
        }
    }

    private func buildRequest(
        operation: SyncOperation,
        entity: SyncEntity,
        item: SyncQueueItem
    ) throws -> APIRequest {
        let basePath: String
        switch entity {
        case .workout:
            basePath = APIEndpoints.Workouts.base
        case .bodyMetric:
            // Body metrics likely share the workouts pattern or have their own endpoint
            basePath = "/api/mobile/metrics"
        case .user:
            basePath = APIEndpoints.UserProfile.profile
        }

        switch operation {
        case .create:
            guard let data = item.payload.data(using: .utf8) else {
                throw SyncError.encodingFailed
            }
            return APIRequest(method: .post, path: basePath, body: data)

        case .update:
            guard let data = item.payload.data(using: .utf8) else {
                throw SyncError.encodingFailed
            }
            return APIRequest(method: .put, path: "\(basePath)/\(item.entityId)", body: data)

        case .delete:
            return APIRequest.delete("\(basePath)/\(item.entityId)")
        }
    }

    // MARK: - Helpers

    private func refreshPendingCount() {
        pendingCount = (try? syncQueueRepository.pendingCount()) ?? 0
    }

    /// Clears all failed items from the queue.
    func clearFailed() {
        try? syncQueueRepository.clearFailed()
        refreshPendingCount()
    }

    /// Resets all failed items to retry.
    func retryFailed() {
        do {
            let items = try syncQueueRepository.fetchAll()
            for var item in items where item.isFailed {
                item.retryCount = 0
                item.nextAttemptAt = nil
                item.lastError = nil
                try syncQueueRepository.save(item)
            }
            refreshPendingCount()
            processQueue()
        } catch {
            print("SyncEngine: Failed to retry failed items: \(error)")
        }
    }
}
