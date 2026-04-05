import Testing
import Foundation
import KairosKit

// MARK: - Test Helpers

/// Builds a Date for today at a given hour and minute (local calendar).
private func today(hour: Int, minute: Int = 0, second: Int = 0) -> Date {
    var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    comps.hour = hour
    comps.minute = minute
    comps.second = second
    return Calendar.current.date(from: comps)!
}

/// Builds a Date for yesterday at a given hour and minute.
private func yesterday(hour: Int, minute: Int = 0) -> Date {
    let cal = Calendar.current
    let base = cal.date(byAdding: .day, value: -1, to: Date())!
    var comps = cal.dateComponents([.year, .month, .day], from: base)
    comps.hour = hour
    comps.minute = minute
    return cal.date(from: comps)!
}

/// Convenience: build a default input, overriding only the fields under test.
private func makeInput(
    currentTime: Date = Date(),
    sleepFocusActive: Bool = false,
    sleepFocusOffTimestamp: Date? = nil,
    isAtHome: Bool = false,
    lastShieldTimestamp: Date? = nil,
    wasInNightMode: Bool = false,
    lastManagedAppUsageTimestamp: Date? = nil
) -> ModeResolverInput {
    ModeResolverInput(
        currentTime: currentTime,
        sleepFocusActive: sleepFocusActive,
        sleepFocusOffTimestamp: sleepFocusOffTimestamp,
        isAtHome: isAtHome,
        lastShieldTimestamp: lastShieldTimestamp,
        wasInNightMode: wasInNightMode,
        lastManagedAppUsageTimestamp: lastManagedAppUsageTimestamp
    )
}

// MARK: - ModeResolver Tests

@Suite("ModeResolver")
struct ModeResolverTests {

    // MARK: - Sleep Focus Active

    @Test("Sleep focus active -> normal (phone in sleep mode)")
    func sleepFocusActive_returnsNormal() {
        let input = makeInput(
            currentTime: today(hour: 10),
            sleepFocusActive: true,
            isAtHome: true
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    @Test("Sleep focus active even at night -> normal")
    func sleepFocusActive_atNight_returnsNormal() {
        let input = makeInput(
            currentTime: today(hour: 23),
            sleepFocusActive: true,
            isAtHome: true
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    // MARK: - Morning Mode (requires wasInNightMode)

    @Test("Just woke up from night mode (< 60 min) -> morning")
    func wokeFromNightMode_withinWindow_returnsMorning() {
        let wakeTime = today(hour: 7, minute: 30)
        let currentTime = today(hour: 8, minute: 0) // 30 min later
        let input = makeInput(
            currentTime: currentTime,
            sleepFocusOffTimestamp: wakeTime,
            isAtHome: true,
            wasInNightMode: true
        )
        #expect(ModeResolver.resolve(input) == .morning)
    }

    @Test("Woke up 59 min ago from night mode -> still morning")
    func wokeFromNightMode_59MinAgo_returnsMorning() {
        let currentTime = today(hour: 9, minute: 0)
        let wakeTime = currentTime.addingTimeInterval(-59 * 60)
        let input = makeInput(
            currentTime: currentTime,
            sleepFocusOffTimestamp: wakeTime,
            wasInNightMode: true
        )
        #expect(ModeResolver.resolve(input) == .morning)
    }

    @Test("Woke up exactly 60 min ago -> morning window expired, not morning")
    func wokeFromNightMode_exactly60MinAgo_morningExpired() {
        let currentTime = today(hour: 9, minute: 0)
        let wakeTime = currentTime.addingTimeInterval(-60 * 60)
        let input = makeInput(
            currentTime: currentTime,
            sleepFocusOffTimestamp: wakeTime,
            wasInNightMode: true
        )
        #expect(ModeResolver.resolve(input) != .morning)
    }

    @Test("Woke up > 60 min ago from night mode -> normal")
    func wokeFromNightMode_moreThan60MinAgo_returnsNormal() {
        let currentTime = today(hour: 10, minute: 0)
        let wakeTime = currentTime.addingTimeInterval(-90 * 60)
        let input = makeInput(
            currentTime: currentTime,
            sleepFocusOffTimestamp: wakeTime,
            wasInNightMode: true
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    @Test("Daytime sleep focus toggle (NOT from night mode) -> normal, NOT morning")
    func daytimeSleepToggle_notFromNight_returnsNormal() {
        let wakeTime = today(hour: 14, minute: 0)
        let currentTime = today(hour: 14, minute: 30) // 30 min later
        let input = makeInput(
            currentTime: currentTime,
            sleepFocusOffTimestamp: wakeTime,
            isAtHome: true,
            wasInNightMode: false // was NOT in night mode
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    @Test("No sleep focus off timestamp, focus not active -> not morning")
    func noSleepFocusTimestamp_notMorning() {
        let input = makeInput(
            currentTime: today(hour: 8),
            isAtHome: true,
            wasInNightMode: true
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    @Test("Re-enable sleep focus during morning -> normal (sleep focus overrides)")
    func reEnableSleepDuringMorning_returnsNormal() {
        let wakeTime = today(hour: 7, minute: 30)
        let input = makeInput(
            currentTime: today(hour: 8, minute: 0),
            sleepFocusActive: true, // re-enabled sleep focus
            sleepFocusOffTimestamp: wakeTime,
            isAtHome: true,
            wasInNightMode: true
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    // MARK: - Morning Priority Over Night

    @Test("Morning mode takes priority over night mode (woke up at 22:30 from night)")
    func morningPriority_overNightMode() {
        let wakeTime = today(hour: 22, minute: 30)
        let currentTime = today(hour: 23, minute: 0) // 30 min later
        let input = makeInput(
            currentTime: currentTime,
            sleepFocusOffTimestamp: wakeTime,
            isAtHome: true,
            wasInNightMode: true
        )
        #expect(ModeResolver.resolve(input) == .morning)
    }

    // MARK: - Daytime / Normal

    @Test("Daytime, at home, no special state -> normal")
    func daytime_atHome_returnsNormal() {
        let input = makeInput(
            currentTime: today(hour: 14),
            isAtHome: true
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    @Test("Daytime, not at home -> normal")
    func daytime_notAtHome_returnsNormal() {
        let input = makeInput(currentTime: today(hour: 12))
        #expect(ModeResolver.resolve(input) == .normal)
    }

    // MARK: - Night Mode (Quota)

    @Test("Night, at home, last usage >= 30 min ago -> night (quota)")
    func night_atHome_inactive30Min_returnsNight() {
        let currentTime = today(hour: 23)
        let lastUsage = currentTime.addingTimeInterval(-30 * 60) // 30 min ago
        let input = makeInput(
            currentTime: currentTime,
            isAtHome: true,
            lastManagedAppUsageTimestamp: lastUsage
        )
        #expect(ModeResolver.resolve(input) == .night)
    }

    @Test("Night, at home, last usage < 30 min ago -> normal (recent activity)")
    func night_atHome_recentUsage_returnsNormal() {
        let currentTime = today(hour: 23)
        let lastUsage = currentTime.addingTimeInterval(-15 * 60) // 15 min ago
        let input = makeInput(
            currentTime: currentTime,
            isAtHome: true,
            lastManagedAppUsageTimestamp: lastUsage
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    @Test("Night, at home, last usage nil (never used) -> night (quota)")
    func night_atHome_nilUsage_returnsNight() {
        let input = makeInput(
            currentTime: today(hour: 23),
            isAtHome: true,
            lastManagedAppUsageTimestamp: nil
        )
        #expect(ModeResolver.resolve(input) == .night)
    }

    @Test("Night, NOT at home -> normal (geofence blocks night)")
    func night_notAtHome_returnsNormal() {
        let input = makeInput(
            currentTime: today(hour: 23),
            lastManagedAppUsageTimestamp: nil
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    // MARK: - Night Window Boundaries

    @Test("21:59 at home -> not yet night, returns normal")
    func oneMinuteBeforeNight_atHome_returnsNormal() {
        let input = makeInput(
            currentTime: today(hour: 21, minute: 59),
            isAtHome: true,
            lastManagedAppUsageTimestamp: nil
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    @Test("22:00 exactly at home, inactive -> night begins, returns night")
    func exactlyNightStart_atHome_inactive_returnsNight() {
        let input = makeInput(
            currentTime: today(hour: 22, minute: 0),
            isAtHome: true,
            lastManagedAppUsageTimestamp: nil
        )
        #expect(ModeResolver.resolve(input) == .night)
    }

    @Test("22:00 exactly but NOT at home -> normal (geofence)")
    func exactlyNightStart_notAtHome_returnsNormal() {
        let input = makeInput(
            currentTime: today(hour: 22, minute: 0),
            lastManagedAppUsageTimestamp: nil
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    @Test("22:00, at home, recent activity -> normal (cooldown cycle)")
    func nightStart_atHome_recentActivity_returnsNormal() {
        let currentTime = today(hour: 22, minute: 0)
        let lastUsage = currentTime.addingTimeInterval(-10 * 60) // 10 min ago
        let input = makeInput(
            currentTime: currentTime,
            isAtHome: true,
            lastManagedAppUsageTimestamp: lastUsage
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    // MARK: - Midnight Crossover

    @Test("00:30 at home, inactive -> still in night window")
    func afterMidnight_atHome_inactive_returnsNight() {
        let input = makeInput(
            currentTime: today(hour: 0, minute: 30),
            isAtHome: true,
            lastManagedAppUsageTimestamp: nil
        )
        #expect(ModeResolver.resolve(input) == .night)
    }

    @Test("03:00 at home, inactive -> still in extended night window")
    func threeAM_atHome_inactive_returnsNight() {
        let input = makeInput(
            currentTime: today(hour: 3),
            isAtHome: true,
            lastManagedAppUsageTimestamp: nil
        )
        #expect(ModeResolver.resolve(input) == .night)
    }

    @Test("06:00 at home -> daytime begins, returns normal")
    func sixAM_atHome_returnsNormal() {
        let input = makeInput(
            currentTime: today(hour: 6),
            isAtHome: true,
            lastManagedAppUsageTimestamp: nil
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    @Test("00:30 at home, recent activity -> normal (cooldown in night window)")
    func afterMidnight_atHome_recentActivity_returnsNormal() {
        let currentTime = today(hour: 0, minute: 30)
        let lastUsage = currentTime.addingTimeInterval(-10 * 60)
        let input = makeInput(
            currentTime: currentTime,
            isAtHome: true,
            lastManagedAppUsageTimestamp: lastUsage
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    // MARK: - Parameterized: All daytime hours are normal

    @Test("Daytime hours (6-21) at home without special state -> normal",
          arguments: [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21])
    func daytimeHours_atHome_returnsNormal(hour: Int) {
        let input = makeInput(
            currentTime: today(hour: hour),
            isAtHome: true
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    @Test("Night hours (22, 23) at home, inactive -> night",
          arguments: [22, 23])
    func nightHours_atHome_inactive_returnsNight(hour: Int) {
        let input = makeInput(
            currentTime: today(hour: hour),
            isAtHome: true,
            lastManagedAppUsageTimestamp: nil
        )
        #expect(ModeResolver.resolve(input) == .night)
    }

    @Test("Post-midnight night hours (0-5) at home, inactive -> night",
          arguments: [0, 1, 2, 3, 4, 5])
    func postMidnightNightHours_atHome_inactive_returnsNight(hour: Int) {
        let input = makeInput(
            currentTime: today(hour: hour),
            isAtHome: true,
            lastManagedAppUsageTimestamp: nil
        )
        #expect(ModeResolver.resolve(input) == .night)
    }

    // MARK: - Edge: Inactivity boundary

    @Test("Night, at home, last usage exactly 29 min 59 sec ago -> normal")
    func night_atHome_lastUsage29Min59Sec_returnsNormal() {
        let currentTime = today(hour: 23)
        let lastUsage = currentTime.addingTimeInterval(-(30 * 60 - 1))
        let input = makeInput(
            currentTime: currentTime,
            isAtHome: true,
            lastManagedAppUsageTimestamp: lastUsage
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    @Test("Night, at home, last usage exactly 30 min ago -> night")
    func night_atHome_lastUsageExactly30Min_returnsNight() {
        let currentTime = today(hour: 23)
        let lastUsage = currentTime.addingTimeInterval(-30 * 60)
        let input = makeInput(
            currentTime: currentTime,
            isAtHome: true,
            lastManagedAppUsageTimestamp: lastUsage
        )
        #expect(ModeResolver.resolve(input) == .night)
    }
}
