import SwiftUI

/// The main 5-tab navigation structure of the authenticated app.
struct MainTabView: View {
    @Environment(\.appEnvironment) private var environment
    @State private var selectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Home
            HomeView()
                .tabItem {
                    Label("Home", systemImage: AppTheme.TabIcon.home)
                }
                .tag(Tab.home)

            // Tab 2: Library
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: AppTheme.TabIcon.library)
                }
                .tag(Tab.library)

            // Tab 3: Scan
            ScannerView()
                .tabItem {
                    Label("Scan", systemImage: AppTheme.TabIcon.scan)
                }
                .tag(Tab.scan)

            // Tab 4: Metrics
            MetricsView()
                .tabItem {
                    Label("Metrics", systemImage: AppTheme.TabIcon.metrics)
                }
                .tag(Tab.metrics)

            // Tab 5: Profile
            ProfileView()
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

// MARK: - Preview

#Preview {
    MainTabView()
        .withPreviewEnvironment()
}
