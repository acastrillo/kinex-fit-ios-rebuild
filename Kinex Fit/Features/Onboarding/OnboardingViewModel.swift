import Foundation

/// Manages the multi-step onboarding flow.
@Observable
@MainActor
final class OnboardingViewModel {
    // MARK: - State

    enum Step: Int, CaseIterable {
        case welcome
        case features
        case notifications
        case complete
    }

    var currentStep: Step = .welcome
    var notificationsRequested = false

    // MARK: - Computed

    var isLastStep: Bool {
        currentStep == Step.allCases.last
    }

    var progress: Double {
        Double(currentStep.rawValue) / Double(Step.allCases.count - 1)
    }

    var stepIndex: Int {
        currentStep.rawValue
    }

    // MARK: - Actions

    func nextStep() {
        guard let nextIndex = Step(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = nextIndex
    }

    func previousStep() {
        guard let prevIndex = Step(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prevIndex
    }

    func skipToEnd() {
        currentStep = .complete
    }
}
