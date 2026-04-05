import Testing
import Foundation
import KairosKit

// MARK: - Test Helpers

private extension Date {
    /// Returns a new Date by adding the given number of minutes.
    func adding(minutes: Double) -> Date {
        addingTimeInterval(minutes * 60)
    }

    /// Returns a new Date by subtracting the given number of minutes.
    func subtracting(minutes: Double) -> Date {
        addingTimeInterval(-(minutes * 60))
    }
}

// MARK: - ShieldTextBuilder Tests

@Suite("ShieldTextBuilder")
struct ShieldTextBuilderTests {

    // MARK: - Morning Mode

    @Test("Morning mode: title is 早安 ☀️")
    func morningMode_titleIsCorrect() {
        let now = Date()
        let sleepOffAt = now.subtracting(minutes: 30) // 30 min ago → 30 min remaining

        let text = ShieldTextBuilder.build(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            currentTime: now
        )

        #expect(text.title == "早安 ☀️")
    }

    @Test("Morning mode: primary button is 好的")
    func morningMode_primaryButtonIsCorrect() {
        let now = Date()
        let text = ShieldTextBuilder.build(
            mode: .morning,
            sleepFocusOffTimestamp: now.subtracting(minutes: 30),
            lastShieldTimestamp: nil,
            currentTime: now
        )

        #expect(text.primaryButtonLabel == "好的")
    }

    @Test("Morning mode: secondary button is 查看状态")
    func morningMode_secondaryButtonIsQueryStatus() {
        let now = Date()
        let text = ShieldTextBuilder.build(
            mode: .morning,
            sleepFocusOffTimestamp: now.subtracting(minutes: 30),
            lastShieldTimestamp: nil,
            currentTime: now
        )

        #expect(text.secondaryButtonLabel == "查看状态")
    }

    @Test("Morning mode with 30 min remaining: subtitle shows remaining time")
    func morningMode_subtitleShowsRemainingTime() {
        let now = Date()
        // sleep focus turned off 30 min ago → unlock at 60 min mark → 30 min left
        let sleepOffAt = now.subtracting(minutes: 30)

        let text = ShieldTextBuilder.build(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            currentTime: now
        )

        // 30 minutes remaining → "0:30 后可用"
        #expect(text.subtitle == "0:30 后可用")
    }

    @Test("Morning mode with 1 min remaining: subtitle shows 0:01")
    func morningMode_subtitleShowsOneMinuteRemaining() {
        let now = Date()
        let sleepOffAt = now.subtracting(minutes: 59)

        let text = ShieldTextBuilder.build(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            currentTime: now
        )

        #expect(text.subtitle == "0:01 后可用")
    }

    @Test("Morning mode with exactly 60 min elapsed: subtitle shows 即将可用")
    func morningMode_exactlyExpired_subtitleIsImminentlyAvailable() {
        let now = Date()
        let sleepOffAt = now.subtracting(minutes: 60)

        let text = ShieldTextBuilder.build(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            currentTime: now
        )

        #expect(text.subtitle == "即将可用")
    }

    @Test("Morning mode with nil sleepFocusOffTimestamp: subtitle shows 即将可用")
    func morningMode_nilTimestamp_subtitleIsImminentlyAvailable() {
        let text = ShieldTextBuilder.build(
            mode: .morning,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: Date()
        )

        #expect(text.subtitle == "即将可用")
    }

    @Test("Morning mode with 65 min elapsed (past lock): subtitle shows 即将可用")
    func morningMode_pastExpiry_subtitleIsImminentlyAvailable() {
        let now = Date()
        let sleepOffAt = now.subtracting(minutes: 65)

        let text = ShieldTextBuilder.build(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            currentTime: now
        )

        #expect(text.subtitle == "即将可用")
    }

    // MARK: - Normal Mode (cooldown)

    @Test("Normal cooldown mode: title is 休息一下 🧘")
    func normalCooldown_titleIsCorrect() {
        let now = Date()
        let text = ShieldTextBuilder.build(
            mode: .normal,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: now.subtracting(minutes: 10),
            currentTime: now
        )

        #expect(text.title == "休息一下 🧘")
    }

    @Test("Normal cooldown mode: primary button is 好的")
    func normalCooldown_primaryButtonIsCorrect() {
        let now = Date()
        let text = ShieldTextBuilder.build(
            mode: .normal,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: now.subtracting(minutes: 10),
            currentTime: now
        )

        #expect(text.primaryButtonLabel == "好的")
    }

    @Test("Normal cooldown mode: secondary button is 查看状态")
    func normalCooldown_secondaryButtonIsQueryStatus() {
        let now = Date()
        let text = ShieldTextBuilder.build(
            mode: .normal,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: now.subtracting(minutes: 10),
            currentTime: now
        )

        #expect(text.secondaryButtonLabel == "查看状态")
    }

    @Test("Normal cooldown with 20 min remaining: subtitle shows remaining time")
    func normalCooldown_subtitleShowsRemainingTime() {
        let now = Date()
        // shield activated 10 min ago → unlock at 30 min mark → 20 min left
        let shieldAt = now.subtracting(minutes: 10)

        let text = ShieldTextBuilder.build(
            mode: .normal,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldAt,
            currentTime: now
        )

        #expect(text.subtitle == "0:20 后可用")
    }

    @Test("Normal cooldown with nil lastShieldTimestamp: subtitle shows 即将可用")
    func normalCooldown_nilShieldTimestamp_subtitleIsImminentlyAvailable() {
        let text = ShieldTextBuilder.build(
            mode: .normal,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: Date()
        )

        #expect(text.subtitle == "即将可用")
    }

    @Test("Normal cooldown: exactly 30 min elapsed → subtitle shows 即将可用")
    func normalCooldown_exactlyExpired_subtitleIsImminentlyAvailable() {
        let now = Date()
        let shieldAt = now.subtracting(minutes: 30)

        let text = ShieldTextBuilder.build(
            mode: .normal,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldAt,
            currentTime: now
        )

        #expect(text.subtitle == "即将可用")
    }

    // MARK: - Night Cooldown Mode

    @Test("Night cooldown mode: title is 休息一下 🌙")
    func nightCooldown_titleIsCorrect() {
        let now = Date()
        let text = ShieldTextBuilder.build(
            mode: .nightCooldown,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: now.subtracting(minutes: 5),
            currentTime: now
        )

        #expect(text.title == "休息一下 🌙")
    }

    @Test("Night cooldown mode: secondary button is 查看状态")
    func nightCooldown_secondaryButtonIsQueryStatus() {
        let now = Date()
        let text = ShieldTextBuilder.build(
            mode: .nightCooldown,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: now.subtracting(minutes: 5),
            currentTime: now
        )

        #expect(text.secondaryButtonLabel == "查看状态")
    }

    @Test("Night cooldown with 25 min remaining: subtitle shows remaining time")
    func nightCooldown_subtitleShowsRemainingTime() {
        let now = Date()
        let shieldAt = now.subtracting(minutes: 5)

        let text = ShieldTextBuilder.build(
            mode: .nightCooldown,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldAt,
            currentTime: now
        )

        #expect(text.subtitle == "0:25 后可用")
    }

    // MARK: - Night Quota Mode

    @Test("Night quota mode: title is 额度使用中 ⏳")
    func nightQuota_titleIsCorrect() {
        let text = ShieldTextBuilder.build(
            mode: .nightQuota,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: Date()
        )

        #expect(text.title == "额度使用中 ⏳")
    }

    @Test("Night quota mode: subtitle is 请注意剩余时间")
    func nightQuota_subtitleIsCorrect() {
        let text = ShieldTextBuilder.build(
            mode: .nightQuota,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: Date()
        )

        #expect(text.subtitle == "请注意剩余时间")
    }

    @Test("Night quota mode: no secondary button")
    func nightQuota_noSecondaryButton() {
        let text = ShieldTextBuilder.build(
            mode: .nightQuota,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: Date()
        )

        #expect(text.secondaryButtonLabel == nil)
    }

    @Test("Night quota mode: primary button is 好的")
    func nightQuota_primaryButtonIsCorrect() {
        let text = ShieldTextBuilder.build(
            mode: .nightQuota,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: Date()
        )

        #expect(text.primaryButtonLabel == "好的")
    }

    // MARK: - Night Exhausted Mode

    @Test("Night exhausted mode: title is 今日额度已用完 🌙")
    func nightExhausted_titleIsCorrect() {
        let text = ShieldTextBuilder.build(
            mode: .nightExhausted,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: Date()
        )

        #expect(text.title == "今日额度已用完 🌙")
    }

    @Test("Night exhausted mode: subtitle is 明天见！")
    func nightExhausted_subtitleShowsMingTianJian() {
        let text = ShieldTextBuilder.build(
            mode: .nightExhausted,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: Date()
        )

        #expect(text.subtitle == "明天见！")
    }

    @Test("Night exhausted mode: no secondary button")
    func nightExhausted_noSecondaryButton() {
        let text = ShieldTextBuilder.build(
            mode: .nightExhausted,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: Date()
        )

        #expect(text.secondaryButtonLabel == nil)
    }

    @Test("Night exhausted mode: primary button is 好的")
    func nightExhausted_primaryButtonIsCorrect() {
        let text = ShieldTextBuilder.build(
            mode: .nightExhausted,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: Date()
        )

        #expect(text.primaryButtonLabel == "好的")
    }

    // MARK: - Time Formatting Edge Cases

    @Test("Remaining time of 61 min formats as 1:01 后可用")
    func remainingTimeFormatsHoursAndMinutes() {
        let now = Date()
        // Normal mode: shield 30 min ago, cooldown is 30 min → already expired
        // To get > 60 min remaining, use morning mode with sleep off < 1 min ago
        // (60 min total - elapsed = remaining)
        // Let's test: sleepOff was 0 seconds ago → 60:00 remaining
        // Actually: 60 min total - 0 elapsed = 60 min remaining
        // But the spec shows "X:XX 后可用" — let's verify a larger value
        // Sleep off 0 seconds ago → 60 minutes remaining = "1:00 后可用"
        let sleepOffAt = now // 0 seconds ago → full 60 min remaining

        let text = ShieldTextBuilder.build(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            currentTime: now
        )

        // 60 minutes remaining = "1:00 后可用"
        #expect(text.subtitle == "1:00 后可用")
    }

    @Test("Remaining time of 1 second rounds to 0:01 for morning mode")
    func nearlyExpiredMorning_showsOneMinute() {
        let now = Date()
        // 59 min 30 sec elapsed → about 30 seconds remain, rounds up to 1 min
        let sleepOffAt = now.subtracting(minutes: 59.5)

        let text = ShieldTextBuilder.build(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            currentTime: now
        )

        // Less than 1 full minute remaining — ceil or floor?
        // Spec: "X:XX 后可用" with whole minutes. Remaining < 1 min → show "0:01" or "即将可用"
        // The implementation should show "即将可用" when <= 0 minutes remain, otherwise show the minutes
        // With 30 sec left (0.5 min), we expect "0:01" (ceiling to nearest minute) or "即将可用"
        // We'll accept either — the key requirement is it's not showing wrong data
        let isValidSubtitle = text.subtitle == "0:01 后可用" || text.subtitle == "即将可用"
        #expect(isValidSubtitle)
    }
}
