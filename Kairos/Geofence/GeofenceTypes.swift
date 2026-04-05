import Foundation

// MARK: - Identifiers

/// Namespace for well-known geofence region identifiers.
enum GeofenceIdentifier {
    static let home = "kairos.home"
}

// MARK: - GeofenceEvent

/// A domain event produced by the location monitoring system.
enum GeofenceEvent: Sendable {
    case regionEntered(identifier: String)
    case regionExited(identifier: String)
    case unknown(identifier: String)
    case unsatisfied(identifier: String)
}

// MARK: - GeofenceAction

/// The state mutation that should be applied after a geofence event.
enum GeofenceAction: Equatable, Sendable {
    case setAtHome(Bool)
    case noOp
}

// MARK: - GeofenceConfiguration

/// Immutable value type describing a monitored circular region.
struct GeofenceConfiguration: Sendable {
    let identifier: String
    let radius: Double

    init(
        identifier: String = GeofenceIdentifier.home,
        radius: Double = 100.0
    ) {
        self.identifier = identifier
        self.radius = radius
    }
}
