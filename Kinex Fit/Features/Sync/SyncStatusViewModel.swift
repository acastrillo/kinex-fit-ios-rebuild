import Foundation

/// Exposes sync engine state for UI display.
@Observable
@MainActor
final class SyncStatusViewModel {
    var status: SyncEngine.Status = .idle
    var pendingCount: Int = 0

    private let syncEngine: SyncEngine

    init(syncEngine: SyncEngine) {
        self.syncEngine = syncEngine
        refresh()
    }

    func refresh() {
        status = syncEngine.status
        pendingCount = syncEngine.pendingCount
    }

    var statusText: String {
        switch status {
        case .idle:
            pendingCount > 0 ? "\(pendingCount) pending" : "Up to date"
        case .syncing:
            "Syncing..."
        case .success:
            "Synced"
        case .error(let message):
            message
        }
    }

    var statusIcon: String {
        switch status {
        case .idle:
            pendingCount > 0 ? "arrow.triangle.2.circlepath" : "checkmark.circle"
        case .syncing:
            "arrow.triangle.2.circlepath"
        case .success:
            "checkmark.circle.fill"
        case .error:
            "exclamationmark.triangle.fill"
        }
    }

    var isError: Bool {
        if case .error = status { return true }
        return false
    }
}
