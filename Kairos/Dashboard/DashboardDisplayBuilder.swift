import Foundation
import KairosKit

// MARK: - DashboardDisplayBuilder

/// Pure function namespace for building user-visible display strings on the Dashboard.
///
/// All functions are deterministic given the same inputs — no side effects, no singletons,
/// fully testable. Time-dependent parameters are injected rather than calling `Date()` directly.
enum DashboardDisplayBuilder {

    // MARK: - Status Message

    /// Returns the primary status line shown beneath the mode name on the Dashboard.
    ///
    /// - Parameter mode: The currently active `KairosMode`.
    /// - Returns: A localized, human-readable status string in Chinese.
    static func statusMessage(for mode: KairosMode) -> String {
        switch mode {
        case .morning:
            return "早晨模式 · 即将可用"
        case .normal:
            return "普通模式 · 正常使用中"
        case .nightCooldown:
            return "晚间冷却 · 使用中"
        case .nightQuota:
            return "晚间额度 · 额度使用中"
        case .nightExhausted:
            return "额度已用完 · 明天见"
        }
    }

    // MARK: - Next Change Description

    /// Returns a human-readable description of when the current mode will change next.
    ///
    /// Returns an empty string for modes where no scheduled change is imminent (e.g. `.normal`).
    ///
    /// - Parameters:
    ///   - mode: The currently active `KairosMode`.
    ///   - sleepFocusOffTimestamp: When Sleep Focus last turned off. Used for morning countdown.
    ///   - lastShieldTimestamp: When the shield was last activated. Used for cooldown countdown.
    ///   - currentTime: The reference point in time. Defaults to `Date()`.
    /// - Returns: A localized description string, or empty string when no change is expected.
    static func nextChangeDescription(
        for mode: KairosMode,
        sleepFocusOffTimestamp: Date?,
        lastShieldTimestamp: Date?,
        currentTime: Date = Date()
    ) -> String {
        switch mode {
        case .morning:
            return morningDescription(
                sleepFocusOffTimestamp: sleepFocusOffTimestamp,
                currentTime: currentTime
            )
        case .normal:
            return ""
        case .nightCooldown:
            return cooldownDescription(
                lastShieldTimestamp: lastShieldTimestamp,
                currentTime: currentTime
            )
        case .nightQuota:
            return "额度消耗中"
        case .nightExhausted:
            return "明天见"
        }
    }

    // MARK: - Private Builders

    private static func morningDescription(
        sleepFocusOffTimestamp: Date?,
        currentTime: Date
    ) -> String {
        guard let offTime = sleepFocusOffTimestamp else {
            return "即将可用"
        }
        let unlockAt = offTime.addingTimeInterval(Double(KairosTime.morningLockMinutes) * 60)
        return remainingDescription(unlockAt: unlockAt, currentTime: currentTime)
    }

    private static func cooldownDescription(
        lastShieldTimestamp: Date?,
        currentTime: Date
    ) -> String {
        guard let shieldTime = lastShieldTimestamp else {
            return "即将可用"
        }
        let unlockAt = shieldTime.addingTimeInterval(Double(KairosTime.cooldownMinutes) * 60)
        return remainingDescription(unlockAt: unlockAt, currentTime: currentTime)
    }

    /// Formats remaining time until `unlockAt` as "X分钟后可用", or "即将可用" when expired.
    private static func remainingDescription(unlockAt: Date, currentTime: Date) -> String {
        let remaining = unlockAt.timeIntervalSince(currentTime)
        guard remaining > 0 else {
            return "即将可用"
        }
        let minutes = Int(ceil(remaining / 60))
        return "\(minutes)分钟后可用"
    }
}
