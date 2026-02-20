import Foundation

enum WorkoutSource: String, Codable, Sendable {
    case manual
    case ocr
    case instagram
    case imported

    var displayName: String {
        switch self {
        case .manual: "Manual"
        case .ocr: "Scanned"
        case .instagram: "Instagram"
        case .imported: "Imported"
        }
    }
}
