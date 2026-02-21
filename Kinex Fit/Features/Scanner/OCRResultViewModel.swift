import Foundation

/// Manages the editable state of an OCR result before saving.
@Observable
@MainActor
final class OCRResultViewModel {
    var title: String
    var content: String

    init(result: OCRResponse) {
        self.title = result.title ?? "Scanned Workout"
        self.content = result.content
    }

    var canSave: Bool {
        !title.isBlank && !content.isBlank
    }
}
