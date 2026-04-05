import Foundation

/// Represents the current FamilyControls authorization state.
public enum AuthorizationStatus: String, CaseIterable, Sendable {
    /// The user has not yet been asked for authorization.
    case notDetermined
    /// The user granted Screen Time authorization.
    case approved
    /// The user denied or revoked Screen Time authorization.
    case denied

    /// Convenience flag — true only when the status is `.approved`.
    public var isAuthorized: Bool {
        self == .approved
    }
}
