import SwiftUI

/// Sheet for creating a new manual workout.
struct AddWorkoutView: View {
    @Environment(\.appEnvironment) private var environment
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddWorkoutViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    AddWorkoutContent(viewModel: viewModel, dismiss: dismiss)
                } else {
                    ProgressView()
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = AddWorkoutViewModel(
                        workoutRepository: environment.workoutRepository
                    )
                }
            }
        }
    }
}

// MARK: - Content

private struct AddWorkoutContent: View {
    @Bindable var viewModel: AddWorkoutViewModel
    let dismiss: DismissAction
    @FocusState private var focusedField: Field?

    enum Field { case title, content }

    var body: some View {
        Form {
            Section("Title") {
                TextField("Workout name", text: $viewModel.title)
                    .focused($focusedField, equals: .title)
            }

            Section("Details") {
                TextEditor(text: $viewModel.content)
                    .frame(minHeight: 150)
                    .focused($focusedField, equals: .content)
            }

            Section {
                Text("Enter exercises, sets, reps, weights — whatever you want to track.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("New Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    viewModel.save()
                }
                .fontWeight(.semibold)
                .disabled(!viewModel.canSave || viewModel.isSaving)
            }
        }
        .onChange(of: viewModel.didSave) { _, saved in
            if saved { dismiss() }
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
        .onAppear {
            focusedField = .title
        }
    }
}

// MARK: - Preview

#Preview {
    AddWorkoutView()
        .withPreviewEnvironment()
}
