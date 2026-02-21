import SwiftUI

/// Full detail view for a single workout with edit and delete capabilities.
struct WorkoutDetailView: View {
    @Environment(\.appEnvironment) private var environment
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: WorkoutDetailViewModel?

    let workout: Workout

    var body: some View {
        Group {
            if let viewModel {
                WorkoutDetailContent(viewModel: viewModel, dismiss: dismiss)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = WorkoutDetailViewModel(
                    workout: workout,
                    workoutRepository: environment.workoutRepository,
                    syncEngine: environment.syncEngine
                )
            }
        }
    }
}

// MARK: - Detail Content

private struct WorkoutDetailContent: View {
    @Bindable var viewModel: WorkoutDetailViewModel
    let dismiss: DismissAction

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingLG) {
                // Header
                headerSection

                Divider()

                // Content
                if viewModel.isEditing {
                    editingSection
                } else {
                    displaySection
                }
            }
            .padding(AppTheme.spacingLG)
        }
        .navigationTitle(viewModel.isEditing ? "Edit Workout" : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if viewModel.isEditing {
                    Button("Save") {
                        viewModel.saveEdits()
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.editTitle.isBlank)
                } else {
                    Menu {
                        Button {
                            viewModel.startEditing()
                        } label: {
                            Label("Edit", systemImage: AppTheme.Icon.edit)
                        }

                        Button(role: .destructive) {
                            viewModel.showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: AppTheme.Icon.delete)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }

            if viewModel.isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelEditing()
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete Workout",
            isPresented: $viewModel.showDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                viewModel.deleteWorkout()
            }
        } message: {
            Text("Are you sure you want to delete \"\(viewModel.workout.title)\"? This cannot be undone.")
        }
        .onChange(of: viewModel.didDelete) { _, deleted in
            if deleted { dismiss() }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            if viewModel.isEditing {
                TextField("Workout Title", text: $viewModel.editTitle)
                    .font(.title2)
                    .fontWeight(.bold)
            } else {
                Text(viewModel.workout.title)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            HStack(spacing: AppTheme.spacingMD) {
                Label(viewModel.workout.source.displayName, systemImage: sourceIcon)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("·")
                    .foregroundStyle(.tertiary)

                Text(viewModel.workout.updatedAt.dateTimeString)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var sourceIcon: String {
        switch viewModel.workout.source {
        case .manual: AppTheme.Icon.edit
        case .ocr: AppTheme.Icon.ocrScan
        case .instagram: AppTheme.Icon.instagram
        case .imported: "square.and.arrow.down"
        }
    }

    // MARK: - Display

    private var displaySection: some View {
        Group {
            if let content = viewModel.workout.content, !content.isBlank {
                Text(content)
                    .font(.body)
                    .lineSpacing(4)
            } else {
                Text("No content")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .italic()
            }
        }
    }

    // MARK: - Editing

    private var editingSection: some View {
        TextEditor(text: $viewModel.editContent)
            .font(.body)
            .frame(minHeight: 200)
            .scrollContentBackground(.hidden)
            .padding(AppTheme.spacingSM)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(AppTheme.cornerRadiusSM)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WorkoutDetailView(workout: MockData.workouts[0])
    }
    .withPreviewEnvironment()
}
