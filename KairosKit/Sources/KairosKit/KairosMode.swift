import Foundation

/// All possible modes the app can be in.
public enum KairosMode: String, Sendable, CaseIterable {
    /// After sleep focus turns off (from night mode), apps locked until 1 hour passes.
    case morning

    /// Default daytime mode: 15-min usage -> 30-min cooldown cycle.
    /// Also covers night-window behavior when the user has been active recently.
    case normal

    /// Night quota mode: at home + night window + 30 min inactive.
    /// General apps get 20 min, novel apps get 45 min. Each group locks independently.
    case night

    public var displayName: String {
        switch self {
        case .morning: "早晨模式"
        case .normal: "普通模式"
        case .night: "晚间模式"
        }
    }

    public var iconName: String {
        switch self {
        case .morning: "sunrise.fill"
        case .normal: "sun.max.fill"
        case .night: "moon.fill"
        }
    }
}
