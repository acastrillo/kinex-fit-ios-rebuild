import Foundation
import GRDB

/// Manages the workout library list with search, CRUD, and real-time GRDB observation.
@Observable
@MainActor
final class LibraryViewModel {
    // MARK: - State

    var workouts: [Workout] = []
    var searchText: String = "" {
        didSet { restartObservation() }
    }
    var isLoading = false
    var error: String?
    var workoutToDelete: Workout?
    var showAddWorkout = false
    var showDeleteConfirmation = false

    // MARK: - Dependencies

    private let workoutRepository: WorkoutRepository
    private var observation: AnyDatabaseCancellable?

    init(workoutRepository: WorkoutRepository) {
        self.workoutRepository = workoutRepository
    }

    // MARK: - Observation

    /// Starts observing workouts from GRDB. Automatically updates `workouts` on any change.
    func startObserving() {
        restartObservation()
    }

    private func restartObservation() {
        observation?.cancel()

        if searchText.trimmed.isEmpty {
            observation = workoutRepository.observeAll { [weak self] workouts in
                Task { @MainActor in
                    self?.workouts = workouts
                }
            }
        } else {
            observation = workoutRepository.observeSearch(query: searchText.trimmed) { [weak self] workouts in
                Task { @MainActor in
                    self?.workouts = workouts
                }
            }
        }
    }

    // MARK: - Actions

    func deleteWorkout(_ workout: Workout) {
        do {
            try workoutRepository.delete(id: workout.id)
            // TODO: Phase 4 — enqueue sync deletion
        } catch {
            self.error = "Failed to delete workout: \(error.localizedDescription)"
        }
    }

    func confirmDelete(_ workout: Workout) {
        workoutToDelete = workout
        showDeleteConfirmation = true
    }

    func refresh() async {
        isLoading = true
        // TODO: Phase 4 — trigger sync engine pull + push
        // For now, just reload from local DB
        do {
            workouts = try workoutRepository.fetchAll()
        } catch {
            self.error = "Failed to refresh: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
