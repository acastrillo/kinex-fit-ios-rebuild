import SwiftUI

/// Sheet for logging a new body weight measurement.
struct AddMetricView: View {
    @Environment(\.appEnvironment) private var environment
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddMetricViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    AddMetricContent(viewModel: viewModel, dismiss: dismiss)
                } else {
                    ProgressView()
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = AddMetricViewModel(
                        bodyMetricRepository: environment.bodyMetricRepository
                    )
                }
            }
        }
    }
}

// MARK: - Content

private struct AddMetricContent: View {
    @Bindable var viewModel: AddMetricViewModel
    let dismiss: DismissAction
    @FocusState private var weightFocused: Bool

    var body: some View {
        Form {
            Section("Weight") {
                HStack {
                    TextField("0.0", text: $viewModel.weightText)
                        .keyboardType(.decimalPad)
                        .focused($weightFocused)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("lbs")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Date") {
                DatePicker(
                    "Date",
                    selection: $viewModel.date,
                    in: ...Date(),
                    displayedComponents: .date
                )
            }

            Section("Notes (optional)") {
                TextField("e.g. Morning weigh-in, after workout", text: $viewModel.notes)
            }
        }
        .navigationTitle("Log Weight")
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
            weightFocused = true
        }
    }
}

// MARK: - Preview

#Preview {
    AddMetricView()
        .withPreviewEnvironment()
}
