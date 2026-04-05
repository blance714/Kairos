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
    /// Night mode only applies at home.
    public let isAtHome: Bool

    /// The timestamp when a shield was last activated.
    /// Reserved for future use by higher-level logic.
    public let lastShieldTimestamp: Date?

    /// Whether the previous mode was `.night` when sleep focus turned on.
    /// Morning mode only triggers if the user was in night mode before sleeping.
    public let wasInNightMode: Bool

    /// The timestamp of the most recent managed app usage.
    /// Used to determine inactivity for night quota transition:
    /// >= 30 min of inactivity -> `.night` (quota mode).
    public let lastManagedAppUsageTimestamp: Date?

    public init(
        currentTime: Date,
        sleepFocusActive: Bool,
        sleepFocusOffTimestamp: Date?,
        isAtHome: Bool,
        lastShieldTimestamp: Date?,
        wasInNightMode: Bool,
        lastManagedAppUsageTimestamp: Date?
    ) {
        self.currentTime = currentTime
        self.sleepFocusActive = sleepFocusActive
        self.sleepFocusOffTimestamp = sleepFocusOffTimestamp
        self.isAtHome = isAtHome
        self.lastShieldTimestamp = lastShieldTimestamp
        self.wasInNightMode = wasInNightMode
        self.lastManagedAppUsageTimestamp = lastManagedAppUsageTimestamp
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
/// 2. **morning** — Sleep Focus turned off < 60 min ago AND was in night mode before
/// 3. **night** — Night window AND at home AND inactive >= 30 min (quota mode)
/// 4. **normal** — Default fallback (includes night window with recent activity)
public enum ModeResolver {

    // MARK: - Night Window Constants

    /// Night mode starts at 22:00 (inclusive).
    private static let nightStartHour = KairosTime.nightStartHour // 22

    /// Night mode ends before 06:00 (exclusive). Hours 0-5 are still "night".
    private static let nightEndHour = 6

    // MARK: - Public Interface

    /// Resolves the Kairos mode for the given input snapshot.
    ///
    /// - Parameter input: A fully specified snapshot of current app state.
    /// - Returns: The `KairosMode` that should be active right now.
    public static func resolve(_ input: ModeResolverInput) -> KairosMode {
        // Priority 1: Sleep focus active -> phone is sleeping, no management needed
        if input.sleepFocusActive {
            return .normal
        }

        // Priority 2: Morning lock — user just woke up from night mode (< 60 min since focus off)
        if isMorningWindowActive(input) {
            return .morning
        }

        // Night mode only applies when within the night window AND at home
        guard isNightWindow(input.currentTime), input.isAtHome else {
            return .normal
        }

        // Priority 3: Night quota mode — inactive for >= 30 min (or never used an app)
        if isInactiveForQuota(input) {
            return .night
        }

        // Priority 4: In night window but recently active — use normal cooldown cycle
        return .normal
    }

    // MARK: - Private Helpers

    /// Returns `true` if the morning lock window is currently active.
    ///
    /// The window is active when:
    /// - Sleep focus is not currently active (already checked by caller)
    /// - The user was in night mode before sleep (`wasInNightMode`)
    /// - A `sleepFocusOffTimestamp` is recorded
    /// - Less than `KairosTime.morningLockMinutes` have elapsed since that timestamp
    private static func isMorningWindowActive(_ input: ModeResolverInput) -> Bool {
        guard input.wasInNightMode else { return false }
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

    /// Returns `true` if the user has been inactive long enough to qualify for night quota.
    ///
    /// When `lastManagedAppUsageTimestamp` is `nil` (no usage recorded), the user is
    /// considered inactive — this handles the case where the user enters the night window
    /// without having used any managed apps.
    private static func isInactiveForQuota(_ input: ModeResolverInput) -> Bool {
        guard let lastUsage = input.lastManagedAppUsageTimestamp else {
            // No usage recorded — user has never used a managed app (or data was cleared).
            // Treat as inactive -> night quota mode.
            return true
        }
        let elapsed = input.currentTime.timeIntervalSince(lastUsage)
        let threshold = Double(KairosTime.inactivityForQuotaMinutes) * 60
        return elapsed >= threshold
    }
}
