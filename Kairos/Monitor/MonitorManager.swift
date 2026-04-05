import DeviceActivity
import FamilyControls
import Foundation
import KairosKit
import ManagedSettings
import Observation
import os

// MARK: - MonitorManager

/// App-side orchestrator that coordinates `DeviceActivityCenter` scheduling and
/// `ManagedSettingsStore` shield activation for the current `KairosMode`.
///
/// This class lives on the main actor and must never be used from extension targets.
/// Extensions interact with the system via `KairosSharedState` and `ManagedSettings`.
@Observable
@MainActor
final class MonitorManager {

    // MARK: - Observable State

    private(set) var currentMode: KairosMode = .normal

    // MARK: - Dependencies

    private let sharedState: KairosSharedState
    private let center: DeviceActivityCenter
    private let logger = Logger(subsystem: "org.blance.kairos", category: "MonitorManager")

    // MARK: - Init

    /// Production initializer using the real singletons.
    convenience init() {
        self.init(sharedState: .shared, center: DeviceActivityCenter())
    }

    /// Testable initializer accepting injected dependencies.
    init(sharedState: KairosSharedState, center: DeviceActivityCenter) {
        self.sharedState = sharedState
        self.center = center
    }

    // MARK: - Public API

    /// Re-resolve the current mode from shared state and update monitoring accordingly.
    func refreshMode() {
        let input = ModeResolverInput(
            currentTime: Date(),
            sleepFocusActive: sharedState.sleepFocusActive,
            sleepFocusOffTimestamp: sharedState.sleepFocusOffTimestamp,
            isAtHome: sharedState.isAtHome,
            lastShieldTimestamp: sharedState.lastShieldTimestamp,
            nightQuotaActivated: sharedState.nightQuotaActivated,
            nightQuotaDate: sharedState.nightQuotaDate,
            nightQuotaExhausted: sharedState.nightQuotaExhausted
        )
        let resolved = ModeResolver.resolve(input)
        currentMode = resolved
        sharedState.currentMode = resolved
        logger.info("Mode refreshed: \(resolved.rawValue)")
        startMonitoring()
    }

    /// Stop any running monitors, then start fresh monitoring for the current mode.
    func startMonitoring() {
        stopMonitoring()
        activateShieldIfNeeded()

        let general = sharedState.generalSelection ?? FamilyActivitySelection()
        let novel = sharedState.novelSelection ?? FamilyActivitySelection()

        // nightQuota needs two separate DeviceActivity monitors — one per quota group —
        // so that the extension receives distinct threshold events for each.
        if currentMode == .nightQuota {
            startNightQuotaMonitoring(
                general: general,
                novel: novel
            )
            return
        }

        guard let (schedule, events) = ActivityScheduleBuilder.build(
            for: currentMode,
            generalTokens: general.applicationTokens,
            novelTokens: novel.applicationTokens,
            generalCategories: general.categoryTokens,
            novelCategories: novel.categoryTokens
        ) else {
            logger.info("No monitoring required for mode: \(self.currentMode.rawValue)")
            return
        }

        let activityName = deviceActivityName(for: currentMode)
        do {
            try center.startMonitoring(activityName, during: schedule, events: events)
            logger.info("Started monitoring '\(activityName.rawValue)' for mode: \(self.currentMode.rawValue)")
        } catch {
            logger.error("Failed to start monitoring for \(self.currentMode.rawValue): \(error)")
        }
    }

    /// Start two separate monitors for nightQuota mode — one for each quota group.
    private func startNightQuotaMonitoring(
        general: FamilyActivitySelection,
        novel: FamilyActivitySelection
    ) {
        let nightStart = DateComponents(hour: KairosTime.nightStartHour, minute: 0)
        let nightEnd = DateComponents(hour: 5, minute: 59)
        let schedule = DeviceActivitySchedule(intervalStart: nightStart, intervalEnd: nightEnd, repeats: true)

        let generalEvent = DeviceActivityEvent(
            applications: general.applicationTokens,
            categories: general.categoryTokens,
            webDomains: [],
            threshold: DateComponents(minute: KairosTime.generalQuotaMinutes)
        )
        let novelEvent = DeviceActivityEvent(
            applications: novel.applicationTokens,
            categories: novel.categoryTokens,
            webDomains: [],
            threshold: DateComponents(minute: KairosTime.novelQuotaMinutes)
        )

        do {
            try center.startMonitoring(.nightQuotaGeneral, during: schedule, events: [.generalQuota: generalEvent])
            logger.info("Started nightQuotaGeneral monitor")
        } catch {
            logger.error("Failed to start nightQuotaGeneral: \(error)")
        }

        do {
            try center.startMonitoring(.nightQuotaNovel, during: schedule, events: [.novelQuota: novelEvent])
            logger.info("Started nightQuotaNovel monitor")
        } catch {
            logger.error("Failed to start nightQuotaNovel: \(error)")
        }
    }

    /// Stop all active Kairos monitoring activities.
    func stopMonitoring() {
        center.stopMonitoring([
            .normalMode,
            .nightCooldown,
            .nightQuotaGeneral,
            .nightQuotaNovel,
        ])
        logger.info("Stopped all active monitors")
    }

    // MARK: - Private Helpers

    /// Activate shields up-front for modes that lock apps immediately,
    /// rather than waiting for a usage threshold.
    private func activateShieldIfNeeded() {
        // Clear all existing shields first so we start from a clean state.
        clearAllShields()

        let general = sharedState.generalSelection ?? FamilyActivitySelection()
        let novel = sharedState.novelSelection ?? FamilyActivitySelection()
        let allApps = general.applicationTokens.union(novel.applicationTokens)
        let allCategories = general.categoryTokens.union(novel.categoryTokens)

        switch currentMode {
        case .morning:
            let store = ManagedSettingsStore(named: .morningLock)
            store.shield.applications = allApps
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(allCategories)
            logger.info("Morning lock shield activated for \(allApps.count) apps")

        case .nightExhausted:
            let store = ManagedSettingsStore(named: .quotaLock)
            store.shield.applications = allApps
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(allCategories)
            logger.info("Quota-exhausted lock shield activated for \(allApps.count) apps")

        case .normal, .nightCooldown, .nightQuota:
            // Shields for these modes are activated reactively by the monitor extension
            // when usage thresholds are reached.
            break
        }
    }

    /// Remove all Kairos-managed shields.
    private func clearAllShields() {
        for name in [ManagedSettingsStore.Name.morningLock,
                     .cooldownLock,
                     .quotaLock] {
            let store = ManagedSettingsStore(named: name)
            store.shield.applications = nil
            store.shield.applicationCategories = nil
        }
    }

    /// Map a mode to its corresponding `DeviceActivityName`.
    /// Note: `.nightQuota` is handled separately via `startNightQuotaMonitoring(_:_:)`
    /// and will never reach this helper; the fallback returns `.nightQuotaGeneral`.
    private func deviceActivityName(for mode: KairosMode) -> DeviceActivityName {
        switch mode {
        case .morning, .nightExhausted:
            // These modes don't monitor; unreachable in practice because
            // ActivityScheduleBuilder returns nil for them.
            return .normalMode
        case .normal:
            return .normalMode
        case .nightCooldown:
            return .nightCooldown
        case .nightQuota:
            return .nightQuotaGeneral
        }
    }
}
