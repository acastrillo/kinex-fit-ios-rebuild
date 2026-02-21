import Foundation
import GRDB

/// Manages body metrics with real-time GRDB observation and chart data.
@Observable
@MainActor
final class MetricsViewModel {
    // MARK: - State

    var metrics: [BodyMetric] = []
    var showAddMetric = false
    var metricToDelete: BodyMetric?
    var showDeleteConfirmation = false
    var error: String?

    // MARK: - Computed

    /// Latest weight entry.
    var latestWeight: Double? {
        metrics.first?.weight
    }

    /// Weight change from the second-most-recent to the most-recent entry.
    var weightChange: Double? {
        guard metrics.count >= 2 else { return nil }
        return metrics[0].weight - metrics[1].weight
    }

    /// Metrics for the chart (last 30 entries, sorted ascending by date for chart display).
    var chartData: [BodyMetric] {
        Array(metrics.prefix(30).reversed())
    }

    // MARK: - Dependencies

    private let bodyMetricRepository: BodyMetricRepository
    private var observation: AnyDatabaseCancellable?

    init(bodyMetricRepository: BodyMetricRepository) {
        self.bodyMetricRepository = bodyMetricRepository
    }

    // MARK: - Observation

    func startObserving() {
        observation = bodyMetricRepository.observeAll { [weak self] metrics in
            Task { @MainActor in
                self?.metrics = metrics
            }
        }
    }

    // MARK: - Actions

    func confirmDelete(_ metric: BodyMetric) {
        metricToDelete = metric
        showDeleteConfirmation = true
    }

    func deleteMetric(_ metric: BodyMetric) {
        do {
            try bodyMetricRepository.delete(id: metric.id)
            // TODO: Phase 4 — enqueue sync deletion
        } catch {
            self.error = "Failed to delete: \(error.localizedDescription)"
        }
    }
}
