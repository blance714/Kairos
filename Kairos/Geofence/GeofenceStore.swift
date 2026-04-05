import Foundation

// MARK: - GeofenceStore Protocol

/// Abstraction over the persistent storage layer for geofence state.
/// Conforming types include `KairosSharedState` (production) and
/// `MockGeofenceStore` (tests).
protocol GeofenceStore: AnyObject, Sendable {
    var isAtHome: Bool { get set }
    var homeLatitude: Double { get set }
    var homeLongitude: Double { get set }
    var homeLocationSet: Bool { get set }
}

// MARK: - GeofenceActionApplicator

/// Applies a `GeofenceAction` to any `GeofenceStore`.
/// Keeps the applicator separate from both the handler and the store,
/// following single-responsibility.
enum GeofenceActionApplicator {
    static func apply(_ action: GeofenceAction, to store: some GeofenceStore) {
        switch action {
        case .setAtHome(let value):
            store.isAtHome = value
        case .noOp:
            break
        }
    }
}
