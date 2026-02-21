import Foundation
import UIKit

/// Handles OCR image upload to the backend and returns extracted text.
@MainActor
final class OCRService {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    /// Uploads an image for OCR processing and returns the extracted content.
    /// - Parameters:
    ///   - image: The image to process.
    ///   - compressionQuality: JPEG compression (0.0–1.0). Default 0.8.
    /// - Returns: An `OCRResponse` with title and content.
    func processImage(_ image: UIImage, compressionQuality: CGFloat = 0.8) async throws -> OCRResponse {
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            throw OCRError.imageProcessingFailed
        }

        var form = MultipartFormData()
        form.addJPEGImage(data: imageData)

        do {
            let response: OCRResponse = try await apiClient.sendMultipart(
                form,
                path: APIEndpoints.OCR.process
            )

            guard !response.content.isBlank else {
                throw OCRError.noTextDetected
            }

            return response
        } catch let error as APIError {
            if error.isNetworkError {
                throw OCRError.networkError(error.localizedDescription)
            }
            throw OCRError.uploadFailed(error.localizedDescription)
        }
    }
}
