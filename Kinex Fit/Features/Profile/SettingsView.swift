import SwiftUI

/// Settings screen accessible from the Profile tab.
struct SettingsView: View {
    @Environment(\.appEnvironment) private var environment
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true

    var body: some View {
        List {
            Section("Notifications") {
                Toggle(isOn: $notificationsEnabled) {
                    Label("Push Notifications", systemImage: "bell")
                }

                Toggle(isOn: $hapticFeedbackEnabled) {
                    Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                }
            }

            Section("Data") {
                NavigationLink {
                    syncDetailView
                } label: {
                    HStack {
                        Label("Sync Status", systemImage: AppTheme.Icon.sync)
                        Spacer()
                        SyncStatusView(syncEngine: environment.syncEngine)
                    }
                }
            }

            Section("Support") {
                Link(destination: URL(string: "https://kinexfit.com/support")!) {
                    Label("Help Center", systemImage: AppTheme.Icon.help)
                }

                Link(destination: URL(string: "https://kinexfit.com/privacy")!) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }

                Link(destination: URL(string: "https://kinexfit.com/terms")!) {
                    Label("Terms of Service", systemImage: "doc.text")
                }
            }

            Section("Debug") {
                HStack {
                    Text("Pending Sync Items")
                    Spacer()
                    Text("\(environment.syncEngine.pendingCount)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                HStack {
                    Text("Network")
                    Spacer()
                    Text(environment.networkMonitor.isConnected ? "Connected" : "Offline")
                        .foregroundStyle(environment.networkMonitor.isConnected ? .green : .red)
                }
            }
        }
        .navigationTitle("Settings")
    }

    private var syncDetailView: some View {
        List {
            Section("Status") {
                HStack {
                    Text("Current Status")
                    Spacer()
                    SyncStatusView(syncEngine: environment.syncEngine)
                }

                HStack {
                    Text("Pending Items")
                    Spacer()
                    Text("\(environment.syncEngine.pendingCount)")
                        .monospacedDigit()
                }
            }

            Section("Actions") {
                Button("Process Queue Now") {
                    environment.syncEngine.processQueue()
                }

                Button("Retry Failed Items") {
                    environment.syncEngine.retryFailed()
                }

                Button("Clear Failed Items", role: .destructive) {
                    environment.syncEngine.clearFailed()
                }
            }
        }
        .navigationTitle("Sync Status")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
    .withPreviewEnvironment()
}
