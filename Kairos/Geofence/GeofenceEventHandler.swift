import Foundation

// MARK: - GeofenceEventHandler

/// Pure, stateless transformer: maps a `GeofenceEvent` to a `GeofenceAction`.
///
/// This struct contains no side effects and no dependencies on CoreLocation,
/// making it straightforwardly unit-testable.
struct GeofenceEventHandler: Sendable {

    /// Determine the state change required for the given geofence event.
    func handleEvent(_ event: GeofenceEvent) -> GeofenceAction {
        switch event {
        case .regionEntered(let id):
            return id == GeofenceIdentifier.home ? .setAtHome(true) : .noOp
        case .regionExited(let id):
            return id == GeofenceIdentifier.home ? .setAtHome(false) : .noOp
        case .unknown, .unsatisfied:
            return .noOp
        }
    }
}
