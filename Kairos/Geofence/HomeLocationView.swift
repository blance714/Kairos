import CoreLocation
import KairosKit
import MapKit
import os
import SwiftUI

// MARK: - HomeLocationView

/// SwiftUI view for viewing and setting the home location used by geofencing.
///
/// - Shows a map centred on the saved home location (or current location if none saved).
/// - "使用当前位置" button saves the device's current coordinates.
/// - Displays a status label reflecting whether a location has been saved.
struct HomeLocationView: View {

    // MARK: - State

    @State private var viewModel: HomeLocationViewModel

    // MARK: - Init

    init(
        manager: GeofenceManager,
        locationProvider: any CurrentLocationProviding = CoreLocationProvider()
    ) {
        _viewModel = State(
            wrappedValue: HomeLocationViewModel(
                manager: manager,
                locationProvider: locationProvider
            )
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                mapSection
                controlSection
            }
            .navigationTitle("家庭位置")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Map

    private var mapSection: some View {
        MapReader { proxy in
            Map(position: $viewModel.cameraPosition) {
                if let coordinate = viewModel.homeCoordinate {
                    Annotation("家", coordinate: coordinate) {
                        Image(systemName: "house.fill")
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(.blue, in: Circle())
                    }
                }
                UserAnnotation()
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .onTapGesture { position in
                if let coordinate = proxy.convert(position, from: .local) {
                    Task { await viewModel.setHomeLocation(coordinate) }
                }
            }
        }
    }

    // MARK: - Controls

    private var controlSection: some View {
        VStack(spacing: 12) {
            statusLabel
            Text("点击地图选择位置，或使用下方按钮获取当前位置")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            useCurrentLocationButton
        }
        .padding(20)
        .background(.regularMaterial)
    }

    private var statusLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.homeLocationSet ? "checkmark.circle.fill" : "location.slash")
                .foregroundStyle(viewModel.homeLocationSet ? .green : .secondary)
            Text(viewModel.statusText)
                .foregroundStyle(viewModel.homeLocationSet ? .primary : .secondary)
                .font(.subheadline)
        }
    }

    private var useCurrentLocationButton: some View {
        Button {
            Task { await viewModel.useCurrentLocation() }
        } label: {
            HStack {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "location.fill")
                }
                Text("使用当前位置")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(viewModel.isSaving)
    }
}

// MARK: - HomeLocationViewModel

@Observable
@MainActor
final class HomeLocationViewModel {

    // MARK: - Observable Properties

    private(set) var homeCoordinate: CLLocationCoordinate2D?
    private(set) var homeLocationSet: Bool = false
    private(set) var isSaving: Bool = false
    var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    // MARK: - Private

    private let manager: GeofenceManager
    private let locationProvider: any CurrentLocationProviding
    private let logger = Logger(subsystem: "org.blance.kairos", category: "HomeLocationView")

    // MARK: - Computed

    var statusText: String {
        homeLocationSet
            ? "已设置家庭位置"
            : "尚未设置家庭位置"
    }

    // MARK: - Init

    init(manager: GeofenceManager, locationProvider: any CurrentLocationProviding) {
        self.manager = manager
        self.locationProvider = locationProvider
        loadSavedLocation()
    }

    // MARK: - Public

    func setHomeLocation(_ coordinate: CLLocationCoordinate2D) async {
        await manager.updateHomeLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        homeCoordinate = coordinate
        homeLocationSet = true
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 500,
                longitudinalMeters: 500
            )
        )
        logger.info("Home location set via map tap: (\(coordinate.latitude), \(coordinate.longitude))")
    }

    func useCurrentLocation() async {
        isSaving = true
        defer { isSaving = false }

        do {
            let coordinate = try await locationProvider.currentCoordinate()
            await manager.updateHomeLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            homeCoordinate = coordinate
            homeLocationSet = true
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: 500,
                    longitudinalMeters: 500
                )
            )
            logger.info("Home location saved: (\(coordinate.latitude), \(coordinate.longitude))")
        } catch {
            logger.error("Failed to obtain current location: \(error.localizedDescription)")
        }
    }

    // MARK: - Private

    private func loadSavedLocation() {
        let store = KairosSharedState.shared
        guard store.homeLocationSet else { return }
        homeLocationSet = true
        let coordinate = CLLocationCoordinate2D(
            latitude: store.homeLatitude,
            longitude: store.homeLongitude
        )
        homeCoordinate = coordinate
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 500,
                longitudinalMeters: 500
            )
        )
    }
}

// MARK: - CurrentLocationProviding

/// Protocol abstracting `CLLocationManager` so the view model can be tested
/// without real location hardware.
protocol CurrentLocationProviding: Sendable {
    func currentCoordinate() async throws -> CLLocationCoordinate2D
}

// MARK: - CoreLocationProvider

/// Production implementation: one-shot location request via `CLLocationManager`.
final class CoreLocationProvider: NSObject, CurrentLocationProviding, CLLocationManagerDelegate, @unchecked Sendable {

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func currentCoordinate() async throws -> CLLocationCoordinate2D {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(throwing: LocationError.unavailable)
                return
            }
            self.continuation = continuation
            self.manager.requestWhenInUseAuthorization()
            self.manager.requestLocation()
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        continuation?.resume(returning: location.coordinate)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

// MARK: - LocationError

enum LocationError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Location services are unavailable."
        }
    }
}
