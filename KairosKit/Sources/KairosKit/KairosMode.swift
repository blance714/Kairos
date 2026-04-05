import Foundation

/// All possible modes the app can be in.
public enum KairosMode: String, Sendable, CaseIterable {
    /// After sleep focus turns off, apps locked until 1 hour passes.
    case morning

    /// Default daytime mode: 15-min usage → 30-min cooldown cycle.
    case normal

    /// Night mode: same 15/30 cycle but can transition to quota mode.
    case nightCooldown

    /// Night mode with quota: limited total usage (20min general / 45min novel).
    case nightQuota

    /// Night quota exhausted: all managed apps locked until next day.
    case nightExhausted

    public var displayName: String {
        switch self {
        case .morning: "早晨模式"
        case .normal: "普通模式"
        case .nightCooldown: "晚间冷却"
        case .nightQuota: "晚间额度"
        case .nightExhausted: "额度已用完"
        }
    }

    public var iconName: String {
        switch self {
        case .morning: "sunrise.fill"
        case .normal: "sun.max.fill"
        case .nightCooldown: "moon.fill"
        case .nightQuota: "hourglass"
        case .nightExhausted: "moon.zzz.fill"
        }
    }
}
