import Foundation

/// Manages viewing, editing, and deleting a single workout.
@Observable
@MainActor
final class WorkoutDetailViewModel {
    // MARK: - State

    var workout: Workout
    var isEditing = false
    var editTitle: String = ""
    var editContent: String = ""
    var showDeleteConfirmation = false
    var error: String?
    var didDelete = false

    // MARK: - Dependencies

    private let workoutRepository: WorkoutRepository

    init(workout: Workout, workoutRepository: WorkoutRepository) {
        self.workout = workout
        self.workoutRepository = workoutRepository
        self.editTitle = workout.title
        self.editContent = workout.content ?? ""
    }

    // MARK: - Actions

    func startEditing() {
        editTitle = workout.title
        editContent = workout.content ?? ""
        isEditing = true
    }

    func cancelEditing() {
        isEditing = false
    }

    func saveEdits() {
        guard !editTitle.isBlank else {
            error = "Title cannot be empty"
            return
        }

        workout.title = editTitle.trimmed
        workout.content = editContent.isBlank ? nil : editContent.trimmed
        workout.updatedAt = Date()

        do {
            try workoutRepository.save(workout)
            isEditing = false
            // TODO: Phase 4 — enqueue sync update
        } catch {
            self.error = "Failed to save: \(error.localizedDescription)"
        }
    }

    func deleteWorkout() {
        do {
            try workoutRepository.delete(id: workout.id)
            didDelete = true
            // TODO: Phase 4 — enqueue sync deletion
        } catch {
            self.error = "Failed to delete: \(error.localizedDescription)"
        }
    }
}
