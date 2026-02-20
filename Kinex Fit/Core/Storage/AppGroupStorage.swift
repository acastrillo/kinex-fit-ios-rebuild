import Foundation

/// Manages shared data between the main app and the Share Extension via App Group.
final class AppGroupStorage: Sendable {
    static let suiteName = "group.com.kinexfit.shared"
    private static let pendingImportsKey = "pendingInstagramImports"

    private let defaults: UserDefaults
    private let containerURL: URL

    init() {
        guard let defaults = UserDefaults(suiteName: Self.suiteName) else {
            fatalError("AppGroupStorage: Failed to access App Group UserDefaults. Ensure App Group '\(Self.suiteName)' is configured in both targets.")
        }
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.suiteName
        ) else {
            fatalError("AppGroupStorage: Failed to access App Group container. Ensure App Group '\(Self.suiteName)' is configured.")
        }

        self.defaults = defaults
        self.containerURL = url
    }

    // MARK: - Pending Instagram Imports

    func pendingImports() -> [PendingInstagramImport] {
        guard let data = defaults.data(forKey: Self.pendingImportsKey) else { return [] }
        return (try? JSONDecoder().decode([PendingInstagramImport].self, from: data)) ?? []
    }

    func savePendingImport(_ item: PendingInstagramImport) {
        var imports = pendingImports()
        imports.append(item)
        if let data = try? JSONEncoder().encode(imports) {
            defaults.set(data, forKey: Self.pendingImportsKey)
        }
    }

    func removePendingImport(id: String) {
        var imports = pendingImports()
        imports.removeAll { $0.id == id }
        if let data = try? JSONEncoder().encode(imports) {
            defaults.set(data, forKey: Self.pendingImportsKey)
        }
    }

    func clearPendingImports() {
        defaults.removeObject(forKey: Self.pendingImportsKey)
    }

    var hasPendingImports: Bool {
        !pendingImports().isEmpty
    }

    // MARK: - File Storage

    /// URL for storing shared image files.
    var imagesDirectory: URL {
        let url = containerURL.appendingPathComponent("PendingImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func imageURL(fileName: String) -> URL {
        imagesDirectory.appendingPathComponent(fileName)
    }

    func saveImage(_ data: Data, fileName: String) throws {
        let url = imageURL(fileName: fileName)
        try data.write(to: url)
    }

    func removeImage(fileName: String) {
        let url = imageURL(fileName: fileName)
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Pending Import Model

struct PendingInstagramImport: Codable, Identifiable, Sendable {
    let id: String
    let imageFileName: String?
    let sourceURL: String?
    let capturedAt: Date
}
