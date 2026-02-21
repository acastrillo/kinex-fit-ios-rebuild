import SwiftUI

/// Multi-step onboarding flow shown after first sign-in.
struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: viewModel.progress)
                .tint(.accent)
                .padding(.horizontal, AppTheme.spacingLG)
                .padding(.top, AppTheme.spacingSM)

            // Content
            TabView(selection: Binding(
                get: { viewModel.stepIndex },
                set: { _ in }
            )) {
                welcomeStep.tag(0)
                featuresStep.tag(1)
                notificationsStep.tag(2)
                completeStep.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(AppTheme.defaultAnimation, value: viewModel.currentStep)

            // Navigation buttons
            HStack {
                if viewModel.currentStep != .welcome {
                    Button("Back") {
                        viewModel.previousStep()
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if viewModel.currentStep == .complete {
                    Button {
                        onComplete()
                    } label: {
                        Text("Get Started")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        viewModel.nextStep()
                    } label: {
                        Text("Next")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, AppTheme.spacingXL)
            .padding(.bottom, AppTheme.spacingXXL)
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        OnboardingStepView(
            icon: AppTheme.Icon.workout,
            title: "Welcome to Kinex Fit",
            subtitle: "Your personal workout companion for tracking, scanning, and improving your fitness."
        )
    }

    private var featuresStep: some View {
        VStack(spacing: AppTheme.spacingXL) {
            Spacer()

            Text("What You Can Do")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: AppTheme.spacingLG) {
                featureRow(icon: "books.vertical", title: "Save Workouts", description: "Create and organize your workout library")
                featureRow(icon: AppTheme.Icon.ocrScan, title: "Scan Workouts", description: "Take a photo and we'll extract the text")
                featureRow(icon: "chart.bar", title: "Track Metrics", description: "Log and visualize your body weight progress")
                featureRow(icon: AppTheme.Icon.instagram, title: "Import from Instagram", description: "Share workout posts directly to the app")
            }
            .padding(.horizontal, AppTheme.spacingXL)

            Spacer()
        }
    }

    private var notificationsStep: some View {
        OnboardingStepView(
            icon: "bell.badge",
            title: "Stay on Track",
            subtitle: "Enable notifications to get reminders and updates about your fitness journey."
        ) {
            if !viewModel.notificationsRequested {
                Button {
                    NotificationManager.shared.requestPermission()
                    viewModel.notificationsRequested = true
                } label: {
                    Text("Enable Notifications")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, AppTheme.spacingXXL)
            } else {
                Label("Notifications Enabled", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            }
        }
    }

    private var completeStep: some View {
        OnboardingStepView(
            icon: "checkmark.circle",
            title: "You're All Set!",
            subtitle: "Start building your workout library and tracking your progress."
        )
    }

    // MARK: - Helpers

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: AppTheme.spacingMD) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.accent)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Onboarding Step View

private struct OnboardingStepView<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    var content: (() -> Content)?

    init(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        VStack(spacing: AppTheme.spacingXL) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(.accent)

            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.spacingXXL)

            if let content {
                content()
            }

            Spacer()
        }
    }
}

extension OnboardingStepView where Content == EmptyView {
    init(icon: String, title: String, subtitle: String) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.content = nil
    }
}

// MARK: - Preview

#Preview {
    OnboardingView {}
}
