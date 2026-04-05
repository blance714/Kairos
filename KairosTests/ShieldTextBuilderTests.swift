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
        let sleepOffAt = now.subtracting(minutes: 30)

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
        let sleepOffAt = now.subtracting(minutes: 30)

        let text = ShieldTextBuilder.build(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            currentTime: now
        )

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

    @Test("Normal cooldown: exactly 30 min elapsed -> subtitle shows 即将可用")
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

    // MARK: - Night Mode

    @Test("Night mode: title is 额度使用中 🌙")
    func nightMode_titleIsCorrect() {
        let text = ShieldTextBuilder.build(
            mode: .night,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: Date()
        )

        #expect(text.title == "额度使用中 🌙")
    }

    @Test("Night mode: subtitle is 请注意剩余时间")
    func nightMode_subtitleIsCorrect() {
        let text = ShieldTextBuilder.build(
            mode: .night,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: Date()
        )

        #expect(text.subtitle == "请注意剩余时间")
    }

    @Test("Night mode: no secondary button")
    func nightMode_noSecondaryButton() {
        let text = ShieldTextBuilder.build(
            mode: .night,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: Date()
        )

        #expect(text.secondaryButtonLabel == nil)
    }

    @Test("Night mode: primary button is 好的")
    func nightMode_primaryButtonIsCorrect() {
        let text = ShieldTextBuilder.build(
            mode: .night,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: Date()
        )

        #expect(text.primaryButtonLabel == "好的")
    }

    // MARK: - Time Formatting Edge Cases

    @Test("Remaining time of 60 min formats as 1:00 后可用")
    func remainingTimeFormatsHoursAndMinutes() {
        let now = Date()
        let sleepOffAt = now // 0 seconds ago -> full 60 min remaining

        let text = ShieldTextBuilder.build(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            currentTime: now
        )

        #expect(text.subtitle == "1:00 后可用")
    }

    @Test("Remaining time of 1 second rounds to 0:01 for morning mode")
    func nearlyExpiredMorning_showsOneMinute() {
        let now = Date()
        let sleepOffAt = now.subtracting(minutes: 59.5)

        let text = ShieldTextBuilder.build(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            currentTime: now
        )

        let isValidSubtitle = text.subtitle == "0:01 后可用" || text.subtitle == "即将可用"
        #expect(isValidSubtitle)
    }
}
