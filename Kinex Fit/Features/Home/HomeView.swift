import SwiftUI

/// The Home tab — a dashboard showing workout summary, recent activity, and quick actions.
struct HomeView: View {
    @Environment(\.appEnvironment) private var environment
    @State private var viewModel: HomeViewModel?

    var body: some View {
        Group {
            if let viewModel {
                HomeContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                let vm = HomeViewModel(
                    workoutRepository: environment.workoutRepository,
                    bodyMetricRepository: environment.bodyMetricRepository,
                    environment: environment
                )
                vm.startObserving()
                viewModel = vm
            }
        }
    }
}

// MARK: - Home Content

private struct HomeContent: View {
    @Bindable var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacingXL) {
                    // Greeting
                    greetingSection

                    // Stats cards
                    statsSection

                    // Quick actions
                    quickActionsSection

                    // Recent workouts
                    recentWorkoutsSection
                }
                .padding(AppTheme.spacingLG)
            }
            .navigationTitle("Home")
        }
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
            Text(viewModel.greeting)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(viewModel.userName)
                .font(.largeTitle)
                .fontWeight(.bold)
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppTheme.spacingMD) {
            StatCard(
                title: "Workouts",
                value: "\(viewModel.totalWorkoutCount)",
                subtitle: "\(viewModel.workoutsThisWeek) this week",
                icon: AppTheme.TabIcon.library
            )

            StatCard(
                title: "Weight",
                value: viewModel.latestWeight.map { String(format: "%.1f", $0.weight) } ?? "—",
                subtitle: viewModel.latestWeight?.date.relativeString ?? "No data",
                icon: AppTheme.TabIcon.metrics
            )

            StatCard(
                title: "Scans Left",
                value: viewModel.subscriptionTier.isUnlimited ? "∞" : "\(viewModel.remainingScans)",
                subtitle: viewModel.subscriptionTier.displayName,
                icon: AppTheme.Icon.ocrScan
            )

            StatCard(
                title: "AI Credits",
                value: viewModel.subscriptionTier.isUnlimited ? "∞" : "\(viewModel.remainingAI)",
                subtitle: viewModel.subscriptionTier.displayName,
                icon: AppTheme.Icon.star
            )
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: AppTheme.spacingMD) {
                QuickActionButton(
                    title: "New Workout",
                    icon: AppTheme.Icon.add,
                    color: .blue
                ) {
                    // TODO: Navigate to add workout
                }

                QuickActionButton(
                    title: "Scan",
                    icon: AppTheme.Icon.ocrScan,
                    color: .purple
                ) {
                    // TODO: Navigate to scanner tab
                }

                QuickActionButton(
                    title: "Log Weight",
                    icon: AppTheme.TabIcon.metrics,
                    color: .green
                ) {
                    // TODO: Navigate to metrics tab
                }
            }
        }
    }

    // MARK: - Recent Workouts

    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            HStack {
                Text("Recent Workouts")
                    .font(.headline)
                Spacer()
                // TODO: Navigate to library tab
                Text("See All")
                    .font(.subheadline)
                    .foregroundStyle(.accent)
            }

            if viewModel.recentWorkouts.isEmpty {
                Text("No workouts yet. Create your first one!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppTheme.spacingXL)
            } else {
                ForEach(viewModel.recentWorkouts) { workout in
                    RecentWorkoutCard(workout: workout)
                }
            }
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.accent)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(AppTheme.spacingMD)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(AppTheme.cornerRadiusMD)
    }
}

// MARK: - Quick Action Button

private struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.spacingSM) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15))
                    .foregroundStyle(color)
                    .clipShape(Circle())

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Recent Workout Card

private struct RecentWorkoutCard: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: AppTheme.spacingMD) {
            Image(systemName: AppTheme.Icon.workout)
                .font(.title3)
                .foregroundStyle(.accent)
                .frame(width: 40, height: 40)
                .background(.accent.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(workout.updatedAt.relativeString)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Image(systemName: AppTheme.Icon.chevronRight)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(AppTheme.spacingMD)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(AppTheme.cornerRadiusSM)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .withPreviewEnvironment()
}
