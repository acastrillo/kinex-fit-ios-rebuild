import Foundation

/// Manages the state for logging a new body metric entry.
@Observable
@MainActor
final class AddMetricViewModel {
    // MARK: - State

    var weightText: String = ""
    var date: Date = Date()
    var notes: String = ""
    var isSaving = false
    var error: String?
    var didSave = false

    // MARK: - Dependencies

    private let bodyMetricRepository: BodyMetricRepository

    init(bodyMetricRepository: BodyMetricRepository) {
        self.bodyMetricRepository = bodyMetricRepository
    }

    // MARK: - Computed

    var canSave: Bool {
        guard let weight = Double(weightText), weight > 0, weight < 1000 else {
            return false
        }
        return true
    }

    // MARK: - Actions

    func save() {
        guard let weight = Double(weightText) else {
            error = "Please enter a valid weight"
            return
        }

        isSaving = true

        let metric = BodyMetric.new(
            weight: weight,
            date: date,
            notes: notes.isBlank ? nil : notes.trimmed
        )

        do {
            try bodyMetricRepository.save(metric)
            didSave = true
            // TODO: Phase 4 — enqueue sync creation
        } catch {
            self.error = "Failed to save: \(error.localizedDescription)"
        }

        isSaving = false
    }
}
