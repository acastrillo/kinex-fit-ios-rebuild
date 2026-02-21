import SwiftUI
import PhotosUI

/// The Scan tab — camera + photo picker for OCR workout extraction.
struct ScannerView: View {
    @Environment(\.appEnvironment) private var environment
    @State private var viewModel: ScannerViewModel?

    var body: some View {
        Group {
            if let viewModel {
                ScannerContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ScannerViewModel(
                    ocrService: OCRService(apiClient: environment.apiClient),
                    workoutRepository: environment.workoutRepository,
                    syncEngine: environment.syncEngine,
                    environment: environment
                )
            }
        }
    }
}

// MARK: - Scanner Content

private struct ScannerContent: View {
    @Bindable var viewModel: ScannerViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.spacingXL) {
                Spacer()

                // Icon
                Image(systemName: AppTheme.Icon.ocrScan)
                    .font(.system(size: 72))
                    .foregroundStyle(.accent)
                    .symbolEffect(.pulse, isActive: viewModel.isProcessing)

                // Title
                Text("Scan a Workout")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Take a photo or choose one from your library to extract workout text.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.spacingXXL)

                // Quota badge
                if !viewModel.quotaText.isEmpty {
                    Text(viewModel.quotaText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, AppTheme.spacingMD)
                        .padding(.vertical, AppTheme.spacingXS)
                        .background(viewModel.canScan ? Color.accent.opacity(0.15) : Color.red.opacity(0.15))
                        .foregroundStyle(viewModel.canScan ? .accent : .red)
                        .cornerRadius(AppTheme.cornerRadiusSM)
                }

                Spacer()

                // Action buttons
                VStack(spacing: AppTheme.spacingMD) {
                    Button {
                        viewModel.showCamera = true
                    } label: {
                        Label("Take Photo", systemImage: AppTheme.Icon.camera)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canScan || viewModel.isProcessing)

                    PhotosPicker(
                        selection: $viewModel.selectedPhoto,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.canScan || viewModel.isProcessing)
                }
                .padding(.horizontal, AppTheme.spacingXL)
                .padding(.bottom, AppTheme.spacingXXL)
            }
            .navigationTitle("Scan")
            .overlay {
                if viewModel.isProcessing {
                    processingOverlay
                }
            }
            .onChange(of: viewModel.selectedPhoto) { _, _ in
                Task {
                    await viewModel.handleSelectedPhoto()
                }
            }
            .fullScreenCover(isPresented: $viewModel.showCamera) {
                CameraView { image in
                    Task {
                        await viewModel.handleCapturedImage(image)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showResult) {
                if let result = viewModel.ocrResult {
                    OCRResultView(
                        result: result,
                        capturedImage: viewModel.capturedImage,
                        onSave: { title, content in
                            viewModel.saveAsWorkout(title: title, content: content)
                        },
                        onDiscard: {
                            viewModel.reset()
                        }
                    )
                }
            }
            .alert("Scan Error", isPresented: Binding(
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
    }

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: AppTheme.spacingLG) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Extracting text...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(AppTheme.spacingXXL)
            .background(.ultraThinMaterial)
            .cornerRadius(AppTheme.cornerRadiusMD)
        }
    }
}

// MARK: - Camera View

/// Simple camera capture using UIImagePickerController.
struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, dismiss: dismiss)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        let dismiss: DismissAction

        init(onCapture: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onCapture = onCapture
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    ScannerView()
        .withPreviewEnvironment()
}
