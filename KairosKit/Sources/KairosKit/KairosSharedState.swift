import Foundation
import FamilyControls
import ManagedSettings

/// Type-safe wrapper around App Group UserDefaults for cross-target state sharing.
public final class KairosSharedState: Sendable {
    public static let shared = KairosSharedState()

    private static let suiteName = "group.org.blance.kairos"
    private nonisolated(unsafe) let defaults: UserDefaults

    private init() {
        guard let defaults = UserDefaults(suiteName: Self.suiteName) else {
            fatalError("Failed to create UserDefaults for App Group: \(Self.suiteName)")
        }
        self.defaults = defaults
    }

    // MARK: - Keys

    private enum Key {
        static let sleepFocusActive = "sleepFocusActive"
        static let sleepFocusOffTimestamp = "sleepFocusOffTimestamp"
        static let isAtHome = "isAtHome"
        static let homeLatitude = "homeLatitude"
        static let homeLongitude = "homeLongitude"
        static let homeLocationSet = "homeLocationSet"
        static let currentMode = "currentMode"
        static let lastShieldTimestamp = "lastShieldTimestamp"
        static let lastUsageTimestamp = "lastUsageTimestamp"
        static let nightQuotaActivated = "nightQuotaActivated"
        static let nightQuotaDate = "nightQuotaDate"
        static let nightQuotaExhausted = "nightQuotaExhausted"
        static let generalSelection = "generalSelection"
        static let novelSelection = "novelSelection"
        static let onboardingCompleted = "onboardingCompleted"
        static let authorizationGranted = "authorizationGranted"
    }

    // MARK: - Sleep Focus

    public var sleepFocusActive: Bool {
        get { defaults.bool(forKey: Key.sleepFocusActive) }
        set { defaults.set(newValue, forKey: Key.sleepFocusActive) }
    }

    public var sleepFocusOffTimestamp: Date? {
        get {
            let interval = defaults.double(forKey: Key.sleepFocusOffTimestamp)
            return interval > 0 ? Date(timeIntervalSince1970: interval) : nil
        }
        set {
            defaults.set(newValue?.timeIntervalSince1970 ?? 0, forKey: Key.sleepFocusOffTimestamp)
        }
    }

    // MARK: - Geofence

    public var isAtHome: Bool {
        get { defaults.bool(forKey: Key.isAtHome) }
        set { defaults.set(newValue, forKey: Key.isAtHome) }
    }

    public var homeLatitude: Double {
        get { defaults.double(forKey: Key.homeLatitude) }
        set { defaults.set(newValue, forKey: Key.homeLatitude) }
    }

    public var homeLongitude: Double {
        get { defaults.double(forKey: Key.homeLongitude) }
        set { defaults.set(newValue, forKey: Key.homeLongitude) }
    }

    public var homeLocationSet: Bool {
        get { defaults.bool(forKey: Key.homeLocationSet) }
        set { defaults.set(newValue, forKey: Key.homeLocationSet) }
    }

    // MARK: - Mode State

    public var currentMode: KairosMode {
        get {
            guard let raw = defaults.string(forKey: Key.currentMode),
                  let mode = KairosMode(rawValue: raw) else {
                return .normal
            }
            return mode
        }
        set { defaults.set(newValue.rawValue, forKey: Key.currentMode) }
    }

    public var lastShieldTimestamp: Date? {
        get {
            let interval = defaults.double(forKey: Key.lastShieldTimestamp)
            return interval > 0 ? Date(timeIntervalSince1970: interval) : nil
        }
        set {
            defaults.set(newValue?.timeIntervalSince1970 ?? 0, forKey: Key.lastShieldTimestamp)
        }
    }

    public var lastUsageTimestamp: Date? {
        get {
            let interval = defaults.double(forKey: Key.lastUsageTimestamp)
            return interval > 0 ? Date(timeIntervalSince1970: interval) : nil
        }
        set {
            defaults.set(newValue?.timeIntervalSince1970 ?? 0, forKey: Key.lastUsageTimestamp)
        }
    }

    public var nightQuotaActivated: Bool {
        get { defaults.bool(forKey: Key.nightQuotaActivated) }
        set { defaults.set(newValue, forKey: Key.nightQuotaActivated) }
    }

    /// The date string (yyyy-MM-dd) when night quota was last activated, for daily reset.
    public var nightQuotaDate: String? {
        get { defaults.string(forKey: Key.nightQuotaDate) }
        set { defaults.set(newValue, forKey: Key.nightQuotaDate) }
    }

    /// Whether the night quota has been fully exhausted today.
    /// Set by the DeviceActivity monitor when both general and novel quotas are consumed.
    public var nightQuotaExhausted: Bool {
        get { defaults.bool(forKey: Key.nightQuotaExhausted) }
        set { defaults.set(newValue, forKey: Key.nightQuotaExhausted) }
    }

    // MARK: - App Selection (FamilyActivitySelection)

    public var generalSelection: FamilyActivitySelection? {
        get { decodeFamilySelection(forKey: Key.generalSelection) }
        set { encodeFamilySelection(newValue, forKey: Key.generalSelection) }
    }

    public var novelSelection: FamilyActivitySelection? {
        get { decodeFamilySelection(forKey: Key.novelSelection) }
        set { encodeFamilySelection(newValue, forKey: Key.novelSelection) }
    }

    // MARK: - Onboarding

    public var onboardingCompleted: Bool {
        get { defaults.bool(forKey: Key.onboardingCompleted) }
        set { defaults.set(newValue, forKey: Key.onboardingCompleted) }
    }

    public var authorizationGranted: Bool {
        get { defaults.bool(forKey: Key.authorizationGranted) }
        set { defaults.set(newValue, forKey: Key.authorizationGranted) }
    }

    // MARK: - Helpers

    private func encodeFamilySelection(_ selection: FamilyActivitySelection?, forKey key: String) {
        guard let selection else {
            defaults.removeObject(forKey: key)
            return
        }
        do {
            let data = try PropertyListEncoder().encode(selection)
            defaults.set(data, forKey: key)
        } catch {
            print("[KairosKit] Failed to encode FamilyActivitySelection: \(error)")
        }
    }

    private func decodeFamilySelection(forKey key: String) -> FamilyActivitySelection? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
        } catch {
            print("[KairosKit] Failed to decode FamilyActivitySelection: \(error)")
            return nil
        }
    }
}
