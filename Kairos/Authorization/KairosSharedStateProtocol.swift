import FamilyControls

/// Dependency-injection seam over `KairosSharedState` for the Authorization layer.
/// Conforming to this protocol is the only surface area managers need, making them
/// fully testable without a real App Group.
protocol KairosSharedStateProtocol: AnyObject {
    var authorizationGranted: Bool { get set }
    var generalSelection: FamilyActivitySelection? { get set }
    var novelSelection: FamilyActivitySelection? { get set }
    var onboardingCompleted: Bool { get set }
}
