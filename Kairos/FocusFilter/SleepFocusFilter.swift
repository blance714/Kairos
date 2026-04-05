import AppIntents
import KairosKit
import os

// MARK: - KairosSharedState + SleepFocusStoring

extension KairosSharedState: SleepFocusStoring {}

// MARK: - SleepFocusFilter

/// Focus Filter intent that activates or deactivates sleep mode when the
/// system Sleep Focus toggles.
///
/// The system calls `perform()` for both activation and deactivation.
/// The direction of the transition is determined by the current shared state.
/// All state-transition logic lives in `SleepFocusTransition` so it can be
/// unit-tested independently of `AppIntents`.
struct SleepFocusFilter: SetFocusFilterIntent {

    static let title: LocalizedStringResource = "Kairos 睡眠模式"
    static let description: LocalizedStringResource = "在睡眠专注模式期间自动管理应用"

    private static let logger = Logger(
        subsystem: "org.blance.kairos",
        category: "SleepFocusFilter"
    )

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "Kairos 睡眠模式",
            subtitle: "在睡眠专注模式期间自动管理应用"
        )
    }

    func perform() async throws -> some IntentResult {
        let state = KairosSharedState.shared
        let transition = SleepFocusTransition(wasActive: state.sleepFocusActive)
        let writer = SleepFocusStateWriter(store: state)
        let outcome = writer.apply(transition: transition)

        Self.logger.info(
            "Sleep Focus transition — active: \(outcome.active), offTimestamp: \(String(describing: outcome.offTimestamp))"
        )

        return .result()
    }
}
