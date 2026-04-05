import Foundation

// MARK: - UnlockAction

/// The action the shield extension should take when the secondary (unlock) button is pressed.
public enum UnlockAction: Sendable, Equatable {
    /// Conditions not met — keep the shield visible and do nothing.
    case deny

    /// Clear the shield and restart monitoring.
    case unlock
}

// MARK: - ShieldUnlockResolver

/// Pure function namespace that determines whether an unlock should be allowed.
///
/// All logic is deterministic given the same inputs — no side effects, fully testable.
/// Follows the safe-default principle: any missing timestamp results in `.deny`.
public enum ShieldUnlockResolver {

    // MARK: - Public Interface

    /// Resolves the unlock action for the current shield state.
    ///
    /// - Parameters:
    ///   - mode: The currently active `KairosMode`.
    ///   - sleepFocusOffTimestamp: When Sleep Focus turned off (morning mode).
    ///   - lastShieldTimestamp: When the shield was last activated (cooldown modes).
    ///   - currentTime: The point in time to evaluate against. Defaults to `Date()`.
    /// - Returns: The `UnlockAction` the extension should perform.
    public static func resolve(
        mode: KairosMode,
        sleepFocusOffTimestamp: Date?,
        lastShieldTimestamp: Date?,
        currentTime: Date = Date()
    ) -> UnlockAction {
        switch mode {
        case .morning:
            return resolveMorning(
                sleepFocusOffTimestamp: sleepFocusOffTimestamp,
                currentTime: currentTime
            )

        case .normal:
            return resolveCooldown(
                lastShieldTimestamp: lastShieldTimestamp,
                currentTime: currentTime
            )

        case .night:
            // Night quota mode: shields are per-group locks. No user-initiated unlock.
            return .deny
        }
    }

    // MARK: - Private Resolvers

    private static func resolveMorning(
        sleepFocusOffTimestamp: Date?,
        currentTime: Date
    ) -> UnlockAction {
        guard let sleepOffAt = sleepFocusOffTimestamp else { return .deny }

        let elapsed = currentTime.timeIntervalSince(sleepOffAt)
        let threshold = Double(KairosTime.morningLockMinutes) * 60
        return elapsed >= threshold ? .unlock : .deny
    }

    private static func resolveCooldown(
        lastShieldTimestamp: Date?,
        currentTime: Date
    ) -> UnlockAction {
        guard let shieldAt = lastShieldTimestamp else { return .deny }

        let elapsed = currentTime.timeIntervalSince(shieldAt)
        let threshold = Double(KairosTime.cooldownMinutes) * 60
        return elapsed >= threshold ? .unlock : .deny
    }
}
