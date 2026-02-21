import Foundation

/// Builder for multipart/form-data request bodies, used for image uploads.
struct MultipartFormData: Sendable {
    let boundary: String
    private var parts: [Part] = []

    init(boundary: String = UUID().uuidString) {
        self.boundary = boundary
    }

    // MARK: - Adding Parts

    /// Adds a text field.
    mutating func addField(name: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        parts.append(Part(
            name: name,
            data: data,
            fileName: nil,
            mimeType: nil
        ))
    }

    /// Adds a file (e.g., an image).
    mutating func addFile(name: String, fileName: String, mimeType: String, data: Data) {
        parts.append(Part(
            name: name,
            data: data,
            fileName: fileName,
            mimeType: mimeType
        ))
    }

    /// Adds a JPEG image with a default field name of "image".
    mutating func addJPEGImage(data: Data, name: String = "image", fileName: String = "photo.jpg") {
        addFile(name: name, fileName: fileName, mimeType: "image/jpeg", data: data)
    }

    // MARK: - Build

    /// Builds the complete multipart form data body.
    func build() -> Data {
        var body = Data()
        let boundaryPrefix = "--\(boundary)\r\n"

        for part in parts {
            body.append(Data(boundaryPrefix.utf8))

            if let fileName = part.fileName, let mimeType = part.mimeType {
                body.append(Data("Content-Disposition: form-data; name=\"\(part.name)\"; filename=\"\(fileName)\"\r\n".utf8))
                body.append(Data("Content-Type: \(mimeType)\r\n\r\n".utf8))
            } else {
                body.append(Data("Content-Disposition: form-data; name=\"\(part.name)\"\r\n\r\n".utf8))
            }

            body.append(part.data)
            body.append(Data("\r\n".utf8))
        }

        body.append(Data("--\(boundary)--\r\n".utf8))
        return body
    }
}

// MARK: - Private

private struct Part: Sendable {
    let name: String
    let data: Data
    let fileName: String?
    let mimeType: String?
}
