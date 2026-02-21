import SwiftUI

/// The Profile tab — displays user info, subscription status, settings, and sign out.
struct ProfileView: View {
    @Environment(\.appEnvironment) private var environment
    @State private var viewModel: ProfileViewModel?

    var body: some View {
        Group {
            if let viewModel {
                ProfileContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ProfileViewModel(environment: environment)
            }
        }
    }
}

// MARK: - Profile Content

private struct ProfileContent: View {
    @Bindable var viewModel: ProfileViewModel

    var body: some View {
        NavigationStack {
            List {
                // User header
                userSection

                // Subscription
                subscriptionSection

                // Quotas
                quotaSection

                // App info
                appSection

                // Sign out
                signOutSection
            }
            .navigationTitle("Profile")
            .refreshable {
                await viewModel.refreshProfile()
            }
            .sheet(isPresented: $viewModel.showPaywall) {
                PaywallView()
            }
            .confirmationDialog(
                "Sign Out",
                isPresented: $viewModel.showSignOutConfirmation
            ) {
                Button("Sign Out", role: .destructive) {
                    Task { await viewModel.signOut() }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") { viewModel.error = nil }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Sections

    private var userSection: some View {
        Section {
            HStack(spacing: AppTheme.spacingLG) {
                Image(systemName: AppTheme.TabIcon.profile)
                    .font(.system(size: 48))
                    .foregroundStyle(.accent)

                VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                    Text(viewModel.userName)
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(viewModel.userEmail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !viewModel.provider.isEmpty {
                        Text("Signed in with \(viewModel.provider)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.vertical, AppTheme.spacingSM)
        }
    }

    private var subscriptionSection: some View {
        Section("Subscription") {
            HStack {
                Text("Current Plan")
                Spacer()
                Text(viewModel.tierName)
                    .fontWeight(.semibold)
                    .padding(.horizontal, AppTheme.spacingMD)
                    .padding(.vertical, AppTheme.spacingXS)
                    .background(.accent.opacity(0.2))
                    .cornerRadius(AppTheme.cornerRadiusSM)
            }

            if viewModel.isFreeUser {
                Button {
                    viewModel.showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: AppTheme.Icon.star)
                            .foregroundStyle(.accent)
                        Text("Upgrade Plan")
                        Spacer()
                        Image(systemName: AppTheme.Icon.chevronRight)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var quotaSection: some View {
        Section("Usage This Month") {
            HStack {
                Label("OCR Scans", systemImage: AppTheme.Icon.ocrScan)
                Spacer()
                Text(viewModel.scanUsageText)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            HStack {
                Label("AI Operations", systemImage: "sparkles")
                Spacer()
                Text(viewModel.aiUsageText)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    private var appSection: some View {
        Section("App") {
            NavigationLink {
                SettingsView()
            } label: {
                Label("Settings", systemImage: AppTheme.Icon.settings)
            }

            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text(AppConfig.versionDisplay)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var signOutSection: some View {
        Section {
            Button(role: .destructive) {
                viewModel.showSignOutConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isSigningOut {
                        ProgressView()
                    } else {
                        Label("Sign Out", systemImage: AppTheme.Icon.signOut)
                    }
                    Spacer()
                }
            }
            .disabled(viewModel.isSigningOut)
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .withPreviewEnvironment()
}
