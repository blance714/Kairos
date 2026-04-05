import Foundation
import DeviceActivity
import ManagedSettings

// MARK: - DeviceActivityName

public extension DeviceActivityName {
    /// Normal mode: 15-min usage monitoring.
    nonisolated(unsafe) static let normalMode = Self("kairos.normalMode")
    /// Night quota: general app group usage monitoring.
    nonisolated(unsafe) static let nightQuotaGeneral = Self("kairos.nightQuotaGeneral")
    /// Night quota: novel app group usage monitoring.
    nonisolated(unsafe) static let nightQuotaNovel = Self("kairos.nightQuotaNovel")
}

// MARK: - DeviceActivityEvent.Name

public extension DeviceActivityEvent.Name {
    /// 15-min usage threshold (normal / night cooldown).
    nonisolated(unsafe) static let usageThreshold = Self("kairos.usageThreshold")
    /// 20-min general app quota (night mode).
    nonisolated(unsafe) static let generalQuota = Self("kairos.generalQuota")
    /// 45-min novel app quota (night mode).
    nonisolated(unsafe) static let novelQuota = Self("kairos.novelQuota")
}

// MARK: - ManagedSettingsStore.Name

public extension ManagedSettingsStore.Name {
    /// Shield applied during morning mode.
    nonisolated(unsafe) static let morningLock = Self("kairos.morningLock")
    /// Shield applied during cooldown (normal / night).
    nonisolated(unsafe) static let cooldownLock = Self("kairos.cooldownLock")
    /// Shield applied when night quota is exhausted.
    nonisolated(unsafe) static let quotaLock = Self("kairos.quotaLock")
}

// MARK: - Time Constants

public enum KairosTime {
    /// Cooldown duration before shield can be lifted (30 minutes).
    public static let cooldownMinutes: Int = 30
    /// Usage threshold before cooldown kicks in (15 minutes).
    public static let usageThresholdMinutes: Int = 15
    /// Morning mode duration after sleep focus off (60 minutes).
    public static let morningLockMinutes: Int = 60
    /// Night mode start hour (22:00).
    public static let nightStartHour: Int = 22
    /// General app quota in night mode (20 minutes).
    public static let generalQuotaMinutes: Int = 20
    /// Novel app quota in night mode (45 minutes).
    public static let novelQuotaMinutes: Int = 45
    /// Inactivity duration to activate night quota (30 minutes).
    public static let inactivityForQuotaMinutes: Int = 30
}
