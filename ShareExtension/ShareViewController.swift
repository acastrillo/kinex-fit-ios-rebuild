import UIKit
import Social
import UniformTypeIdentifiers

/// Share extension that captures images shared from Instagram (or other apps)
/// and saves them to the App Group shared container for the main app to process.
///
/// **Setup required in Xcode:**
/// 1. Add a new Share Extension target named "ShareExtension"
/// 2. Enable the App Group capability (group.com.kinexfit.shared) on both targets
/// 3. Configure NSExtensionActivationRule in the extension's Info.plist
class ShareViewController: UIViewController {

    private let appGroupSuiteName = "group.com.kinexfit.shared"
    private let pendingImportsKey = "pendingInstagramImports"

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handleIncomingContent()
    }

    // MARK: - Content Handling

    private func handleIncomingContent() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            close(success: false)
            return
        }

        Task {
            var savedAny = false

            for item in extensionItems {
                guard let attachments = item.attachments else { continue }

                for provider in attachments {
                    if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                        if let imageData = await loadImageData(from: provider) {
                            saveToAppGroup(imageData: imageData, sourceURL: nil)
                            savedAny = true
                        }
                    } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                        if let url = await loadURL(from: provider) {
                            // Save the URL for the main app to handle
                            saveToAppGroup(imageData: nil, sourceURL: url.absoluteString)
                            savedAny = true
                        }
                    }
                }
            }

            close(success: savedAny)
        }
    }

    // MARK: - Data Loading

    private func loadImageData(from provider: NSItemProvider) async -> Data? {
        await withCheckedContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                continuation.resume(returning: data)
            }
        }
    }

    private func loadURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.url.identifier) { item, _ in
                continuation.resume(returning: item as? URL)
            }
        }
    }

    // MARK: - App Group Storage

    private func saveToAppGroup(imageData: Data?, sourceURL: String?) {
        guard let defaults = UserDefaults(suiteName: appGroupSuiteName) else { return }

        let id = UUID().uuidString
        var imageFileName: String?

        // Save image to shared container if provided
        if let imageData = imageData {
            let fileName = "\(id).jpg"
            if let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupSuiteName
            ) {
                let imagesDir = containerURL.appendingPathComponent("PendingImages", isDirectory: true)
                try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
                let fileURL = imagesDir.appendingPathComponent(fileName)
                try? imageData.write(to: fileURL)
                imageFileName = fileName
            }
        }

        // Build the pending import record
        let importRecord: [String: Any] = [
            "id": id,
            "imageFileName": imageFileName as Any,
            "sourceURL": sourceURL as Any,
            "capturedAt": ISO8601DateFormatter().string(from: Date())
        ]

        // Append to existing pending imports
        var existingImports = defaults.array(forKey: pendingImportsKey) as? [[String: Any]] ?? []
        existingImports.append(importRecord)

        // Encode as JSON and save (matching PendingInstagramImport Codable format)
        let pendingItems = existingImports.compactMap { dict -> [String: Any]? in
            return dict
        }

        // Use Codable-compatible storage
        struct PendingItem: Codable {
            let id: String
            let imageFileName: String?
            let sourceURL: String?
            let capturedAt: Date
        }

        var codableItems = (defaults.data(forKey: pendingImportsKey))
            .flatMap { try? JSONDecoder().decode([PendingItem].self, from: $0) } ?? []

        codableItems.append(PendingItem(
            id: id,
            imageFileName: imageFileName,
            sourceURL: sourceURL,
            capturedAt: Date()
        ))

        if let data = try? JSONEncoder().encode(codableItems) {
            defaults.set(data, forKey: pendingImportsKey)
        }
    }

    // MARK: - Completion

    private func close(success: Bool) {
        if success {
            extensionContext?.completeRequest(returningItems: nil)
        } else {
            extensionContext?.cancelRequest(withError: NSError(
                domain: "com.kinexfit.share",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to process shared content"]
            ))
        }
    }
}
