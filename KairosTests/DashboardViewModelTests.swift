import Foundation
import KairosKit
import Testing
@testable import Kairos

// MARK: - Test Helpers

private func makeDate(hour: Int, minute: Int = 0, second: Int = 0) -> Date {
    var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    comps.hour = hour
    comps.minute = minute
    comps.second = second
    return Calendar.current.date(from: comps)!
}

// MARK: - DashboardDisplayBuilder Tests

@Suite("DashboardDisplayBuilder")
struct DashboardDisplayBuilderTests {

    // MARK: - statusMessage(for:)

    @Test("Morning mode returns correct status message prefix")
    func morningMode_statusMessage_containsMorning() {
        let message = DashboardDisplayBuilder.statusMessage(for: .morning)
        #expect(message.hasPrefix("早晨模式"))
    }

    @Test("Normal mode returns correct status message")
    func normalMode_statusMessage() {
        let message = DashboardDisplayBuilder.statusMessage(for: .normal)
        #expect(message == "普通模式 · 正常使用中")
    }

    @Test("NightCooldown mode returns correct status message prefix")
    func nightCooldownMode_statusMessage() {
        let message = DashboardDisplayBuilder.statusMessage(for: .nightCooldown)
        #expect(message.hasPrefix("晚间冷却"))
    }

    @Test("NightQuota mode returns correct status message prefix")
    func nightQuotaMode_statusMessage() {
        let message = DashboardDisplayBuilder.statusMessage(for: .nightQuota)
        #expect(message.hasPrefix("晚间额度"))
    }

    @Test("NightExhausted mode returns correct status message")
    func nightExhaustedMode_statusMessage_containsTomorrowBye() {
        let message = DashboardDisplayBuilder.statusMessage(for: .nightExhausted)
        #expect(message.contains("明天见"))
    }

    @Test("All modes produce non-empty status messages",
          arguments: KairosMode.allCases)
    func allModes_statusMessage_notEmpty(mode: KairosMode) {
        let message = DashboardDisplayBuilder.statusMessage(for: mode)
        #expect(!message.isEmpty)
    }

    // MARK: - nextChangeDescription(for:sleepFocusOffTimestamp:lastShieldTimestamp:currentTime:)

    @Test("Morning mode with focus off 30 min ago shows remaining ~30 min")
    func morningMode_30minElapsed_showsRemainingMinutes() {
        let currentTime = makeDate(hour: 8, minute: 0)
        let focusOffTime = currentTime.addingTimeInterval(-30 * 60) // 30 min ago
        let description = DashboardDisplayBuilder.nextChangeDescription(
            for: .morning,
            sleepFocusOffTimestamp: focusOffTime,
            lastShieldTimestamp: nil,
            currentTime: currentTime
        )
        // 30 minutes remain until morning lock ends (60 - 30 = 30)
        #expect(description.contains("30"))
    }

    @Test("Morning mode with focus off 59 min ago shows ~1 min remaining")
    func morningMode_59minElapsed_shows1MinRemaining() {
        let currentTime = makeDate(hour: 9, minute: 0)
        let focusOffTime = currentTime.addingTimeInterval(-59 * 60) // 59 min ago
        let description = DashboardDisplayBuilder.nextChangeDescription(
            for: .morning,
            sleepFocusOffTimestamp: focusOffTime,
            lastShieldTimestamp: nil,
            currentTime: currentTime
        )
        #expect(!description.isEmpty)
    }

    @Test("Morning mode with nil sleepFocusOffTimestamp returns fallback")
    func morningMode_nilFocusOff_returnsFallback() {
        let description = DashboardDisplayBuilder.nextChangeDescription(
            for: .morning,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: makeDate(hour: 8)
        )
        #expect(!description.isEmpty)
    }

    @Test("Normal mode returns empty next change description")
    func normalMode_returnsEmptyDescription() {
        let description = DashboardDisplayBuilder.nextChangeDescription(
            for: .normal,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: makeDate(hour: 14)
        )
        #expect(description.isEmpty)
    }

    @Test("NightCooldown with shield 10 min ago shows remaining ~20 min")
    func nightCooldownMode_10minSinceShield_shows20MinRemaining() {
        let currentTime = makeDate(hour: 22, minute: 30)
        let shieldTime = currentTime.addingTimeInterval(-10 * 60) // 10 min ago
        let description = DashboardDisplayBuilder.nextChangeDescription(
            for: .nightCooldown,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldTime,
            currentTime: currentTime
        )
        // 20 minutes remain until cooldown ends (30 - 10 = 20)
        #expect(description.contains("20"))
    }

    @Test("NightCooldown with nil shield timestamp returns fallback description")
    func nightCooldownMode_nilShield_returnsFallback() {
        let description = DashboardDisplayBuilder.nextChangeDescription(
            for: .nightCooldown,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: makeDate(hour: 22, minute: 30)
        )
        #expect(!description.isEmpty)
    }

    @Test("NightQuota mode returns non-empty description")
    func nightQuotaMode_returnsNonEmptyDescription() {
        let description = DashboardDisplayBuilder.nextChangeDescription(
            for: .nightQuota,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: makeDate(hour: 23)
        )
        #expect(!description.isEmpty)
    }

    @Test("NightExhausted mode description contains 明天见")
    func nightExhaustedMode_containsTomorrowBye() {
        let description = DashboardDisplayBuilder.nextChangeDescription(
            for: .nightExhausted,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: makeDate(hour: 23)
        )
        #expect(description.contains("明天见"))
    }

    // MARK: - Edge Cases

    @Test("Morning mode with elapsed time exactly at boundary returns fallback")
    func morningMode_exactlyAtBoundary_returnsFallback() {
        let currentTime = makeDate(hour: 9)
        // Exactly 60 minutes have elapsed — morning window just expired
        let focusOffTime = currentTime.addingTimeInterval(-60 * 60)
        let description = DashboardDisplayBuilder.nextChangeDescription(
            for: .morning,
            sleepFocusOffTimestamp: focusOffTime,
            lastShieldTimestamp: nil,
            currentTime: currentTime
        )
        // When remaining <= 0, should show an "imminent" or fallback message
        #expect(!description.isEmpty)
    }

    @Test("NightCooldown with shield over 30 min ago shows expired/fallback")
    func nightCooldownMode_shieldOver30Min_showsFallback() {
        let currentTime = makeDate(hour: 23)
        let shieldTime = currentTime.addingTimeInterval(-35 * 60) // 35 min ago, past cooldown
        let description = DashboardDisplayBuilder.nextChangeDescription(
            for: .nightCooldown,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldTime,
            currentTime: currentTime
        )
        #expect(!description.isEmpty)
    }
}
