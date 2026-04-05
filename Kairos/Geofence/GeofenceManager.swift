import CoreLocation
import KairosKit
import Observation
import os

// MARK: - GeofenceManager

/// Manages a single CLMonitor-based circular geofence for the home location.
///
/// - On region enter → sets `isAtHome = true` in the geofence store.
/// - On region exit  → sets `isAtHome = false` in the geofence store.
///
/// Uses `GeofenceEventHandler` for pure event→action translation so that
/// business logic remains testable without a real device or location.
@Observable
@MainActor
final class GeofenceManager {

    // MARK: - Observable State

    private(set) var isMonitoring: Bool = false
    private(set) var isAtHome: Bool = false

    // MARK: - Private

    private var monitor: CLMonitor?
    private let store: any GeofenceStore
    private let handler: GeofenceEventHandler
    private let configuration: GeofenceConfiguration
    private let logger = Logger(subsystem: "org.blance.kairos", category: "Geofence")

    // MARK: - Init

    init(
        store: any GeofenceStore = KairosSharedState.shared,
        handler: GeofenceEventHandler = GeofenceEventHandler(),
        configuration: GeofenceConfiguration = GeofenceConfiguration()
    ) {
        self.store = store
        self.handler = handler
        self.configuration = configuration
        self.isAtHome = store.isAtHome
    }

    // MARK: - Public API

    /// Start monitoring the home geofence.
    /// Call this once the home location has been saved in `store`.
    func startMonitoring() async {
        guard store.homeLocationSet else {
            logger.warning("Cannot start geofence monitoring: home location not set")
            return
        }

        let center = CLLocationCoordinate2D(
            latitude: store.homeLatitude,
            longitude: store.homeLongitude
        )
        let condition = CLMonitor.CircularGeographicCondition(
            center: center,
            radius: configuration.radius
        )

        let monitor = await CLMonitor(configuration.identifier)
        await monitor.add(condition, identifier: configuration.identifier)
        self.monitor = monitor
        isMonitoring = true
        logger.info("Geofence monitoring started at (\(center.latitude), \(center.longitude)) radius \(self.configuration.radius)m")

        await runEventLoop(monitor: monitor)
    }

    /// Stop monitoring and tear down the CLMonitor.
    func stopMonitoring() async {
        guard let monitor else { return }
        await monitor.remove(configuration.identifier)
        self.monitor = nil
        isMonitoring = false
        logger.info("Geofence monitoring stopped")
    }

    /// Update the home location and restart monitoring if already active.
    func updateHomeLocation(latitude: Double, longitude: Double) async {
        store.homeLatitude = latitude
        store.homeLongitude = longitude
        store.homeLocationSet = true
        logger.info("Home location updated to (\(latitude), \(longitude))")

        if isMonitoring {
            await stopMonitoring()
            await startMonitoring()
        }
    }

    // MARK: - Private

    private func runEventLoop(monitor: CLMonitor) async {
        do {
            for try await event in await monitor.events {
                let geofenceEvent = mapToGeofenceEvent(event, identifier: configuration.identifier)
                let action = handler.handleEvent(geofenceEvent)
                GeofenceActionApplicator.apply(action, to: store)

                if case .setAtHome(let value) = action {
                    isAtHome = value
                    logger.info("isAtHome updated to \(value)")
                }
            }
        } catch {
            logger.error("Geofence event loop error: \(error.localizedDescription)")
        }
    }

    private func mapToGeofenceEvent(
        _ event: CLMonitor.Event,
        identifier: String
    ) -> GeofenceEvent {
        switch event.state {
        case .satisfied:
            return .regionEntered(identifier: identifier)
        case .unsatisfied:
            return .regionExited(identifier: identifier)
        default:
            return .unknown(identifier: identifier)
        }
    }
}
