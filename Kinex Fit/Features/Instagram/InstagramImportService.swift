import Foundation
import UIKit

/// Handles importing pending Instagram shares from the App Group shared container.
@MainActor
final class InstagramImportService {
    private let appGroupStorage: AppGroupStorage
    private let ocrService: OCRService
    private let workoutRepository: WorkoutRepository
    private let syncEngine: SyncEngine

    init(
        appGroupStorage: AppGroupStorage,
        ocrService: OCRService,
        workoutRepository: WorkoutRepository,
        syncEngine: SyncEngine
    ) {
        self.appGroupStorage = appGroupStorage
        self.ocrService = ocrService
        self.workoutRepository = workoutRepository
        self.syncEngine = syncEngine
    }

    /// Checks if there are pending imports from the share extension.
    var hasPendingImports: Bool {
        appGroupStorage.hasPendingImports
    }

    /// Returns all pending imports.
    func pendingImports() -> [PendingInstagramImport] {
        appGroupStorage.pendingImports()
    }

    /// Processes a pending import: loads image, runs OCR, returns result for review.
    func processImport(_ item: PendingInstagramImport) async throws -> OCRResponse {
        guard let fileName = item.imageFileName else {
            throw OCRError.imageProcessingFailed
        }

        let imageURL = appGroupStorage.imageURL(fileName: fileName)
        guard let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData) else {
            throw OCRError.imageProcessingFailed
        }

        return try await ocrService.processImage(image)
    }

    /// Saves an imported workout and removes it from the pending queue.
    func saveImportedWorkout(title: String, content: String, importItem: PendingInstagramImport) throws {
        let workout = Workout.new(
            title: title,
            content: content,
            source: .instagram
        )

        try workoutRepository.save(workout)
        syncEngine.enqueue(
            operation: .create,
            entity: .workout,
            entityId: workout.id,
            object: workout
        )

        // Clean up the pending import
        if let fileName = importItem.imageFileName {
            appGroupStorage.removeImage(fileName: fileName)
        }
        appGroupStorage.removePendingImport(id: importItem.id)
    }

    /// Discards a pending import without saving.
    func discardImport(_ item: PendingInstagramImport) {
        if let fileName = item.imageFileName {
            appGroupStorage.removeImage(fileName: fileName)
        }
        appGroupStorage.removePendingImport(id: item.id)
    }
}
