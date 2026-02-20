import Foundation

extension String {
    /// Returns the string trimmed of whitespace and newlines.
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whether the string is empty after trimming whitespace.
    var isBlank: Bool {
        trimmed.isEmpty
    }

    /// Truncates the string to a maximum length, adding "..." if truncated.
    func truncated(to maxLength: Int) -> String {
        guard count > maxLength else { return self }
        return String(prefix(maxLength)) + "..."
    }
}
