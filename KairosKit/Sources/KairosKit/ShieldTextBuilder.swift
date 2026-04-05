import Foundation

// MARK: - ShieldText

/// Immutable value type describing all user-visible text on a shield overlay.
public struct ShieldText: Sendable, Equatable {
    public let title: String
    public let subtitle: String
    public let primaryButtonLabel: String
    /// `nil` means the secondary button should not be shown.
    public let secondaryButtonLabel: String?

    public init(
        title: String,
        subtitle: String,
        primaryButtonLabel: String,
        secondaryButtonLabel: String?
    ) {
        self.title = title
        self.subtitle = subtitle
        self.primaryButtonLabel = primaryButtonLabel
        self.secondaryButtonLabel = secondaryButtonLabel
    }
}

// MARK: - ShieldTextBuilder

/// Pure function namespace that constructs `ShieldText` from mode and timestamps.
///
/// All logic is deterministic given the same inputs — no side effects, fully testable.
public enum ShieldTextBuilder {

    // MARK: - Public Interface

    /// Builds the complete set of display text for a shield overlay.
    ///
    /// - Parameters:
    ///   - mode: The currently active `KairosMode`.
    ///   - sleepFocusOffTimestamp: When Sleep Focus turned off (used for morning countdown).
    ///   - lastShieldTimestamp: When the shield was last activated (used for cooldown countdown).
    ///   - currentTime: The point in time for which text is being built. Defaults to `Date()`.
    /// - Returns: A fully populated `ShieldText` value.
    public static func build(
        mode: KairosMode,
        sleepFocusOffTimestamp: Date?,
        lastShieldTimestamp: Date?,
        currentTime: Date = Date()
    ) -> ShieldText {
        switch mode {
        case .morning:
            return buildMorning(
                sleepFocusOffTimestamp: sleepFocusOffTimestamp,
                currentTime: currentTime
            )

        case .normal:
            return buildCooldown(
                title: "休息一下 🧘",
                lastShieldTimestamp: lastShieldTimestamp,
                currentTime: currentTime
            )

        case .nightCooldown:
            return buildCooldown(
                title: "休息一下 🌙",
                lastShieldTimestamp: lastShieldTimestamp,
                currentTime: currentTime
            )

        case .nightQuota:
            return ShieldText(
                title: "额度使用中 ⏳",
                subtitle: "请注意剩余时间",
                primaryButtonLabel: "好的",
                secondaryButtonLabel: nil
            )

        case .nightExhausted:
            return ShieldText(
                title: "今日额度已用完 🌙",
                subtitle: "明天见！",
                primaryButtonLabel: "好的",
                secondaryButtonLabel: nil
            )
        }
    }

    // MARK: - Private Builders

    private static func buildMorning(
        sleepFocusOffTimestamp: Date?,
        currentTime: Date
    ) -> ShieldText {
        let unlockAt = sleepFocusOffTimestamp.map {
            $0.addingTimeInterval(Double(KairosTime.morningLockMinutes) * 60)
        }
        let subtitle = remainingSubtitle(unlockAt: unlockAt, currentTime: currentTime)

        return ShieldText(
            title: "早安 ☀️",
            subtitle: subtitle,
            primaryButtonLabel: "好的",
            secondaryButtonLabel: "查看状态"
        )
    }

    private static func buildCooldown(
        title: String,
        lastShieldTimestamp: Date?,
        currentTime: Date
    ) -> ShieldText {
        let unlockAt = lastShieldTimestamp.map {
            $0.addingTimeInterval(Double(KairosTime.cooldownMinutes) * 60)
        }
        let subtitle = remainingSubtitle(unlockAt: unlockAt, currentTime: currentTime)

        return ShieldText(
            title: title,
            subtitle: subtitle,
            primaryButtonLabel: "好的",
            secondaryButtonLabel: "查看状态"
        )
    }

    // MARK: - Subtitle Formatting

    /// Returns "M:SS 后可用" when time remains, or "即将可用" when the unlock time
    /// has already passed or `unlockAt` is `nil`.
    private static func remainingSubtitle(unlockAt: Date?, currentTime: Date) -> String {
        guard let unlockAt else { return "即将可用" }

        let remaining = unlockAt.timeIntervalSince(currentTime)
        guard remaining > 0 else { return "即将可用" }

        return formatRemaining(seconds: remaining)
    }

    /// Formats a positive `TimeInterval` (in seconds) as "M:SS 后可用".
    ///
    /// Examples:
    /// - 3600 s (60 min) → "1:00 后可用"
    /// - 1800 s (30 min) → "0:30 后可用"
    /// -   90 s (1.5 min) → "0:01 后可用"  (ceiling to whole minutes)
    private static func formatRemaining(seconds: TimeInterval) -> String {
        // Ceiling to the nearest whole minute so users see at least "0:01" rather than "0:00".
        let totalMinutes = Int(ceil(seconds / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes)) 后可用"
        } else {
            return "0:\(String(format: "%02d", minutes)) 后可用"
        }
    }
}
