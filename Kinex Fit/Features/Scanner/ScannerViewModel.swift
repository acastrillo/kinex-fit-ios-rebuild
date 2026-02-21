import Foundation
import PhotosUI
import SwiftUI

/// Manages the scanner tab: camera capture, photo picker, quota checks, and OCR upload.
@Observable
@MainActor
final class ScannerViewModel {
    // MARK: - State

    var selectedPhoto: PhotosPickerItem?
    var capturedImage: UIImage?
    var isProcessing = false
    var error: String?
    var ocrResult: OCRResponse?
    var showPhotoPicker = false
    var showCamera = false
    var showResult = false

    // MARK: - Dependencies

    private let ocrService: OCRService
    private let workoutRepository: WorkoutRepository
    private let syncEngine: SyncEngine
    private let environment: AppEnvironment

    init(
        ocrService: OCRService,
        workoutRepository: WorkoutRepository,
        syncEngine: SyncEngine,
        environment: AppEnvironment
    ) {
        self.ocrService = ocrService
        self.workoutRepository = workoutRepository
        self.syncEngine = syncEngine
        self.environment = environment
    }

    // MARK: - Computed

    var canScan: Bool {
        environment.currentUser?.canScan ?? false
    }

    var remainingScans: Int {
        environment.currentUser?.remainingScans ?? 0
    }

    var quotaText: String {
        guard let user = environment.currentUser else { return "" }
        if user.subscriptionTier.isUnlimited { return "Unlimited scans" }
        return "\(user.remainingScans) of \(user.subscriptionTier.scanQuotaLimit) scans remaining"
    }

    // MARK: - Actions

    /// Called when a photo is selected from the picker.
    func handleSelectedPhoto() async {
        guard let item = selectedPhoto else { return }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                error = "Failed to load the selected image."
                return
            }
            capturedImage = image
            await processImage(image)
        } catch {
            self.error = "Failed to load image: \(error.localizedDescription)"
        }
    }

    /// Called with a camera-captured image.
    func handleCapturedImage(_ image: UIImage) async {
        capturedImage = image
        await processImage(image)
    }

    /// Processes an image through the OCR backend.
    private func processImage(_ image: UIImage) async {
        guard canScan else {
            error = OCRError.quotaExceeded.localizedDescription
            return
        }

        isProcessing = true
        error = nil

        do {
            let result = try await ocrService.processImage(image)
            ocrResult = result
            showResult = true
        } catch {
            self.error = error.localizedDescription
        }

        isProcessing = false
    }

    /// Saves the OCR result as a new workout.
    func saveAsWorkout(title: String, content: String) {
        let workout = Workout.new(
            title: title,
            content: content,
            source: .ocr
        )

        do {
            try workoutRepository.save(workout)
            syncEngine.enqueue(
                operation: .create,
                entity: .workout,
                entityId: workout.id,
                object: workout
            )

            // Increment scan quota locally
            if var user = environment.currentUser {
                user.scanQuotaUsed += 1
                try? environment.userRepository.save(user)
                environment.currentUser = user
            }

            reset()
        } catch {
            self.error = "Failed to save workout: \(error.localizedDescription)"
        }
    }

    /// Resets the scanner state for a new scan.
    func reset() {
        capturedImage = nil
        ocrResult = nil
        selectedPhoto = nil
        showResult = false
        error = nil
    }
}
