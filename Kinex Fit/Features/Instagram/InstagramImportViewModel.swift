import Foundation

/// Manages the Instagram import review flow.
@Observable
@MainActor
final class InstagramImportViewModel {
    // MARK: - State

    var pendingImports: [PendingInstagramImport] = []
    var currentImport: PendingInstagramImport?
    var ocrResult: OCRResponse?
    var isProcessing = false
    var error: String?
    var editTitle: String = ""
    var editContent: String = ""
    var didSave = false

    // MARK: - Dependencies

    private let importService: InstagramImportService

    init(importService: InstagramImportService) {
        self.importService = importService
    }

    // MARK: - Computed

    var hasPending: Bool {
        !pendingImports.isEmpty
    }

    var canSave: Bool {
        !editTitle.isBlank && !editContent.isBlank
    }

    // MARK: - Actions

    /// Loads pending imports from the shared container.
    func loadPendingImports() {
        pendingImports = importService.pendingImports()
    }

    /// Starts processing the next pending import.
    func processNext() async {
        guard let next = pendingImports.first else { return }
        currentImport = next
        isProcessing = true
        error = nil

        do {
            let result = try await importService.processImport(next)
            ocrResult = result
            editTitle = result.title ?? "Instagram Workout"
            editContent = result.content
        } catch {
            self.error = error.localizedDescription
        }

        isProcessing = false
    }

    /// Saves the current import as a workout.
    func saveCurrentImport() {
        guard let current = currentImport else { return }

        do {
            try importService.saveImportedWorkout(
                title: editTitle.trimmed,
                content: editContent.trimmed,
                importItem: current
            )
            pendingImports.removeAll { $0.id == current.id }
            resetCurrent()
            didSave = true
        } catch {
            self.error = "Failed to save: \(error.localizedDescription)"
        }
    }

    /// Discards the current import.
    func discardCurrentImport() {
        guard let current = currentImport else { return }
        importService.discardImport(current)
        pendingImports.removeAll { $0.id == current.id }
        resetCurrent()
    }

    private func resetCurrent() {
        currentImport = nil
        ocrResult = nil
        editTitle = ""
        editContent = ""
    }
}
