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
    private let syncEngine: SyncEngine

    init(workoutRepository: WorkoutRepository, syncEngine: SyncEngine) {
        self.workoutRepository = workoutRepository
        self.syncEngine = syncEngine
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
            syncEngine.enqueue(
                operation: .create,
                entity: .workout,
                entityId: workout.id,
                object: workout
            )
            didSave = true
        } catch {
            self.error = "Failed to save workout: \(error.localizedDescription)"
        }

        isSaving = false
    }
}
