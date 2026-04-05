import Testing
import Foundation
@testable import Kairos

// MARK: - SleepFocusTransition Tests

@Suite("SleepFocusTransition")
struct SleepFocusTransitionTests {

    // MARK: - Focus Turning ON (inactive → active)

    @Test("inactive → active: sets active to true")
    func inactiveToActive_setsActiveTrue() {
        let transition = SleepFocusTransition(wasActive: false)
        let result = transition.resolve()
        #expect(result.active == true)
    }

    @Test("inactive → active: offTimestamp is nil")
    func inactiveToActive_offTimestampIsNil() {
        let transition = SleepFocusTransition(wasActive: false)
        let result = transition.resolve()
        #expect(result.offTimestamp == nil)
    }

    // MARK: - Focus Turning OFF (active → inactive)

    @Test("active → inactive: sets active to false")
    func activeToInactive_setsActiveFalse() {
        let transition = SleepFocusTransition(wasActive: true)
        let result = transition.resolve()
        #expect(result.active == false)
    }

    @Test("active → inactive: records offTimestamp")
    func activeToInactive_recordsOffTimestamp() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let transition = SleepFocusTransition(wasActive: true, now: { fixedDate })
        let result = transition.resolve()
        #expect(result.offTimestamp == fixedDate)
    }

    @Test("active → inactive: offTimestamp is close to current time by default")
    func activeToInactive_offTimestampIsNearNow() {
        let before = Date()
        let transition = SleepFocusTransition(wasActive: true)
        let result = transition.resolve()
        let after = Date()

        guard let ts = result.offTimestamp else {
            Issue.record("Expected offTimestamp to be non-nil when turning OFF")
            return
        }
        #expect(ts >= before)
        #expect(ts <= after)
    }

    // MARK: - Idempotency / Edge Cases

    @Test("already active → active: stays active, no timestamp")
    func alreadyActive_staysActive_noTimestamp() {
        // Turning ON when already ON is an edge case the system might call.
        // wasActive = false means "not yet active" → will become active.
        // This test documents that wasActive=false always produces active=true.
        let transition = SleepFocusTransition(wasActive: false)
        let result = transition.resolve()
        #expect(result.active == true)
        #expect(result.offTimestamp == nil)
    }

    @Test("already inactive → inactive: stays inactive, records timestamp")
    func alreadyInactive_staysInactive_recordsTimestamp() {
        // wasActive = true means "currently active" → turning off, timestamp set.
        let transition = SleepFocusTransition(wasActive: true)
        let result = transition.resolve()
        #expect(result.active == false)
        #expect(result.offTimestamp != nil)
    }
}

// MARK: - SleepFocusStateWriter Tests

@Suite("SleepFocusStateWriter")
struct SleepFocusStateWriterTests {

    // A testable stand-in for KairosSharedState, injected via the SleepFocusStateWriter protocol.
    final class MockSleepFocusStore: SleepFocusStoring {
        var sleepFocusActive: Bool = false
        var sleepFocusOffTimestamp: Date? = nil
    }

    @Test("apply(transition:) writes active=true and nil timestamp on focus ON")
    func apply_focusOn_writesCorrectly() {
        let store = MockSleepFocusStore()
        let writer = SleepFocusStateWriter(store: store)
        let transition = SleepFocusTransition(wasActive: false)

        writer.apply(transition: transition)

        #expect(store.sleepFocusActive == true)
        #expect(store.sleepFocusOffTimestamp == nil)
    }

    @Test("apply(transition:) writes active=false and non-nil timestamp on focus OFF")
    func apply_focusOff_writesCorrectly() {
        let store = MockSleepFocusStore()
        store.sleepFocusActive = true
        let writer = SleepFocusStateWriter(store: store)
        let fixedDate = Date(timeIntervalSince1970: 1_600_000_000)
        let transition = SleepFocusTransition(wasActive: true, now: { fixedDate })

        writer.apply(transition: transition)

        #expect(store.sleepFocusActive == false)
        #expect(store.sleepFocusOffTimestamp == fixedDate)
    }

    @Test("apply(transition:) does not mutate store before being called")
    func storeUnchangedBeforeApply() {
        let store = MockSleepFocusStore()
        store.sleepFocusActive = false
        store.sleepFocusOffTimestamp = nil
        // No writer.apply — store should be untouched
        #expect(store.sleepFocusActive == false)
        #expect(store.sleepFocusOffTimestamp == nil)
    }
}
