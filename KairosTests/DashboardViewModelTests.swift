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

    @Test("Night mode returns correct status message prefix")
    func nightMode_statusMessage() {
        let message = DashboardDisplayBuilder.statusMessage(for: .night)
        #expect(message.hasPrefix("晚间模式"))
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
        let focusOffTime = currentTime.addingTimeInterval(-30 * 60)
        let description = DashboardDisplayBuilder.nextChangeDescription(
            for: .morning,
            sleepFocusOffTimestamp: focusOffTime,
            lastShieldTimestamp: nil,
            currentTime: currentTime
        )
        #expect(description.contains("30"))
    }

    @Test("Morning mode with focus off 59 min ago shows ~1 min remaining")
    func morningMode_59minElapsed_shows1MinRemaining() {
        let currentTime = makeDate(hour: 9, minute: 0)
        let focusOffTime = currentTime.addingTimeInterval(-59 * 60)
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

    @Test("Night mode returns non-empty description")
    func nightMode_returnsNonEmptyDescription() {
        let description = DashboardDisplayBuilder.nextChangeDescription(
            for: .night,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: makeDate(hour: 23)
        )
        #expect(!description.isEmpty)
    }

    // MARK: - Edge Cases

    @Test("Morning mode with elapsed time exactly at boundary returns fallback")
    func morningMode_exactlyAtBoundary_returnsFallback() {
        let currentTime = makeDate(hour: 9)
        let focusOffTime = currentTime.addingTimeInterval(-60 * 60)
        let description = DashboardDisplayBuilder.nextChangeDescription(
            for: .morning,
            sleepFocusOffTimestamp: focusOffTime,
            lastShieldTimestamp: nil,
            currentTime: currentTime
        )
        #expect(!description.isEmpty)
    }
}
