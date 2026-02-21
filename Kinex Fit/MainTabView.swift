import SwiftUI

/// The main 5-tab navigation structure of the authenticated app.
struct MainTabView: View {
    @Environment(\.appEnvironment) private var environment
    @State private var selectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Home
            HomeTabPlaceholder()
                .tabItem {
                    Label("Home", systemImage: AppTheme.TabIcon.home)
                }
                .tag(Tab.home)

            // Tab 2: Library
            LibraryTabPlaceholder()
                .tabItem {
                    Label("Library", systemImage: AppTheme.TabIcon.library)
                }
                .tag(Tab.library)

            // Tab 3: Scan
            ScanTabPlaceholder()
                .tabItem {
                    Label("Scan", systemImage: AppTheme.TabIcon.scan)
                }
                .tag(Tab.scan)

            // Tab 4: Metrics
            MetricsTabPlaceholder()
                .tabItem {
                    Label("Metrics", systemImage: AppTheme.TabIcon.metrics)
                }
                .tag(Tab.metrics)

            // Tab 5: Profile
            ProfileTabPlaceholder()
                .tabItem {
                    Label("Profile", systemImage: AppTheme.TabIcon.profile)
                }
                .tag(Tab.profile)
        }
    }
}

// MARK: - Tab Enum

extension MainTabView {
    enum Tab: Int, Hashable {
        case home
        case library
        case scan
        case metrics
        case profile
    }
}

// MARK: - Placeholder Tabs (replaced in Phase 3+)

private struct HomeTabPlaceholder: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Home",
                systemImage: AppTheme.TabIcon.home,
                description: Text("Dashboard coming soon")
            )
            .navigationTitle("Home")
        }
    }
}

private struct LibraryTabPlaceholder: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Library",
                systemImage: AppTheme.TabIcon.library,
                description: Text("Your workouts will appear here")
            )
            .navigationTitle("Library")
        }
    }
}

private struct ScanTabPlaceholder: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Scan",
                systemImage: AppTheme.Icon.ocrScan,
                description: Text("OCR scanner coming soon")
            )
            .navigationTitle("Scan")
        }
    }
}

private struct MetricsTabPlaceholder: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Metrics",
                systemImage: AppTheme.TabIcon.metrics,
                description: Text("Body metrics tracking coming soon")
            )
            .navigationTitle("Metrics")
        }
    }
}

private struct ProfileTabPlaceholder: View {
    @Environment(\.appEnvironment) private var environment

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.spacingLG) {
                if let user = environment.currentUser {
                    VStack(spacing: AppTheme.spacingSM) {
                        Image(systemName: AppTheme.TabIcon.profile)
                            .font(.system(size: 56))
                            .foregroundStyle(.accent)

                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(user.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(user.subscriptionTier.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, AppTheme.spacingMD)
                            .padding(.vertical, AppTheme.spacingXS)
                            .background(.accent.opacity(0.2))
                            .cornerRadius(AppTheme.cornerRadiusSM)
                    }
                    .padding(.top, AppTheme.spacingXXL)
                }

                Spacer()

                Text(AppConfig.versionDisplay)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, AppTheme.spacingLG)
            }
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .withPreviewEnvironment()
}
