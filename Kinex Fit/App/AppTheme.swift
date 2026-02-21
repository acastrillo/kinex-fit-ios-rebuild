import SwiftUI

/// Centralized theme constants for consistent UI styling.
enum AppTheme {

    // MARK: - Colors

    /// Primary accent color (blue).
    static let accentColor = Color.accentColor
    static let destructiveColor = Color.red
    static let successColor = Color.green
    static let warningColor = Color.orange

    /// Background colors.
    static let primaryBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 24
    static let spacingXXL: CGFloat = 32

    // MARK: - Corner Radius

    static let cornerRadiusSM: CGFloat = 8
    static let cornerRadiusMD: CGFloat = 12
    static let cornerRadiusLG: CGFloat = 16

    // MARK: - Animation

    static let defaultAnimation: Animation = .easeInOut(duration: 0.3)
    static let quickAnimation: Animation = .easeInOut(duration: 0.15)
    static let springAnimation: Animation = .spring(response: 0.35, dampingFraction: 0.85)

    // MARK: - Transitions

    static let bannerTransition: AnyTransition = .move(edge: .top).combined(with: .opacity)
    static let sheetTransition: AnyTransition = .move(edge: .bottom).combined(with: .opacity)

    // MARK: - Tab Bar Icons

    enum TabIcon {
        static let home = "house"
        static let library = "books.vertical"
        static let scan = "plus.circle"
        static let metrics = "chart.bar"
        static let profile = "person.circle"
    }

    // MARK: - Common Icons

    enum Icon {
        static let workout = "figure.run.circle"
        static let ocrScan = "doc.text.viewfinder"
        static let camera = "camera"
        static let search = "magnifyingglass"
        static let settings = "gearshape"
        static let help = "questionmark.circle"
        static let signOut = "rectangle.portrait.and.arrow.right"
        static let sync = "arrow.triangle.2.circlepath"
        static let syncDone = "checkmark.circle"
        static let syncError = "exclamationmark.triangle"
        static let delete = "trash"
        static let edit = "pencil"
        static let add = "plus"
        static let close = "xmark"
        static let chevronRight = "chevron.right"
        static let instagram = "camera"
        static let star = "star.fill"
    }
}
