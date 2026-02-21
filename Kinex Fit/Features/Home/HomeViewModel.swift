import Foundation
import GRDB

/// Manages dashboard data for the Home tab — aggregates workouts, metrics, and user info.
@Observable
@MainActor
final class HomeViewModel {
    // MARK: - State

    var recentWorkouts: [Workout] = []
    var totalWorkoutCount: Int = 0
    var latestWeight: BodyMetric?
    var userName: String = ""
    var subscriptionTier: SubscriptionTier = .free
    var remainingScans: Int = 0
    var remainingAI: Int = 0
    var pendingInstagramImports: Int = 0

    // MARK: - Dependencies

    private let workoutRepository: WorkoutRepository
    private let bodyMetricRepository: BodyMetricRepository
    private let environment: AppEnvironment
    private var workoutObservation: AnyDatabaseCancellable?
    private var metricObservation: AnyDatabaseCancellable?

    init(
        workoutRepository: WorkoutRepository,
        bodyMetricRepository: BodyMetricRepository,
        environment: AppEnvironment
    ) {
        self.workoutRepository = workoutRepository
        self.bodyMetricRepository = bodyMetricRepository
        self.environment = environment
    }

    // MARK: - Observation

    func startObserving() {
        // Observe workouts — take the 5 most recent for the dashboard
        workoutObservation = workoutRepository.observeAll { [weak self] workouts in
            Task { @MainActor in
                self?.recentWorkouts = Array(workouts.prefix(5))
                self?.totalWorkoutCount = workouts.count
            }
        }

        // Observe latest body metric
        metricObservation = bodyMetricRepository.observeAll { [weak self] metrics in
            Task { @MainActor in
                self?.latestWeight = metrics.first
            }
        }

        refreshUserInfo()
        checkPendingImports()
    }

    /// Refreshes user-related dashboard data.
    func refreshUserInfo() {
        guard let user = environment.currentUser else { return }
        userName = user.name
        subscriptionTier = user.subscriptionTier
        remainingScans = user.remainingScans
        remainingAI = user.remainingAIOperations
    }

    /// Checks for pending Instagram imports in the App Group shared container.
    func checkPendingImports() {
        let storage = AppGroupStorage()
        pendingInstagramImports = storage.pendingImports().count
    }

    // MARK: - Computed

    /// Greeting based on time of day.
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    /// Workouts logged this week.
    var workoutsThisWeek: Int {
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return recentWorkouts.filter { $0.createdAt >= startOfWeek }.count
    }
}
