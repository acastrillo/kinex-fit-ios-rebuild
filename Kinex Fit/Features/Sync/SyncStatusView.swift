import SwiftUI

/// Small sync status indicator for use in toolbars or headers.
struct SyncStatusView: View {
    let syncEngine: SyncEngine

    var body: some View {
        HStack(spacing: AppTheme.spacingXS) {
            statusIcon
            statusText
        }
        .font(.caption)
        .foregroundStyle(foregroundColor)
        .animation(AppTheme.quickAnimation, value: syncEngine.status)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch syncEngine.status {
        case .syncing:
            ProgressView()
                .scaleEffect(0.6)
                .frame(width: 14, height: 14)
        default:
            Image(systemName: iconName)
                .font(.caption2)
        }
    }

    @ViewBuilder
    private var statusText: some View {
        switch syncEngine.status {
        case .idle:
            if syncEngine.pendingCount > 0 {
                Text("\(syncEngine.pendingCount) pending")
            }
            // Show nothing when idle with no pending items
        case .syncing:
            Text("Syncing...")
        case .success:
            Text("Synced")
        case .error(let message):
            Text(message)
                .lineLimit(1)
        }
    }

    private var iconName: String {
        switch syncEngine.status {
        case .idle:
            syncEngine.pendingCount > 0 ? "arrow.triangle.2.circlepath" : "checkmark.circle"
        case .syncing:
            "arrow.triangle.2.circlepath"
        case .success:
            "checkmark.circle.fill"
        case .error:
            "exclamationmark.triangle.fill"
        }
    }

    private var foregroundColor: Color {
        switch syncEngine.status {
        case .idle:
            syncEngine.pendingCount > 0 ? .orange : .secondary
        case .syncing:
            .accent
        case .success:
            .green
        case .error:
            .red
        }
    }
}

// MARK: - Toolbar Modifier

extension View {
    /// Adds a sync status indicator to the navigation toolbar.
    func syncStatusToolbar(syncEngine: SyncEngine) -> some View {
        toolbar {
            ToolbarItem(placement: .status) {
                SyncStatusView(syncEngine: syncEngine)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        Text("Content")
            .navigationTitle("Library")
    }
    .withPreviewEnvironment()
}
