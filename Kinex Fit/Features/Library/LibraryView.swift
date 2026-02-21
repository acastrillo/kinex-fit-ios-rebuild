import SwiftUI

/// The Library tab — displays all saved workouts with search, swipe-delete, and pull-to-refresh.
struct LibraryView: View {
    @Environment(\.appEnvironment) private var environment
    @State private var viewModel: LibraryViewModel?

    var body: some View {
        Group {
            if let viewModel {
                LibraryContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                let vm = LibraryViewModel(workoutRepository: environment.workoutRepository)
                vm.startObserving()
                viewModel = vm
            }
        }
    }
}

// MARK: - Library Content

private struct LibraryContent: View {
    @Bindable var viewModel: LibraryViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.workouts.isEmpty && viewModel.searchText.isEmpty {
                    ContentUnavailableView(
                        "No Workouts Yet",
                        systemImage: AppTheme.TabIcon.library,
                        description: Text("Tap + to create your first workout")
                    )
                } else if viewModel.workouts.isEmpty {
                    ContentUnavailableView.search(text: viewModel.searchText)
                } else {
                    workoutList
                }
            }
            .navigationTitle("Library")
            .searchable(text: $viewModel.searchText, prompt: "Search workouts")
            .refreshable {
                await viewModel.refresh()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showAddWorkout = true
                    } label: {
                        Image(systemName: AppTheme.Icon.add)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddWorkout) {
                AddWorkoutView()
            }
            .confirmationDialog(
                "Delete Workout",
                isPresented: $viewModel.showDeleteConfirmation,
                presenting: viewModel.workoutToDelete
            ) { workout in
                Button("Delete", role: .destructive) {
                    viewModel.deleteWorkout(workout)
                }
            } message: { workout in
                Text("Are you sure you want to delete \"\(workout.title)\"? This cannot be undone.")
            }
            .overlay {
                if let error = viewModel.error {
                    errorBanner(error)
                }
            }
        }
    }

    // MARK: - Workout List

    private var workoutList: some View {
        List {
            ForEach(viewModel.workouts) { workout in
                NavigationLink(value: workout) {
                    WorkoutRowView(workout: workout)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.confirmDelete(workout)
                    } label: {
                        Label("Delete", systemImage: AppTheme.Icon.delete)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: Workout.self) { workout in
            WorkoutDetailView(workout: workout)
        }
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text(message)
                    .font(.caption)
                Spacer()
                Button {
                    withAnimation(AppTheme.defaultAnimation) {
                        viewModel.error = nil
                    }
                } label: {
                    Image(systemName: AppTheme.Icon.close)
                        .font(.caption)
                }
            }
            .padding(AppTheme.spacingMD)
            .background(.ultraThinMaterial)
            .cornerRadius(AppTheme.cornerRadiusSM)
            .padding(.horizontal, AppTheme.spacingLG)
            .transition(AppTheme.bannerTransition)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    LibraryView()
        .withPreviewEnvironment()
}
