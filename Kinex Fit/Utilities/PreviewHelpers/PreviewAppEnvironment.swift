import SwiftUI

/// Convenience extension for wrapping views in a preview-ready environment.
extension View {
    /// Wraps the view with a populated preview `AppEnvironment` and dark mode.
    func withPreviewEnvironment() -> some View {
        self
            .environment(\.appEnvironment, .preview())
            .preferredColorScheme(.dark)
    }
}
