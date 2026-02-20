import Foundation

extension Date {
    /// Relative time string (e.g., "2 hours ago", "Yesterday").
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Short date string (e.g., "Feb 20, 2026").
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Date and time string (e.g., "Feb 20, 2026 at 3:30 PM").
    var dateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Whether this date is today.
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Whether this date is yesterday.
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Start of the day.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
