import Foundation

/// Sample data for Xcode Previews and UI development.
enum MockData {

    // MARK: - Workouts

    static let workouts: [Workout] = [
        Workout(
            id: "workout-001",
            title: "Push Day - Chest & Shoulders",
            content: """
            Bench Press: 4x8 @ 185lbs
            Incline DB Press: 3x10 @ 65lbs
            OHP: 3x8 @ 115lbs
            Lateral Raises: 3x15 @ 20lbs
            Tricep Pushdowns: 3x12 @ 50lbs
            """,
            source: .manual,
            createdAt: Date().addingTimeInterval(-86400 * 1),
            updatedAt: Date().addingTimeInterval(-86400 * 1)
        ),
        Workout(
            id: "workout-002",
            title: "Pull Day - Back & Biceps",
            content: """
            Deadlifts: 4x5 @ 275lbs
            Pull-ups: 4x8 bodyweight
            Barbell Rows: 3x10 @ 155lbs
            Face Pulls: 3x15 @ 30lbs
            Barbell Curls: 3x10 @ 75lbs
            """,
            source: .manual,
            createdAt: Date().addingTimeInterval(-86400 * 3),
            updatedAt: Date().addingTimeInterval(-86400 * 3)
        ),
        Workout(
            id: "workout-003",
            title: "Leg Day",
            content: """
            Squats: 4x6 @ 225lbs
            Romanian Deadlifts: 3x10 @ 185lbs
            Leg Press: 3x12 @ 360lbs
            Leg Curls: 3x12 @ 90lbs
            Calf Raises: 4x15 @ 135lbs
            """,
            source: .ocr,
            createdAt: Date().addingTimeInterval(-86400 * 5),
            updatedAt: Date().addingTimeInterval(-86400 * 5)
        ),
        Workout(
            id: "workout-004",
            title: "HIIT Cardio Circuit",
            content: """
            30s Burpees / 30s Rest
            30s Mountain Climbers / 30s Rest
            30s Box Jumps / 30s Rest
            30s Battle Ropes / 30s Rest
            Repeat 4 rounds
            """,
            source: .instagram,
            createdAt: Date().addingTimeInterval(-86400 * 7),
            updatedAt: Date().addingTimeInterval(-86400 * 7)
        )
    ]

    // MARK: - Body Metrics

    static let bodyMetrics: [BodyMetric] = [
        BodyMetric(id: "metric-001", weight: 185.5, date: Date(), notes: "Morning weigh-in"),
        BodyMetric(id: "metric-002", weight: 186.0, date: Date().addingTimeInterval(-86400 * 1), notes: nil),
        BodyMetric(id: "metric-003", weight: 184.8, date: Date().addingTimeInterval(-86400 * 3), notes: "After cardio day"),
        BodyMetric(id: "metric-004", weight: 185.2, date: Date().addingTimeInterval(-86400 * 5), notes: nil),
        BodyMetric(id: "metric-005", weight: 186.5, date: Date().addingTimeInterval(-86400 * 7), notes: "Start of week"),
        BodyMetric(id: "metric-006", weight: 187.0, date: Date().addingTimeInterval(-86400 * 10), notes: nil),
        BodyMetric(id: "metric-007", weight: 188.2, date: Date().addingTimeInterval(-86400 * 14), notes: "Two weeks ago")
    ]

    // MARK: - Users

    static let freeUser = User(
        id: "user-free",
        name: "Free User",
        email: "free@example.com",
        provider: "email",
        subscriptionTier: .free,
        scanQuotaUsed: 3,
        aiQuotaUsed: 2,
        onboardingCompleted: true
    )

    static let proUser = User(
        id: "user-pro",
        name: "Pro User",
        email: "pro@example.com",
        provider: "apple",
        subscriptionTier: .pro,
        scanQuotaUsed: 12,
        aiQuotaUsed: 25,
        onboardingCompleted: true
    )

    static let newUser = User(
        id: "user-new",
        name: "New User",
        email: "new@example.com",
        provider: "google",
        subscriptionTier: .free,
        scanQuotaUsed: 0,
        aiQuotaUsed: 0,
        onboardingCompleted: false
    )
}
