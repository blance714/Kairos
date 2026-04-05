@testable import Kairos

/// In-memory geofence store for use in unit tests.
/// No UserDefaults, no App Group, no side effects.
final class MockGeofenceStore: GeofenceStore, @unchecked Sendable {
    var isAtHome: Bool = false
    var homeLatitude: Double = 0.0
    var homeLongitude: Double = 0.0
    var homeLocationSet: Bool = false
}
