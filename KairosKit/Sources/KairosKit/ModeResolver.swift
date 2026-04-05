import Foundation

// MARK: - ModeResolverInput

/// All inputs required to deterministically resolve the current Kairos mode.
///
/// This is a pure value type — create a new instance for each resolution call
/// rather than mutating an existing one.
public struct ModeResolverInput: Sendable {
    /// The point in time for which the mode is being resolved.
    public let currentTime: Date

    /// Whether Sleep Focus is currently active on the device.
    /// When true, the phone is in sleep mode — management is suspended.
    public let sleepFocusActive: Bool

    /// The timestamp when Sleep Focus last turned off.
    /// Used to determine whether the user is still in the morning lock window.
    public let sleepFocusOffTimestamp: Date?

    /// Whether the device is currently inside the home geofence.
    /// Night modes (cooldown, quota, exhausted) only apply at home.
    public let isAtHome: Bool

    /// The timestamp when a shield was last activated.
    /// Reserved for future use by higher-level logic.
    public let lastShieldTimestamp: Date?

    /// Whether the night quota has been activated for the quota date.
    /// Quota activates after `KairosTime.inactivityForQuotaMinutes` of inactivity
    /// during nightCooldown.
    public let nightQuotaActivated: Bool

    /// The date string ("yyyy-MM-dd") for which night quota was activated.
    /// Used to detect stale quota state from a previous day.
    public let nightQuotaDate: String?

    /// Whether the night quota has been fully exhausted for the quota date.
    /// Set externally by the DeviceActivity monitor when usage exceeds limits.
    public let nightQuotaExhausted: Bool

    public init(
        currentTime: Date,
        sleepFocusActive: Bool,
        sleepFocusOffTimestamp: Date?,
        isAtHome: Bool,
        lastShieldTimestamp: Date?,
        nightQuotaActivated: Bool,
        nightQuotaDate: String?,
        nightQuotaExhausted: Bool
    ) {
        self.currentTime = currentTime
        self.sleepFocusActive = sleepFocusActive
        self.sleepFocusOffTimestamp = sleepFocusOffTimestamp
        self.isAtHome = isAtHome
        self.lastShieldTimestamp = lastShieldTimestamp
        self.nightQuotaActivated = nightQuotaActivated
        self.nightQuotaDate = nightQuotaDate
        self.nightQuotaExhausted = nightQuotaExhausted
    }
}

// MARK: - ModeResolver

/// Resolves the current `KairosMode` from a snapshot of app state.
///
/// This is a **pure function** — given the same input it always returns the same
/// output with no side effects. All time-dependent logic is injected via
/// `ModeResolverInput.currentTime`, making the resolver fully testable.
///
/// ## Priority Order (highest to lowest)
/// 1. **normal** — Sleep Focus is currently active (phone sleeping, no management)
/// 2. **morning** — Sleep Focus turned off < 60 min ago (morning lock window)
/// 3. **nightExhausted** — Night window AND at home AND quota exhausted for today
/// 4. **nightQuota** — Night window AND at home AND quota activated for today
/// 5. **nightCooldown** — Night window AND at home
/// 6. **normal** — Default fallback
public enum ModeResolver {

    // MARK: - Night Window Constants

    /// Night mode starts at 22:00 (inclusive).
    private static let nightStartHour = KairosTime.nightStartHour // 22

    /// Night mode ends before 06:00 (exclusive). Hours 0–5 are still "night".
    private static let nightEndHour = 6

    // MARK: - Date Formatter

    /// Reusable formatter for comparing quota dates. Not cached as a stored property
    /// to avoid shared mutable state; DateFormatter creation is fast for this use.
    private static func makeDateFormatter() -> DateFormatter {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt
    }

    // MARK: - Public Interface

    /// Resolves the Kairos mode for the given input snapshot.
    ///
    /// - Parameter input: A fully specified snapshot of current app state.
    /// - Returns: The `KairosMode` that should be active right now.
    public static func resolve(_ input: ModeResolverInput) -> KairosMode {
        // Priority 1: Sleep focus active → phone is sleeping, no management needed
        if input.sleepFocusActive {
            return .normal
        }

        // Priority 2: Morning lock — user just woke up (< 60 min since focus off)
        if isMorningWindowActive(input) {
            return .morning
        }

        // Night modes only apply when within the night window AND at home
        guard isNightWindow(input.currentTime), input.isAtHome else {
            return .normal
        }

        let todayStr = makeDateFormatter().string(from: input.currentTime)
        let quotaIsForToday = input.nightQuotaDate == todayStr

        // Priority 3: Night quota exhausted for today
        if input.nightQuotaExhausted, quotaIsForToday {
            return .nightExhausted
        }

        // Priority 4: Night quota active for today (but not yet exhausted)
        if input.nightQuotaActivated, quotaIsForToday {
            return .nightQuota
        }

        // Priority 5: Night cooldown (home, night window, no quota yet)
        return .nightCooldown
    }

    // MARK: - Private Helpers

    /// Returns `true` if the morning lock window is currently active.
    ///
    /// The window is active when:
    /// - Sleep focus is not currently active (already checked by caller)
    /// - A `sleepFocusOffTimestamp` is recorded
    /// - Less than `KairosTime.morningLockMinutes` have elapsed since that timestamp
    private static func isMorningWindowActive(_ input: ModeResolverInput) -> Bool {
        guard let offTime = input.sleepFocusOffTimestamp else { return false }
        let elapsed = input.currentTime.timeIntervalSince(offTime)
        let morningWindowSeconds = Double(KairosTime.morningLockMinutes) * 60
        return elapsed >= 0 && elapsed < morningWindowSeconds
    }

    /// Returns `true` if `time` falls within the nightly window.
    ///
    /// The night window spans from `nightStartHour` (22:00) through the end of the
    /// day, then continues from midnight through `nightEndHour - 1` (05:59) the next
    /// morning. This captures the real-world pattern where users stay up past midnight.
    private static func isNightWindow(_ time: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: time)
        return hour >= nightStartHour || hour < nightEndHour
    }
}
