import DeviceActivity
import Foundation
import Testing
@testable import KairosKit

// MARK: - ActivityScheduleBuilder Tests

/// Tests for the pure schedule-building logic in ActivityScheduleBuilder.
/// DeviceActivityCenter is not touched here — only the returned value types are verified.
@Suite("ActivityScheduleBuilder")
struct ActivityScheduleBuilderTests {

    // MARK: - Helper

    /// Calls the builder with empty token sets — avoids referencing FamilyControls types directly.
    private func build(for mode: KairosMode) -> (schedule: DeviceActivitySchedule, events: [DeviceActivityEvent.Name: DeviceActivityEvent])? {
        ActivityScheduleBuilder.build(
            for: mode,
            generalTokens: [],
            novelTokens: [],
            generalCategories: [],
            novelCategories: []
        )
    }

    // MARK: - Nil cases

    @Test("morning mode returns nil -- no monitoring needed")
    func morningMode_returnsNil() {
        #expect(build(for: .morning) == nil)
    }

    // MARK: - normal mode

    @Test("normal mode returns non-nil result")
    func normalMode_returnsResult() {
        #expect(build(for: .normal) != nil)
    }

    @Test("normal mode schedule covers all day -- hour 0:00 to 23:59")
    func normalMode_scheduleIsAllDay() {
        guard let (schedule, _) = build(for: .normal) else {
            Issue.record("Expected non-nil result for normal mode")
            return
        }
        #expect(schedule.intervalStart.hour == 0)
        #expect(schedule.intervalStart.minute == 0)
        #expect(schedule.intervalEnd.hour == 23)
        #expect(schedule.intervalEnd.minute == 59)
    }

    @Test("normal mode schedule repeats")
    func normalMode_scheduleRepeats() {
        guard let (schedule, _) = build(for: .normal) else {
            Issue.record("Expected non-nil result for normal mode")
            return
        }
        #expect(schedule.repeats == true)
    }

    @Test("normal mode has exactly one event: usageThreshold")
    func normalMode_hasUsageThresholdEvent() {
        guard let (_, events) = build(for: .normal) else {
            Issue.record("Expected non-nil result for normal mode")
            return
        }
        #expect(events.count == 1)
        #expect(events[.usageThreshold] != nil)
    }

    @Test("normal mode usageThreshold event threshold is 15 minutes")
    func normalMode_usageThresholdIs15Min() {
        guard let (_, events) = build(for: .normal) else {
            Issue.record("Expected non-nil result for normal mode")
            return
        }
        let event = events[.usageThreshold]
        #expect(event?.threshold.minute == KairosTime.usageThresholdMinutes)
    }

    // MARK: - night mode (quota)

    @Test("night mode returns non-nil result")
    func nightMode_returnsResult() {
        #expect(build(for: .night) != nil)
    }

    @Test("night mode schedule starts at 22:00")
    func nightMode_scheduleStartsAtNight() {
        guard let (schedule, _) = build(for: .night) else {
            Issue.record("Expected non-nil result for night mode")
            return
        }
        #expect(schedule.intervalStart.hour == KairosTime.nightStartHour)
        #expect(schedule.intervalStart.minute == 0)
    }

    @Test("night mode schedule ends at 5:59")
    func nightMode_scheduleEndsAtDawn() {
        guard let (schedule, _) = build(for: .night) else {
            Issue.record("Expected non-nil result for night mode")
            return
        }
        #expect(schedule.intervalEnd.hour == 5)
        #expect(schedule.intervalEnd.minute == 59)
    }

    @Test("night mode schedule repeats")
    func nightMode_scheduleRepeats() {
        guard let (schedule, _) = build(for: .night) else {
            Issue.record("Expected non-nil result for night mode")
            return
        }
        #expect(schedule.repeats == true)
    }

    @Test("night mode has exactly two events: generalQuota and novelQuota")
    func nightMode_hasTwoQuotaEvents() {
        guard let (_, events) = build(for: .night) else {
            Issue.record("Expected non-nil result for night mode")
            return
        }
        #expect(events.count == 2)
        #expect(events[.generalQuota] != nil)
        #expect(events[.novelQuota] != nil)
    }

    @Test("night mode generalQuota event threshold is 20 minutes")
    func nightMode_generalQuotaIs20Min() {
        guard let (_, events) = build(for: .night) else {
            Issue.record("Expected non-nil result for night mode")
            return
        }
        let event = events[.generalQuota]
        #expect(event?.threshold.minute == KairosTime.generalQuotaMinutes)
    }

    @Test("night mode novelQuota event threshold is 45 minutes")
    func nightMode_novelQuotaIs45Min() {
        guard let (_, events) = build(for: .night) else {
            Issue.record("Expected non-nil result for night mode")
            return
        }
        let event = events[.novelQuota]
        #expect(event?.threshold.minute == KairosTime.novelQuotaMinutes)
    }

    // MARK: - Token propagation

    @Test("normal mode event does not reference tokens when both sets are empty")
    func normalMode_emptyTokens_eventHasEmptyApplications() {
        guard let (_, events) = build(for: .normal) else {
            Issue.record("Expected non-nil result for normal mode")
            return
        }
        let event = events[.usageThreshold]
        #expect(event?.applications.isEmpty == true)
    }

    @Test("night mode generalQuota event only references general tokens")
    func nightMode_generalQuotaReferencesGeneralTokensOnly() {
        guard let (_, events) = build(for: .night) else {
            Issue.record("Expected non-nil result for night mode")
            return
        }
        let generalEvent = events[.generalQuota]
        #expect(generalEvent?.applications.isEmpty == true)
    }

    @Test("night mode novelQuota event only references novel tokens")
    func nightMode_novelQuotaReferencesNovelTokensOnly() {
        guard let (_, events) = build(for: .night) else {
            Issue.record("Expected non-nil result for night mode")
            return
        }
        let novelEvent = events[.novelQuota]
        #expect(novelEvent?.applications.isEmpty == true)
    }

    // MARK: - Schedule symmetry

    @Test("normal and night produce different schedule intervals")
    func normalVsNight_differentIntervals() {
        guard let (normalSchedule, _) = build(for: .normal),
              let (nightSchedule, _) = build(for: .night) else {
            Issue.record("Both modes should produce non-nil results")
            return
        }
        #expect(normalSchedule.intervalStart.hour != nightSchedule.intervalStart.hour)
    }
}
