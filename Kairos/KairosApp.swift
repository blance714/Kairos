import KairosKit
import SwiftUI

@main
struct KairosApp: App {

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: - RootView

/// Decides whether to show onboarding or the main dashboard,
/// observing `KairosSharedState` for the onboarding-completion flag.
private struct RootView: View {

    @State private var showOnboarding = !KairosSharedState.shared.onboardingCompleted

    var body: some View {
        if showOnboarding {
            OnboardingContainerView(onComplete: {
                showOnboarding = false
            })
        } else {
            DashboardView()
        }
    }
}
