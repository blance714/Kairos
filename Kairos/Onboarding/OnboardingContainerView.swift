import SwiftUI

/// Root container for the multi-step onboarding flow.
/// Uses a paged TabView driven by `OnboardingViewModel.currentStep`.
struct OnboardingContainerView: View {

    @State private var viewModel: OnboardingViewModel
    @State private var geofenceManager: GeofenceManager
    private let onComplete: (() -> Void)?

    // MARK: - Init

    init(
        onComplete: (() -> Void)? = nil
    ) {
        _viewModel = State(wrappedValue: OnboardingViewModel())
        _geofenceManager = State(wrappedValue: GeofenceManager())
        self.onComplete = onComplete
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            progressIndicator
            pageContent
            navigationBar
        }
        .background(Color(.systemBackground))
        .onChange(of: viewModel.isCompleted) { _, isCompleted in
            if isCompleted {
                onComplete?()
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ForEach(OnboardingViewModel.Step.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step.rawValue <= viewModel.currentStep.rawValue ? Color.blue : Color(.systemGray5))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.currentStep)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Page Content

    @ViewBuilder
    private var pageContent: some View {
        TabView(selection: .constant(viewModel.currentStep.rawValue)) {
            WelcomeStepView()
                .tag(OnboardingViewModel.Step.welcome.rawValue)
            AuthorizationStepView(authManager: viewModel.authManager)
                .tag(OnboardingViewModel.Step.authorization.rawValue)
            AppSelectionStepView(selectionManager: viewModel.selectionManager)
                .tag(OnboardingViewModel.Step.appSelection.rawValue)
            HomeLocationStepView(
                geofenceManager: geofenceManager,
                onSkip: { viewModel.advance() }
            )
            .tag(OnboardingViewModel.Step.homeLocation.rawValue)
            FocusFilterStepView()
                .tag(OnboardingViewModel.Step.focusFilter.rawValue)
            CompletionStepView(onFinish: { viewModel.advance() })
                .tag(OnboardingViewModel.Step.complete.rawValue)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        VStack(spacing: 12) {
            stepLabel
            nextButton
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(.regularMaterial)
    }

    private var stepLabel: some View {
        Text(viewModel.currentStep.localizedTitle)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var nextButton: some View {
        Button(action: { viewModel.advance() }) {
            Text("下一步")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.canAdvance())
        // Hide on the completion step — CompletionStepView owns its own CTA
        .opacity(viewModel.currentStep == .complete ? 0 : 1)
    }
}

// MARK: - Step Localized Title

private extension OnboardingViewModel.Step {
    var localizedTitle: String {
        switch self {
        case .welcome:       return "欢迎"
        case .authorization: return "授权"
        case .appSelection:  return "选择应用"
        case .homeLocation:  return "家庭位置"
        case .focusFilter:   return "睡眠专注"
        case .complete:      return "完成"
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingContainerView()
}
