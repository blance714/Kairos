import FamilyControls
import Foundation
import KairosKit
import Observation
import os

/// Manages FamilyControls authorization state for the app.
@Observable
final class AuthorizationManager {

    // MARK: - Properties

    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined

    private let center: AuthorizationCenter
    private let sharedState: any KairosSharedStateProtocol
    private let logger = Logger(subsystem: "org.blance.kairos", category: "Authorization")

    // MARK: - Init

    /// Production initializer — uses the real singletons.
    convenience init() {
        self.init(center: .shared, sharedState: KairosSharedState.shared)
    }

    /// Testable initializer — accepts injected dependencies.
    init(center: AuthorizationCenter = .shared, sharedState: any KairosSharedStateProtocol) {
        self.center = center
        self.sharedState = sharedState
        syncStatus()
    }

    // MARK: - Public

    /// Request Screen Time authorization from the user.
    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            authorizationStatus = .approved
            sharedState.authorizationGranted = true
            logger.info("Screen Time authorization approved")
        } catch {
            authorizationStatus = .denied
            sharedState.authorizationGranted = false
            logger.error("Screen Time authorization failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Private

    /// Sync local status from the shared persisted state.
    private func syncStatus() {
        authorizationStatus = sharedState.authorizationGranted ? .approved : .notDetermined
    }
}
