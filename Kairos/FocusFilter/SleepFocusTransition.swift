import Foundation

// MARK: - SleepFocusTransition

/// Pure value type that encodes a single sleep-focus state transition.
///
/// `wasActive` captures whether Sleep Focus was active *before* the `perform()` call.
/// Calling `resolve()` returns the new desired state without touching any external storage,
/// making the logic fully unit-testable.
struct SleepFocusTransition: Sendable {

    /// Whether Sleep Focus was active before this transition.
    let wasActive: Bool

    /// Injectable clock — defaults to `Date.init` in production.
    let now: @Sendable () -> Date

    init(wasActive: Bool, now: @Sendable @escaping () -> Date = { Date() }) {
        self.wasActive = wasActive
        self.now = now
    }

    // MARK: - Result

    struct Outcome: Sendable {
        /// The new value for `sleepFocusActive`.
        let active: Bool
        /// Non-nil only when Sleep Focus just turned OFF.
        let offTimestamp: Date?
    }

    /// Computes the new state without side effects.
    func resolve() -> Outcome {
        if wasActive {
            // Focus is turning OFF
            return Outcome(active: false, offTimestamp: now())
        } else {
            // Focus is turning ON
            return Outcome(active: true, offTimestamp: nil)
        }
    }
}

// MARK: - SleepFocusStoring

/// Minimal interface for the sleep-focus properties of shared state.
/// Production code uses `KairosSharedState`; tests inject `MockSleepFocusStore`.
protocol SleepFocusStoring: AnyObject {
    var sleepFocusActive: Bool { get set }
    var sleepFocusOffTimestamp: Date? { get set }
}

// MARK: - SleepFocusStateWriter

/// Applies a `SleepFocusTransition` outcome to any `SleepFocusStoring` object.
struct SleepFocusStateWriter {

    private let store: any SleepFocusStoring

    init(store: any SleepFocusStoring) {
        self.store = store
    }

    /// Resolves the transition and writes the result into the store.
    /// - Returns: The computed outcome, so callers can log or react without re-resolving.
    @discardableResult
    func apply(transition: SleepFocusTransition) -> SleepFocusTransition.Outcome {
        let outcome = transition.resolve()
        store.sleepFocusActive = outcome.active
        store.sleepFocusOffTimestamp = outcome.offTimestamp
        return outcome
    }
}
