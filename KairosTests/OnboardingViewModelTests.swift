import Foundation
import KairosKit
import Testing
@testable import Kairos

// MARK: - OnboardingViewModel Step Order Tests

@Suite("OnboardingViewModel - step order")
struct OnboardingViewModelStepOrderTests {

    @Test("Step enum cases appear in the correct order")
    func stepCasesInCorrectOrder() {
        let cases = OnboardingViewModel.Step.allCases
        #expect(cases[0] == .welcome)
        #expect(cases[1] == .authorization)
        #expect(cases[2] == .appSelection)
        #expect(cases[3] == .homeLocation)
        #expect(cases[4] == .focusFilter)
        #expect(cases[5] == .complete)
    }

    @Test("Step raw values are sequential integers starting at 0")
    func stepRawValuesSequential() {
        for (index, step) in OnboardingViewModel.Step.allCases.enumerated() {
            #expect(step.rawValue == index)
        }
    }

    @Test("Total step count is 6")
    func stepCount() {
        #expect(OnboardingViewModel.Step.allCases.count == 6)
    }
}

// MARK: - OnboardingViewModel Initial State Tests

@Suite("OnboardingViewModel - initial state")
struct OnboardingViewModelInitialStateTests {

    @Test("Initial step is .welcome")
    @MainActor
    func initialStepIsWelcome() {
        let fakeState = FakeSharedState()
        let authManager = AuthorizationManager(sharedState: fakeState)
        let selectionManager = AppSelectionManager(sharedState: fakeState)
        let viewModel = OnboardingViewModel(
            authManager: authManager,
            selectionManager: selectionManager,
            sharedState: fakeState
        )
        #expect(viewModel.currentStep == .welcome)
    }

    @Test("isCompleted starts as false")
    @MainActor
    func isCompletedStartsFalse() {
        let fakeState = FakeSharedState()
        let authManager = AuthorizationManager(sharedState: fakeState)
        let selectionManager = AppSelectionManager(sharedState: fakeState)
        let viewModel = OnboardingViewModel(
            authManager: authManager,
            selectionManager: selectionManager,
            sharedState: fakeState
        )
        #expect(viewModel.isCompleted == false)
    }
}

// MARK: - OnboardingViewModel canAdvance Tests

@Suite("OnboardingViewModel - canAdvance()")
struct OnboardingViewModelCanAdvanceTests {

    @Test("canAdvance() returns true on welcome step")
    @MainActor
    func canAdvanceWelcomeAlwaysTrue() {
        let fakeState = FakeSharedState()
        let viewModel = OnboardingViewModel(
            authManager: AuthorizationManager(sharedState: fakeState),
            selectionManager: AppSelectionManager(sharedState: fakeState),
            sharedState: fakeState
        )
        #expect(viewModel.currentStep == .welcome)
        #expect(viewModel.canAdvance() == true)
    }

    @Test("canAdvance() returns false on authorization step when not approved")
    @MainActor
    func canAdvanceAuthorizationFalseWhenNotApproved() {
        let fakeState = FakeSharedState()
        fakeState.authorizationGranted = false
        let authManager = AuthorizationManager(sharedState: fakeState)
        let viewModel = OnboardingViewModel(
            authManager: authManager,
            selectionManager: AppSelectionManager(sharedState: fakeState),
            sharedState: fakeState
        )
        // Advance to authorization step
        viewModel.advance()
        #expect(viewModel.currentStep == .authorization)
        #expect(viewModel.canAdvance() == false)
    }

    @Test("canAdvance() returns true on authorization step when approved")
    @MainActor
    func canAdvanceAuthorizationTrueWhenApproved() {
        let fakeState = FakeSharedState()
        fakeState.authorizationGranted = true
        let authManager = AuthorizationManager(sharedState: fakeState)
        let viewModel = OnboardingViewModel(
            authManager: authManager,
            selectionManager: AppSelectionManager(sharedState: fakeState),
            sharedState: fakeState
        )
        viewModel.advance()
        #expect(viewModel.currentStep == .authorization)
        #expect(viewModel.canAdvance() == true)
    }

    @Test("canAdvance() returns false on appSelection step when no selections made")
    @MainActor
    func canAdvanceAppSelectionFalseWhenNoSelections() {
        let fakeState = FakeSharedState()
        fakeState.authorizationGranted = true
        let authManager = AuthorizationManager(sharedState: fakeState)
        let selectionManager = AppSelectionManager(sharedState: fakeState)
        let viewModel = OnboardingViewModel(
            authManager: authManager,
            selectionManager: selectionManager,
            sharedState: fakeState
        )
        // Advance past welcome and authorization to appSelection
        viewModel.advance() // → authorization
        viewModel.advance() // → appSelection
        #expect(viewModel.currentStep == .appSelection)
        #expect(viewModel.canAdvance() == false)
    }

    @Test("canAdvance() returns true on homeLocation step (always optional)")
    @MainActor
    func canAdvanceHomeLocationAlwaysTrue() {
        let fakeState = FakeSharedState()
        fakeState.authorizationGranted = true
        let authManager = AuthorizationManager(sharedState: fakeState)
        let selectionManager = AppSelectionManager(sharedState: fakeState)
        let viewModel = OnboardingViewModel(
            authManager: authManager,
            selectionManager: selectionManager,
            sharedState: fakeState
        )
        // Force the step directly to test canAdvance in isolation
        viewModel.forceStep(.homeLocation)
        #expect(viewModel.currentStep == .homeLocation)
        #expect(viewModel.canAdvance() == true)
    }

    @Test("canAdvance() returns true on focusFilter step (informational only)")
    @MainActor
    func canAdvanceFocusFilterAlwaysTrue() {
        let fakeState = FakeSharedState()
        let viewModel = OnboardingViewModel(
            authManager: AuthorizationManager(sharedState: fakeState),
            selectionManager: AppSelectionManager(sharedState: fakeState),
            sharedState: fakeState
        )
        viewModel.forceStep(.focusFilter)
        #expect(viewModel.currentStep == .focusFilter)
        #expect(viewModel.canAdvance() == true)
    }

    @Test("canAdvance() returns true on complete step")
    @MainActor
    func canAdvanceCompleteAlwaysTrue() {
        let fakeState = FakeSharedState()
        let viewModel = OnboardingViewModel(
            authManager: AuthorizationManager(sharedState: fakeState),
            selectionManager: AppSelectionManager(sharedState: fakeState),
            sharedState: fakeState
        )
        viewModel.forceStep(.complete)
        #expect(viewModel.currentStep == .complete)
        #expect(viewModel.canAdvance() == true)
    }
}

// MARK: - OnboardingViewModel advance() Tests

@Suite("OnboardingViewModel - advance()")
struct OnboardingViewModelAdvanceTests {

    @Test("advance() moves from welcome to authorization")
    @MainActor
    func advanceFromWelcomeToAuthorization() {
        let fakeState = FakeSharedState()
        let viewModel = OnboardingViewModel(
            authManager: AuthorizationManager(sharedState: fakeState),
            selectionManager: AppSelectionManager(sharedState: fakeState),
            sharedState: fakeState
        )
        #expect(viewModel.currentStep == .welcome)
        viewModel.advance()
        #expect(viewModel.currentStep == .authorization)
    }

    @Test("advance() moves from authorization to appSelection when approved")
    @MainActor
    func advanceFromAuthorizationToAppSelection() {
        let fakeState = FakeSharedState()
        fakeState.authorizationGranted = true
        let viewModel = OnboardingViewModel(
            authManager: AuthorizationManager(sharedState: fakeState),
            selectionManager: AppSelectionManager(sharedState: fakeState),
            sharedState: fakeState
        )
        viewModel.advance() // welcome → authorization
        viewModel.advance() // authorization → appSelection
        #expect(viewModel.currentStep == .appSelection)
    }

    @Test("advance() does not move from authorization when not approved")
    @MainActor
    func advanceBlockedOnAuthorizationWhenNotApproved() {
        let fakeState = FakeSharedState()
        fakeState.authorizationGranted = false
        let viewModel = OnboardingViewModel(
            authManager: AuthorizationManager(sharedState: fakeState),
            selectionManager: AppSelectionManager(sharedState: fakeState),
            sharedState: fakeState
        )
        viewModel.advance() // welcome → authorization
        viewModel.advance() // should be blocked
        #expect(viewModel.currentStep == .authorization)
    }

    @Test("advance() from complete sets isCompleted to true")
    @MainActor
    func advanceFromCompleteSetsIsCompleted() {
        let fakeState = FakeSharedState()
        let viewModel = OnboardingViewModel(
            authManager: AuthorizationManager(sharedState: fakeState),
            selectionManager: AppSelectionManager(sharedState: fakeState),
            sharedState: fakeState
        )
        viewModel.forceStep(.complete)
        #expect(viewModel.isCompleted == false)
        viewModel.advance()
        #expect(viewModel.isCompleted == true)
    }

    @Test("advance() from complete marks onboardingCompleted in shared state")
    @MainActor
    func advanceFromCompletePersistsOnboardingCompleted() {
        let fakeState = FakeSharedState()
        let viewModel = OnboardingViewModel(
            authManager: AuthorizationManager(sharedState: fakeState),
            selectionManager: AppSelectionManager(sharedState: fakeState),
            sharedState: fakeState
        )
        viewModel.forceStep(.complete)
        viewModel.advance()
        #expect(fakeState.onboardingCompleted == true)
    }

    @Test("advance() traverses all steps in order")
    @MainActor
    func advanceTraversesAllStepsInOrder() {
        let fakeState = FakeSharedState()
        // Pre-approve and pre-populate selections so each step allows advance
        fakeState.authorizationGranted = true
        let selectionManager = AppSelectionManager(sharedState: fakeState)
        let viewModel = OnboardingViewModel(
            authManager: AuthorizationManager(sharedState: fakeState),
            selectionManager: selectionManager,
            sharedState: fakeState
        )

        let expectedSteps: [OnboardingViewModel.Step] = [
            .welcome, .authorization, .appSelection, .homeLocation, .focusFilter, .complete
        ]

        for (index, expected) in expectedSteps.enumerated() {
            #expect(viewModel.currentStep == expected, "Step \(index) should be \(expected)")
            if index < expectedSteps.count - 1 {
                // For appSelection we must bypass the hasBothSelections guard
                if viewModel.currentStep == .appSelection {
                    viewModel.forceStep(.homeLocation)
                } else {
                    viewModel.advance()
                }
            }
        }
    }
}

// MARK: - OnboardingViewModel Shared State Tests

@Suite("OnboardingViewModel - shared state interaction")
struct OnboardingViewModelSharedStateTests {

    @Test("isCompleted stays false until complete step is advanced past")
    @MainActor
    func isCompletedFalseUntilFinalAdvance() {
        let fakeState = FakeSharedState()
        let viewModel = OnboardingViewModel(
            authManager: AuthorizationManager(sharedState: fakeState),
            selectionManager: AppSelectionManager(sharedState: fakeState),
            sharedState: fakeState
        )
        viewModel.forceStep(.focusFilter)
        viewModel.advance() // → complete
        #expect(viewModel.isCompleted == false)
        #expect(fakeState.onboardingCompleted == false)
    }

    @Test("onboardingCompleted is false before finishing")
    @MainActor
    func onboardingCompletedFalseByDefault() {
        let fakeState = FakeSharedState()
        let viewModel = OnboardingViewModel(
            authManager: AuthorizationManager(sharedState: fakeState),
            selectionManager: AppSelectionManager(sharedState: fakeState),
            sharedState: fakeState
        )
        _ = viewModel
        #expect(fakeState.onboardingCompleted == false)
    }
}
