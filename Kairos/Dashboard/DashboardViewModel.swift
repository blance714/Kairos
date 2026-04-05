import Foundation
import Observation
import KairosKit

// MARK: - DashboardViewModel

/// Observable view model for the Dashboard screen.
///
/// Reads from `KairosSharedState.shared` on `refresh()` and exposes only
/// derived, display-ready values — no raw shared state leaks into the view layer.
@Observable
@MainActor
final class DashboardViewModel {

    // MARK: - Published State

    private(set) var currentMode: KairosMode = .normal
    private(set) var statusMessage: String = ""
    private(set) var nextChangeDescription: String = ""

    // MARK: - Refresh

    /// Re-resolves the active mode from shared state and updates all display strings.
    ///
    /// Call this from `onAppear` and whenever the app returns to the foreground.
    func refresh() {
        let state = KairosSharedState.shared
        let now = Date()

        let input = ModeResolverInput(
            currentTime: now,
            sleepFocusActive: state.sleepFocusActive,
            sleepFocusOffTimestamp: state.sleepFocusOffTimestamp,
            isAtHome: state.isAtHome,
            lastShieldTimestamp: state.lastShieldTimestamp,
            nightQuotaActivated: state.nightQuotaActivated,
            nightQuotaDate: state.nightQuotaDate,
            nightQuotaExhausted: state.nightQuotaExhausted
        )

        let resolvedMode = ModeResolver.resolve(input)

        currentMode = resolvedMode
        statusMessage = DashboardDisplayBuilder.statusMessage(for: resolvedMode)
        nextChangeDescription = DashboardDisplayBuilder.nextChangeDescription(
            for: resolvedMode,
            sleepFocusOffTimestamp: state.sleepFocusOffTimestamp,
            lastShieldTimestamp: state.lastShieldTimestamp,
            currentTime: now
        )
    }
}
