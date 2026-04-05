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

/// Returns today's date string in yyyy-MM-dd format.
private var todayString: String {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    return fmt.string(from: Date())
}

/// Returns yesterday's date string in yyyy-MM-dd format.
private var yesterdayString: String {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    return fmt.string(from: yesterday)
}

// MARK: - ModeResolver Tests

@Suite("ModeResolver")
struct ModeResolverTests {

    // MARK: - Sleep Focus Active

    @Test("Sleep focus active → normal (phone in sleep mode)")
    func sleepFocusActive_returnsNormal() {
        let input = ModeResolverInput(
            currentTime: today(hour: 10),
            sleepFocusActive: true,
            sleepFocusOffTimestamp: nil,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    @Test("Sleep focus active even at night → normal")
    func sleepFocusActive_atNight_returnsNormal() {
        let input = ModeResolverInput(
            currentTime: today(hour: 23),
            sleepFocusActive: true,
            sleepFocusOffTimestamp: nil,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    // MARK: - Morning Mode

    @Test("Just woke up (< 60 min since sleep focus off) → morning")
    func justWokeUp_withinMorningWindow_returnsMorning() {
        let wakeTime = today(hour: 7, minute: 30)
        let currentTime = today(hour: 8, minute: 0) // 30 min later
        let input = ModeResolverInput(
            currentTime: currentTime,
            sleepFocusActive: false,
            sleepFocusOffTimestamp: wakeTime,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        #expect(ModeResolver.resolve(input) == .morning)
    }

    @Test("Woke up 59 min ago → still morning")
    func wokeUp59MinAgo_returnsMorning() {
        let currentTime = today(hour: 9, minute: 0)
        let wakeTime = currentTime.addingTimeInterval(-59 * 60) // 59 minutes ago
        let input = ModeResolverInput(
            currentTime: currentTime,
            sleepFocusActive: false,
            sleepFocusOffTimestamp: wakeTime,
            isAtHome: false,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        #expect(ModeResolver.resolve(input) == .morning)
    }

    @Test("Woke up exactly 60 min ago → morning window expired, not morning")
    func wokeUpExactly60MinAgo_morningExpired() {
        let currentTime = today(hour: 9, minute: 0)
        let wakeTime = currentTime.addingTimeInterval(-60 * 60) // exactly 60 min ago
        let input = ModeResolverInput(
            currentTime: currentTime,
            sleepFocusActive: false,
            sleepFocusOffTimestamp: wakeTime,
            isAtHome: false,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        #expect(ModeResolver.resolve(input) != .morning)
    }

    @Test("Woke up > 60 min ago → morning expired, falls to normal")
    func wokeUpMoreThan60MinAgo_returnsNormal() {
        let currentTime = today(hour: 10, minute: 0)
        let wakeTime = currentTime.addingTimeInterval(-90 * 60) // 90 min ago
        let input = ModeResolverInput(
            currentTime: currentTime,
            sleepFocusActive: false,
            sleepFocusOffTimestamp: wakeTime,
            isAtHome: false,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    @Test("No sleep focus off timestamp, focus not active → not morning")
    func noSleepFocusTimestamp_notMorning() {
        let input = ModeResolverInput(
            currentTime: today(hour: 8),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    // MARK: - Morning Priority Over Night

    @Test("Morning mode takes priority over night mode (woke up at 22:30)")
    func morningPriority_overNightMode() {
        // User fell asleep, sleep focus turned on, then off at 22:30
        let wakeTime = today(hour: 22, minute: 30)
        let currentTime = today(hour: 23, minute: 0) // 30 min later, within morning window
        let input = ModeResolverInput(
            currentTime: currentTime,
            sleepFocusActive: false,
            sleepFocusOffTimestamp: wakeTime,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        // Morning takes priority — even though it's night and at home
        #expect(ModeResolver.resolve(input) == .morning)
    }

    // MARK: - Daytime / Normal

    @Test("Daytime, at home, no special state → normal")
    func daytime_atHome_returnsNormal() {
        let input = ModeResolverInput(
            currentTime: today(hour: 14),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    @Test("Daytime, not at home → normal")
    func daytime_notAtHome_returnsNormal() {
        let input = ModeResolverInput(
            currentTime: today(hour: 12),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: false,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    // MARK: - Night Mode Edge Cases (Hour Boundaries)

    @Test("21:59 at home → not yet night, returns normal")
    func oneMinuteBeforeNight_atHome_returnsNormal() {
        let input = ModeResolverInput(
            currentTime: today(hour: 21, minute: 59),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    @Test("22:00 exactly at home → night begins, returns nightCooldown")
    func exactlyNightStart_atHome_returnsNightCooldown() {
        let input = ModeResolverInput(
            currentTime: today(hour: 22, minute: 0),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        #expect(ModeResolver.resolve(input) == .nightCooldown)
    }

    @Test("22:00 exactly but NOT at home → normal (geofence)")
    func exactlyNightStart_notAtHome_returnsNormal() {
        let input = ModeResolverInput(
            currentTime: today(hour: 22, minute: 0),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: false,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    // MARK: - Night Mode (nightCooldown)

    @Test("Night, at home, no quota activated → nightCooldown")
    func night_atHome_noQuota_returnsNightCooldown() {
        let input = ModeResolverInput(
            currentTime: today(hour: 23),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        #expect(ModeResolver.resolve(input) == .nightCooldown)
    }

    @Test("Night, NOT at home → normal (geofence blocks night modes)")
    func night_notAtHome_returnsNormal() {
        let input = ModeResolverInput(
            currentTime: today(hour: 23),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: false,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    // MARK: - Night Quota Mode

    @Test("Night, at home, quota activated for today → nightQuota")
    func night_atHome_quotaActivatedToday_returnsNightQuota() {
        let input = ModeResolverInput(
            currentTime: today(hour: 23),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: true,
            nightQuotaDate: todayString,
            nightQuotaExhausted: false
        )
        #expect(ModeResolver.resolve(input) == .nightQuota)
    }

    @Test("Night, at home, quota activated but date is yesterday → nightCooldown (stale quota)")
    func night_atHome_quotaActivatedYesterday_returnsNightCooldown() {
        let input = ModeResolverInput(
            currentTime: today(hour: 23),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: true,
            nightQuotaDate: yesterdayString,
            nightQuotaExhausted: false
        )
        // Yesterday's quota date means it hasn't been set for today yet
        #expect(ModeResolver.resolve(input) == .nightCooldown)
    }

    @Test("Night, at home, quota activated but date is nil → nightCooldown")
    func night_atHome_quotaActivated_nilDate_returnsNightCooldown() {
        let input = ModeResolverInput(
            currentTime: today(hour: 23),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: true,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        #expect(ModeResolver.resolve(input) == .nightCooldown)
    }

    // MARK: - Night Exhausted Mode

    @Test("Night, at home, quota exhausted for today → nightExhausted")
    func night_atHome_quotaExhaustedToday_returnsNightExhausted() {
        let input = ModeResolverInput(
            currentTime: today(hour: 23),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: true,
            nightQuotaDate: todayString,
            nightQuotaExhausted: true
        )
        #expect(ModeResolver.resolve(input) == .nightExhausted)
    }

    @Test("Night, at home, exhausted but date is yesterday → nightCooldown (stale state)")
    func night_atHome_exhaustedYesterday_returnsNightCooldown() {
        let input = ModeResolverInput(
            currentTime: today(hour: 23),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: true,
            nightQuotaDate: yesterdayString,
            nightQuotaExhausted: true
        )
        // Stale exhaust marker from yesterday — treat as fresh night
        #expect(ModeResolver.resolve(input) == .nightCooldown)
    }

    @Test("Night, at home, exhausted flag true but quotaDate nil → nightCooldown")
    func night_atHome_exhausted_nilDate_returnsNightCooldown() {
        let input = ModeResolverInput(
            currentTime: today(hour: 23),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: true
        )
        // No date set — exhausted flag without context → nightCooldown
        #expect(ModeResolver.resolve(input) == .nightCooldown)
    }

    // MARK: - Midnight Crossover (After-Midnight Night)

    @Test("00:30 at home → still in night window (past midnight crossover)")
    func afterMidnight_atHome_returnsNightCooldown() {
        // 00:30 is before nightEnd (we treat 0–5am as part of night in many sleep apps,
        // but here the spec only says nightStartHour = 22. We treat hours 22–23 as night.
        // Hours 0–21 are daytime. So 00:30 should be normal.
        // HOWEVER: the task says "midnight crossover → should still be night mode".
        // This means the design intent is hours 22–23 AND 0–X are night.
        // Let's document this test per the spec requirement.
        let input = ModeResolverInput(
            currentTime: today(hour: 0, minute: 30),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        // Per task: midnight crossover should still be night mode
        #expect(ModeResolver.resolve(input) == .nightCooldown)
    }

    @Test("03:00 at home → still in extended night window")
    func threeAM_atHome_returnsNightCooldown() {
        let input = ModeResolverInput(
            currentTime: today(hour: 3),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        #expect(ModeResolver.resolve(input) == .nightCooldown)
    }

    @Test("06:00 at home → daytime begins, returns normal")
    func sixAM_atHome_returnsNormal() {
        let input = ModeResolverInput(
            currentTime: today(hour: 6),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        // 06:00 is after the night window ends
        #expect(ModeResolver.resolve(input) == .normal)
    }

    // MARK: - Priority Order Verification

    @Test("Night exhausted has higher priority than nightQuota")
    func nightExhausted_higherPriority_thanNightQuota() {
        // Both exhausted=true and quota date = today → nightExhausted wins
        let input = ModeResolverInput(
            currentTime: today(hour: 23),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: true,
            nightQuotaDate: todayString,
            nightQuotaExhausted: true
        )
        #expect(ModeResolver.resolve(input) == .nightExhausted)
    }

    @Test("Morning higher priority than nightExhausted")
    func morning_higherPriority_thanNightExhausted() {
        // User woke up from sleep at 22:30, and quota is exhausted
        let wakeTime = today(hour: 22, minute: 30)
        let currentTime = today(hour: 23, minute: 0) // 30 min later
        let input = ModeResolverInput(
            currentTime: currentTime,
            sleepFocusActive: false,
            sleepFocusOffTimestamp: wakeTime,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: true,
            nightQuotaDate: todayString,
            nightQuotaExhausted: true
        )
        // Morning takes priority over everything
        #expect(ModeResolver.resolve(input) == .morning)
    }

    // MARK: - Parameterized: All daytime hours are normal

    @Test("Daytime hours (6–21) at home without special state → normal",
          arguments: [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21])
    func daytimeHours_atHome_returnsNormal(hour: Int) {
        let input = ModeResolverInput(
            currentTime: today(hour: hour),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        #expect(ModeResolver.resolve(input) == .normal)
    }

    @Test("Night hours (22, 23) at home without quota → nightCooldown",
          arguments: [22, 23])
    func nightHours_atHome_returnsNightCooldown(hour: Int) {
        let input = ModeResolverInput(
            currentTime: today(hour: hour),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        #expect(ModeResolver.resolve(input) == .nightCooldown)
    }

    @Test("Post-midnight night hours (0–5) at home without quota → nightCooldown",
          arguments: [0, 1, 2, 3, 4, 5])
    func postMidnightNightHours_atHome_returnsNightCooldown(hour: Int) {
        let input = ModeResolverInput(
            currentTime: today(hour: hour),
            sleepFocusActive: false,
            sleepFocusOffTimestamp: nil,
            isAtHome: true,
            lastShieldTimestamp: nil,
            nightQuotaActivated: false,
            nightQuotaDate: nil,
            nightQuotaExhausted: false
        )
        #expect(ModeResolver.resolve(input) == .nightCooldown)
    }
}
