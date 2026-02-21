import SwiftUI

/// Review screen shown after OCR processing. User can edit title/content before saving.
struct OCRResultView: View {
    let result: OCRResponse
    let capturedImage: UIImage?
    let onSave: (String, String) -> Void
    let onDiscard: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: OCRResultViewModel

    init(
        result: OCRResponse,
        capturedImage: UIImage?,
        onSave: @escaping (String, String) -> Void,
        onDiscard: @escaping () -> Void
    ) {
        self.result = result
        self.capturedImage = capturedImage
        self.onSave = onSave
        self.onDiscard = onDiscard
        _viewModel = State(initialValue: OCRResultViewModel(result: result))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacingLG) {
                    // Captured image thumbnail
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(AppTheme.cornerRadiusMD)
                            .frame(maxWidth: .infinity)
                    }

                    // Title field
                    VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                        Text("Title")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        TextField("Workout title", text: $viewModel.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Extracted content
                    VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                        Text("Extracted Text")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        TextEditor(text: $viewModel.content)
                            .font(.body)
                            .frame(minHeight: 250)
                            .scrollContentBackground(.hidden)
                            .padding(AppTheme.spacingSM)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(AppTheme.cornerRadiusSM)
                    }
                }
                .padding(AppTheme.spacingLG)
            }
            .navigationTitle("Review Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") {
                        onDiscard()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(viewModel.title, viewModel.content)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OCRResultView(
        result: OCRResponse(title: "Push Day", content: "Bench Press 4x8\nOverhead Press 3x10\nTricep Dips 3x12"),
        capturedImage: nil,
        onSave: { _, _ in },
        onDiscard: {}
    )
}
