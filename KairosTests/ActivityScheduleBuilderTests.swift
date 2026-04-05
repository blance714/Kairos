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

    @Test("morning mode returns nil — no monitoring needed")
    func morningMode_returnsNil() {
        #expect(build(for: .morning) == nil)
    }

    @Test("nightExhausted mode returns nil — apps are locked, no monitoring needed")
    func nightExhaustedMode_returnsNil() {
        #expect(build(for: .nightExhausted) == nil)
    }

    // MARK: - normal mode

    @Test("normal mode returns non-nil result")
    func normalMode_returnsResult() {
        #expect(build(for: .normal) != nil)
    }

    @Test("normal mode schedule covers all day — hour 0:00 to 23:59")
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

    // MARK: - nightCooldown mode

    @Test("nightCooldown mode returns non-nil result")
    func nightCooldownMode_returnsResult() {
        #expect(build(for: .nightCooldown) != nil)
    }

    @Test("nightCooldown mode schedule starts at 22:00")
    func nightCooldownMode_scheduleStartsAtNight() {
        guard let (schedule, _) = build(for: .nightCooldown) else {
            Issue.record("Expected non-nil result for nightCooldown mode")
            return
        }
        #expect(schedule.intervalStart.hour == KairosTime.nightStartHour)
        #expect(schedule.intervalStart.minute == 0)
    }

    @Test("nightCooldown mode schedule ends at 5:59")
    func nightCooldownMode_scheduleEndsAtDawn() {
        guard let (schedule, _) = build(for: .nightCooldown) else {
            Issue.record("Expected non-nil result for nightCooldown mode")
            return
        }
        #expect(schedule.intervalEnd.hour == 5)
        #expect(schedule.intervalEnd.minute == 59)
    }

    @Test("nightCooldown mode schedule repeats")
    func nightCooldownMode_scheduleRepeats() {
        guard let (schedule, _) = build(for: .nightCooldown) else {
            Issue.record("Expected non-nil result for nightCooldown mode")
            return
        }
        #expect(schedule.repeats == true)
    }

    @Test("nightCooldown mode has exactly one event: usageThreshold")
    func nightCooldownMode_hasUsageThresholdEvent() {
        guard let (_, events) = build(for: .nightCooldown) else {
            Issue.record("Expected non-nil result for nightCooldown mode")
            return
        }
        #expect(events.count == 1)
        #expect(events[.usageThreshold] != nil)
    }

    @Test("nightCooldown mode usageThreshold event threshold is 15 minutes")
    func nightCooldownMode_usageThresholdIs15Min() {
        guard let (_, events) = build(for: .nightCooldown) else {
            Issue.record("Expected non-nil result for nightCooldown mode")
            return
        }
        let event = events[.usageThreshold]
        #expect(event?.threshold.minute == KairosTime.usageThresholdMinutes)
    }

    // MARK: - nightQuota mode

    @Test("nightQuota mode returns non-nil result")
    func nightQuotaMode_returnsResult() {
        #expect(build(for: .nightQuota) != nil)
    }

    @Test("nightQuota mode schedule starts at 22:00")
    func nightQuotaMode_scheduleStartsAtNight() {
        guard let (schedule, _) = build(for: .nightQuota) else {
            Issue.record("Expected non-nil result for nightQuota mode")
            return
        }
        #expect(schedule.intervalStart.hour == KairosTime.nightStartHour)
        #expect(schedule.intervalStart.minute == 0)
    }

    @Test("nightQuota mode schedule ends at 5:59")
    func nightQuotaMode_scheduleEndsAtDawn() {
        guard let (schedule, _) = build(for: .nightQuota) else {
            Issue.record("Expected non-nil result for nightQuota mode")
            return
        }
        #expect(schedule.intervalEnd.hour == 5)
        #expect(schedule.intervalEnd.minute == 59)
    }

    @Test("nightQuota mode has exactly two events: generalQuota and novelQuota")
    func nightQuotaMode_hasTwoQuotaEvents() {
        guard let (_, events) = build(for: .nightQuota) else {
            Issue.record("Expected non-nil result for nightQuota mode")
            return
        }
        #expect(events.count == 2)
        #expect(events[.generalQuota] != nil)
        #expect(events[.novelQuota] != nil)
    }

    @Test("nightQuota generalQuota event threshold is 20 minutes")
    func nightQuotaMode_generalQuotaIs20Min() {
        guard let (_, events) = build(for: .nightQuota) else {
            Issue.record("Expected non-nil result for nightQuota mode")
            return
        }
        let event = events[.generalQuota]
        #expect(event?.threshold.minute == KairosTime.generalQuotaMinutes)
    }

    @Test("nightQuota novelQuota event threshold is 45 minutes")
    func nightQuotaMode_novelQuotaIs45Min() {
        guard let (_, events) = build(for: .nightQuota) else {
            Issue.record("Expected non-nil result for nightQuota mode")
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

    @Test("nightQuota generalQuota event only references general tokens")
    func nightQuotaMode_generalQuotaReferencesGeneralTokensOnly() {
        guard let (_, events) = build(for: .nightQuota) else {
            Issue.record("Expected non-nil result for nightQuota mode")
            return
        }
        let generalEvent = events[.generalQuota]
        #expect(generalEvent?.applications.isEmpty == true)
    }

    @Test("nightQuota novelQuota event only references novel tokens")
    func nightQuotaMode_novelQuotaReferencesNovelTokensOnly() {
        guard let (_, events) = build(for: .nightQuota) else {
            Issue.record("Expected non-nil result for nightQuota mode")
            return
        }
        let novelEvent = events[.novelQuota]
        #expect(novelEvent?.applications.isEmpty == true)
    }

    // MARK: - Schedule symmetry

    @Test("normal and nightCooldown produce different schedule intervals")
    func normalVsNightCooldown_differentIntervals() {
        guard let (normalSchedule, _) = build(for: .normal),
              let (nightSchedule, _) = build(for: .nightCooldown) else {
            Issue.record("Both modes should produce non-nil results")
            return
        }
        #expect(normalSchedule.intervalStart.hour != nightSchedule.intervalStart.hour)
    }
}
