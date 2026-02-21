import SwiftUI

/// Full-screen review flow for pending Instagram imports.
struct InstagramImportReviewView: View {
    @Environment(\.appEnvironment) private var environment
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: InstagramImportViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    ImportReviewContent(viewModel: viewModel, dismiss: dismiss)
                } else {
                    ProgressView()
                }
            }
            .onAppear {
                if viewModel == nil {
                    let service = InstagramImportService(
                        appGroupStorage: AppGroupStorage(),
                        ocrService: OCRService(apiClient: environment.apiClient),
                        workoutRepository: environment.workoutRepository,
                        syncEngine: environment.syncEngine
                    )
                    let vm = InstagramImportViewModel(importService: service)
                    vm.loadPendingImports()
                    viewModel = vm
                }
            }
        }
    }
}

// MARK: - Content

private struct ImportReviewContent: View {
    @Bindable var viewModel: InstagramImportViewModel
    let dismiss: DismissAction

    var body: some View {
        Group {
            if viewModel.isProcessing {
                VStack(spacing: AppTheme.spacingLG) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Processing import...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.ocrResult != nil {
                editForm
            } else if viewModel.hasPending {
                pendingList
            } else {
                ContentUnavailableView(
                    "No Pending Imports",
                    systemImage: AppTheme.Icon.instagram,
                    description: Text("Share workout images from Instagram to import them here.")
                )
            }
        }
        .navigationTitle("Instagram Imports")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .onChange(of: viewModel.didSave) { _, saved in
            if saved {
                viewModel.didSave = false
                // Auto-process next or close if none left
                if viewModel.hasPending {
                    Task { await viewModel.processNext() }
                }
            }
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

    // MARK: - Pending List

    private var pendingList: some View {
        List(viewModel.pendingImports) { item in
            HStack {
                Image(systemName: AppTheme.Icon.instagram)
                    .foregroundStyle(.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Import from \(item.capturedAt.dateTimeString)")
                        .font(.subheadline)

                    if let url = item.sourceURL {
                        Text(url)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                Task { await viewModel.processNext() }
            }
        }
    }

    // MARK: - Edit Form

    private var editForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingLG) {
                VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                    Text("Title")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    TextField("Workout title", text: $viewModel.editTitle)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                    Text("Extracted Content")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    TextEditor(text: $viewModel.editContent)
                        .font(.body)
                        .frame(minHeight: 250)
                        .scrollContentBackground(.hidden)
                        .padding(AppTheme.spacingSM)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(AppTheme.cornerRadiusSM)
                }

                HStack(spacing: AppTheme.spacingMD) {
                    Button(role: .destructive) {
                        viewModel.discardCurrentImport()
                    } label: {
                        Text("Discard")
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        viewModel.saveCurrentImport()
                    } label: {
                        Text("Save Workout")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canSave)
                }
            }
            .padding(AppTheme.spacingLG)
        }
    }
}

// MARK: - Preview

#Preview {
    InstagramImportReviewView()
        .withPreviewEnvironment()
}
