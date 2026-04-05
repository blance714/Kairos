//
//  DeviceActivityMonitorExtension.swift
//  KairosMonitor
//
//  Created by blance on 05/04/2026.
//

import DeviceActivity
import FamilyControls
import Foundation
import KairosKit
import ManagedSettings
import os

// MARK: - DeviceActivityMonitorExtension

/// Extension process that reacts to DeviceActivity threshold and interval events.
///
/// This process runs in a sandboxed extension context. It has no access to the main
/// app's classes — all cross-process communication happens through `KairosSharedState`
/// (App Group UserDefaults) and `ManagedSettingsStore` (ScreenTime API).
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let sharedState = KairosSharedState.shared
    private let logger = Logger(subsystem: "org.blance.kairos", category: "Monitor")

    // MARK: - Interval Events

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        logger.info("Interval started for activity: \(activity.rawValue)")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        logger.info("Interval ended for activity: \(activity.rawValue)")
        clearShields(for: activity)
    }

    // MARK: - Threshold Events

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        logger.info("Event reached threshold: \(event.rawValue) in \(activity.rawValue)")

        if event == .usageThreshold {
            handleUsageThreshold()
        } else if event == .generalQuota {
            handleGeneralQuotaReached()
        } else if event == .novelQuota {
            handleNovelQuotaReached()
        } else {
            logger.warning("Unrecognised event name: \(event.rawValue)")
        }
    }

    // MARK: - Warning Events (for future use)

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        logger.debug("Interval will start warning for: \(activity.rawValue)")
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        logger.debug("Interval will end warning for: \(activity.rawValue)")
    }

    override func eventWillReachThresholdWarning(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        logger.debug("Event will reach threshold warning: \(event.rawValue)")
    }

    // MARK: - Threshold Handlers

    /// Fired when the combined usage threshold (normal mode) is reached.
    private func handleUsageThreshold() {
        let mode = sharedState.currentMode
        guard mode == .normal else {
            logger.info("usageThreshold fired but mode is \(mode.rawValue) -- ignoring")
            return
        }

        let general = sharedState.generalSelection
        let novel = sharedState.novelSelection
        let allApps = (general?.applicationTokens ?? []).union(novel?.applicationTokens ?? [])
        let allCategories = (general?.categoryTokens ?? []).union(novel?.categoryTokens ?? [])

        let store = ManagedSettingsStore(named: .cooldownLock)
        store.shield.applications = allApps
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(allCategories)

        sharedState.lastShieldTimestamp = Date()
        sharedState.lastManagedAppUsageTimestamp = Date()
        logger.info("Cooldown lock applied: shielded \(allApps.count) apps")
    }

    /// Fired when the general-app quota is exhausted in night mode.
    private func handleGeneralQuotaReached() {
        let general = sharedState.generalSelection
        let generalApps = general?.applicationTokens ?? []
        let generalCategories = general?.categoryTokens ?? []

        let store = ManagedSettingsStore(named: .quotaLock)
        store.shield.applications = generalApps
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(generalCategories)

        logger.info("General quota exhausted: shielded \(generalApps.count) general apps")
    }

    /// Fired when the novel-app quota is exhausted in night mode.
    private func handleNovelQuotaReached() {
        let novel = sharedState.novelSelection
        let novelApps = novel?.applicationTokens ?? []
        let novelCategories = novel?.categoryTokens ?? []

        // Merge novel apps into the quota lock store (general may already be there).
        let store = ManagedSettingsStore(named: .quotaLock)
        let existing = store.shield.applications ?? []
        store.shield.applications = existing.union(novelApps)

        // Merge novel categories into any categories already set by the general quota handler.
        let existingCategories: Set<ActivityCategoryToken>
        if case .specific(let cats, except: _) = store.shield.applicationCategories {
            existingCategories = cats
        } else {
            existingCategories = []
        }
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(
            existingCategories.union(novelCategories)
        )

        logger.info("Novel quota exhausted: shielded \(novelApps.count) novel apps")
    }

    // MARK: - Shield Cleanup

    /// Clear shields associated with the activity that just ended its interval.
    private func clearShields(for activity: DeviceActivityName) {
        if activity == .normalMode {
            let store = ManagedSettingsStore(named: .cooldownLock)
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            logger.info("Cooldown lock cleared for ended activity: \(activity.rawValue)")
        } else if activity == .nightQuotaGeneral || activity == .nightQuotaNovel {
            let store = ManagedSettingsStore(named: .quotaLock)
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            logger.info("Quota lock cleared for ended activity: \(activity.rawValue)")
        } else {
            logger.warning("Unrecognised activity in intervalDidEnd: \(activity.rawValue)")
        }
    }
}
