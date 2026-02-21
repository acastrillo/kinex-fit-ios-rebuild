import SwiftUI

/// The root view of the app. Routes between authentication, onboarding, and the main app.
struct RootView: View {
    @Environment(\.appEnvironment) private var environment
    @State private var viewModel: RootViewModel?

    var body: some View {
        Group {
            if let viewModel {
                RootContent(viewModel: viewModel, environment: environment)
            } else {
                launchScreen
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = RootViewModel(environment: environment)
            }
        }
    }

    private var launchScreen: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: AppTheme.spacingMD) {
                Image(systemName: AppTheme.Icon.workout)
                    .font(.system(size: 56))
                    .foregroundStyle(.accent)
                ProgressView()
            }
        }
    }
}

// MARK: - Root Content

private struct RootContent: View {
    @Bindable var viewModel: RootViewModel
    let environment: AppEnvironment

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                launchScreen

            case .signedOut:
                AuthView()
                    .transition(.opacity)

            case .onboarding:
                // Placeholder — will be replaced in Phase 8
                OnboardingPlaceholder {
                    viewModel.completeOnboarding()
                }
                .transition(.opacity)

            case .signedIn:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(AppTheme.defaultAnimation, value: viewModel.state)
        .task {
            await viewModel.checkAuthState()
        }
        .onChange(of: environment.currentUser) { _, _ in
            viewModel.handleUserChange()
        }
    }

    private var launchScreen: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: AppTheme.spacingMD) {
                Image(systemName: AppTheme.Icon.workout)
                    .font(.system(size: 56))
                    .foregroundStyle(.accent)
                ProgressView()
            }
        }
    }
}

// MARK: - Onboarding Placeholder

/// Temporary placeholder for onboarding. Will be replaced in Phase 8.
private struct OnboardingPlaceholder: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.spacingXL) {
            Spacer()

            Image(systemName: AppTheme.Icon.workout)
                .font(.system(size: 72))
                .foregroundStyle(.accent)

            Text("Welcome to Kinex Fit!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your workout companion for tracking, scanning, and improving your fitness journey.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.spacingXXL)

            Spacer()

            Button {
                onComplete()
            } label: {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, AppTheme.spacingXL)
            .padding(.bottom, AppTheme.spacingXXL)
        }
    }
}

// MARK: - Preview

#Preview("Signed Out") {
    RootView()
        .environment(\.appEnvironment, {
            let env = AppEnvironment.preview()
            env.currentUser = nil
            return env
        }())
        .preferredColorScheme(.dark)
}

#Preview("Signed In") {
    RootView()
        .withPreviewEnvironment()
}
