import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

// MARK: - ActivityScheduleBuilder

/// Pure helper that constructs `DeviceActivitySchedule` and event dictionaries
/// from a given `KairosMode` and app-token sets.
///
/// This type contains no side effects and no dependencies on device state,
/// making it straightforwardly unit-testable.
public enum ActivityScheduleBuilder {

    // MARK: - Public Interface

    /// Build a schedule and event map for the given mode and token sets.
    ///
    /// - Parameters:
    ///   - mode: The mode for which monitoring should be configured.
    ///   - generalTokens: `ApplicationToken` set from the *general* `FamilyActivitySelection`.
    ///   - novelTokens: `ApplicationToken` set from the *novel* `FamilyActivitySelection`.
    ///   - generalCategories: `ActivityCategoryToken` set from the general selection.
    ///   - novelCategories: `ActivityCategoryToken` set from the novel selection.
    /// - Returns: A `(schedule, events)` tuple, or `nil` when no monitoring is
    ///   required for `mode` (`.morning` locks via `ManagedSettingsStore` instead).
    public static func build(
        for mode: KairosMode,
        generalTokens: Set<ApplicationToken>,
        novelTokens: Set<ApplicationToken>,
        generalCategories: Set<ActivityCategoryToken>,
        novelCategories: Set<ActivityCategoryToken>
    ) -> (schedule: DeviceActivitySchedule, events: [DeviceActivityEvent.Name: DeviceActivityEvent])? {
        switch mode {
        case .morning:
            // Apps are locked via ManagedSettingsStore; no usage monitoring required.
            return nil

        case .normal:
            return buildNormal(
                generalTokens: generalTokens,
                novelTokens: novelTokens,
                generalCategories: generalCategories,
                novelCategories: novelCategories
            )

        case .night:
            return buildNightQuota(
                generalTokens: generalTokens,
                novelTokens: novelTokens,
                generalCategories: generalCategories,
                novelCategories: novelCategories
            )
        }
    }

    // MARK: - Private Builders

    private static func buildNormal(
        generalTokens: Set<ApplicationToken>,
        novelTokens: Set<ApplicationToken>,
        generalCategories: Set<ActivityCategoryToken>,
        novelCategories: Set<ActivityCategoryToken>
    ) -> (schedule: DeviceActivitySchedule, events: [DeviceActivityEvent.Name: DeviceActivityEvent]) {
        let schedule = allDaySchedule()
        let combinedApps = generalTokens.union(novelTokens)
        let combinedCategories = generalCategories.union(novelCategories)
        let event = usageThresholdEvent(
            applications: combinedApps,
            categories: combinedCategories
        )
        return (schedule, [.usageThreshold: event])
    }

    private static func buildNightQuota(
        generalTokens: Set<ApplicationToken>,
        novelTokens: Set<ApplicationToken>,
        generalCategories: Set<ActivityCategoryToken>,
        novelCategories: Set<ActivityCategoryToken>
    ) -> (schedule: DeviceActivitySchedule, events: [DeviceActivityEvent.Name: DeviceActivityEvent]) {
        let schedule = nightSchedule()

        let generalEvent = DeviceActivityEvent(
            applications: generalTokens,
            categories: generalCategories,
            webDomains: [],
            threshold: DateComponents(minute: KairosTime.generalQuotaMinutes)
        )
        let novelEvent = DeviceActivityEvent(
            applications: novelTokens,
            categories: novelCategories,
            webDomains: [],
            threshold: DateComponents(minute: KairosTime.novelQuotaMinutes)
        )
        return (schedule, [.generalQuota: generalEvent, .novelQuota: novelEvent])
    }

    // MARK: - Schedule Factories

    /// All-day schedule: 00:00 - 23:59, repeating.
    private static func allDaySchedule() -> DeviceActivitySchedule {
        let start = DateComponents(hour: 0, minute: 0)
        let end = DateComponents(hour: 23, minute: 59)
        return DeviceActivitySchedule(
            intervalStart: start,
            intervalEnd: end,
            repeats: true
        )
    }

    /// Night schedule: 22:00 - 05:59 (next day), repeating.
    private static func nightSchedule() -> DeviceActivitySchedule {
        let start = DateComponents(hour: KairosTime.nightStartHour, minute: 0)
        let end = DateComponents(hour: 5, minute: 59)
        return DeviceActivitySchedule(
            intervalStart: start,
            intervalEnd: end,
            repeats: true
        )
    }

    // MARK: - Event Factories

    /// A `DeviceActivityEvent` that fires after `KairosTime.usageThresholdMinutes` of
    /// combined usage across all supplied tokens and categories.
    private static func usageThresholdEvent(
        applications: Set<ApplicationToken>,
        categories: Set<ActivityCategoryToken>
    ) -> DeviceActivityEvent {
        DeviceActivityEvent(
            applications: applications,
            categories: categories,
            webDomains: [],
            threshold: DateComponents(minute: KairosTime.usageThresholdMinutes)
        )
    }
}
