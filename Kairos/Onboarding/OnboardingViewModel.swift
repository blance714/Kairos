import Foundation
import KairosKit
import Observation
import os

/// Drives the multi-step onboarding flow, enforcing step-gating rules
/// and persisting completion state when the user finishes.
@Observable
@MainActor
final class OnboardingViewModel {

    // MARK: - Step

    enum Step: Int, CaseIterable {
        case welcome = 0
        case authorization
        case appSelection
        case homeLocation
        case focusFilter
        case complete
    }

    // MARK: - Observable Properties

    private(set) var currentStep: Step = .welcome
    private(set) var isCompleted: Bool = false

    // MARK: - Dependencies

    let authManager: AuthorizationManager
    let selectionManager: AppSelectionManager

    private let sharedState: any KairosSharedStateProtocol
    private let logger = Logger(subsystem: "org.blance.kairos", category: "Onboarding")

    // MARK: - Init

    /// Production initializer — uses real singletons.
    convenience init() {
        self.init(
            authManager: AuthorizationManager(),
            selectionManager: AppSelectionManager(),
            sharedState: KairosSharedState.shared
        )
    }

    /// Testable initializer — accepts injected dependencies.
    init(
        authManager: AuthorizationManager,
        selectionManager: AppSelectionManager,
        sharedState: any KairosSharedStateProtocol
    ) {
        self.authManager = authManager
        self.selectionManager = selectionManager
        self.sharedState = sharedState
    }

    // MARK: - Navigation

    /// Returns true when the current step's requirements are satisfied.
    func canAdvance() -> Bool {
        switch currentStep {
        case .welcome:
            return true
        case .authorization:
            return authManager.authorizationStatus == .approved
        case .appSelection:
            return selectionManager.hasBothSelections
        case .homeLocation:
            return true
        case .focusFilter:
            return true
        case .complete:
            return true
        }
    }

    /// Advances to the next step when `canAdvance()` is true.
    /// When called on `.complete`, marks onboarding as finished.
    func advance() {
        guard canAdvance() else {
            logger.debug("advance() blocked at step: \(String(describing: self.currentStep))")
            return
        }

        if currentStep == .complete {
            completeOnboarding()
            return
        }

        let nextRaw = currentStep.rawValue + 1
        guard let next = Step(rawValue: nextRaw) else { return }
        currentStep = next
        logger.debug("Advanced to step: \(String(describing: next))")
    }

    // MARK: - Testing Support

    /// Forces the current step to the given value.
    /// Intended for test use only — bypasses normal step-gating.
    func forceStep(_ step: Step) {
        currentStep = step
    }

    // MARK: - Private

    private func completeOnboarding() {
        sharedState.onboardingCompleted = true
        isCompleted = true
        logger.info("Onboarding completed")
    }
}
