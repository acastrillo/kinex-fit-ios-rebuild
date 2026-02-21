import Foundation

/// Manages the state for creating a new manual workout.
@Observable
@MainActor
final class AddWorkoutViewModel {
    // MARK: - State

    var title: String = ""
    var content: String = ""
    var isSaving = false
    var error: String?
    var didSave = false

    // MARK: - Dependencies

    private let workoutRepository: WorkoutRepository

    init(workoutRepository: WorkoutRepository) {
        self.workoutRepository = workoutRepository
    }

    // MARK: - Computed

    var canSave: Bool {
        !title.isBlank
    }

    // MARK: - Actions

    func save() {
        guard canSave else { return }

        isSaving = true
        let workout = Workout.new(
            title: title.trimmed,
            content: content.isBlank ? nil : content.trimmed,
            source: .manual
        )

        do {
            try workoutRepository.save(workout)
            didSave = true
            // TODO: Phase 4 — enqueue sync creation
        } catch {
            self.error = "Failed to save workout: \(error.localizedDescription)"
        }

        isSaving = false
    }
}
