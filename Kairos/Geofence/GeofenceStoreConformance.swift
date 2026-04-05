import KairosKit

/// Retroactive conformance — `KairosSharedState` already implements all
/// required `GeofenceStore` properties; this wires it into the geofence DI seam.
extension KairosSharedState: @retroactive GeofenceStore {}
