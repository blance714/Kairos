import Testing
import Foundation
import KairosKit

// MARK: - Test Helpers

private extension Date {
    func adding(minutes: Double) -> Date {
        addingTimeInterval(minutes * 60)
    }

    func subtracting(minutes: Double) -> Date {
        addingTimeInterval(-(minutes * 60))
    }
}

// MARK: - ShieldUnlockResolver Tests

@Suite("ShieldUnlockResolver")
struct ShieldUnlockResolverTests {

    // MARK: - Morning Mode

    @Test("Morning: nil sleepFocusOffTimestamp -> deny (safe default)")
    func morning_nilSleepFocusOff_denies() {
        let result = ShieldUnlockResolver.resolve(
            mode: .morning,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: Date()
        )

        #expect(result == .deny)
    }

    @Test("Morning: less than 60 min since sleep focus off -> deny")
    func morning_lessThan60Min_denies() {
        let now = Date()
        let sleepOffAt = now.subtracting(minutes: 30)

        let result = ShieldUnlockResolver.resolve(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            currentTime: now
        )

        #expect(result == .deny)
    }

    @Test("Morning: exactly 59 min 59 sec since sleep focus off -> deny")
    func morning_59Min59Sec_denies() {
        let now = Date()
        let sleepOffAt = now.subtracting(minutes: 59).addingTimeInterval(-59)

        let result = ShieldUnlockResolver.resolve(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            currentTime: now
        )

        #expect(result == .deny)
    }

    @Test("Morning: exactly 60 min since sleep focus off -> unlock")
    func morning_exactly60Min_unlocks() {
        let now = Date()
        let sleepOffAt = now.subtracting(minutes: 60)

        let result = ShieldUnlockResolver.resolve(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            currentTime: now
        )

        #expect(result == .unlock)
    }

    @Test("Morning: more than 60 min since sleep focus off -> unlock")
    func morning_moreThan60Min_unlocks() {
        let now = Date()
        let sleepOffAt = now.subtracting(minutes: 90)

        let result = ShieldUnlockResolver.resolve(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            currentTime: now
        )

        #expect(result == .unlock)
    }

    @Test("Morning: 60 min + 1 second since sleep focus off -> unlock")
    func morning_60MinPlusOneSecond_unlocks() {
        let now = Date()
        let sleepOffAt = now.subtracting(minutes: 60).addingTimeInterval(-1)

        let result = ShieldUnlockResolver.resolve(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            currentTime: now
        )

        #expect(result == .unlock)
    }

    // MARK: - Normal Mode (cooldown)

    @Test("Normal: nil lastShieldTimestamp -> deny (safe default)")
    func normal_nilShieldTimestamp_denies() {
        let result = ShieldUnlockResolver.resolve(
            mode: .normal,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: Date()
        )

        #expect(result == .deny)
    }

    @Test("Normal cooldown: less than 30 min since last shield -> deny")
    func normal_lessThan30Min_denies() {
        let now = Date()
        let shieldAt = now.subtracting(minutes: 15)

        let result = ShieldUnlockResolver.resolve(
            mode: .normal,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldAt,
            currentTime: now
        )

        #expect(result == .deny)
    }

    @Test("Normal cooldown: exactly 29 min 59 sec since last shield -> deny")
    func normal_29Min59Sec_denies() {
        let now = Date()
        let shieldAt = now.subtracting(minutes: 29).addingTimeInterval(-59)

        let result = ShieldUnlockResolver.resolve(
            mode: .normal,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldAt,
            currentTime: now
        )

        #expect(result == .deny)
    }

    @Test("Normal cooldown: exactly 30 min since last shield -> unlock")
    func normal_exactly30Min_unlocks() {
        let now = Date()
        let shieldAt = now.subtracting(minutes: 30)

        let result = ShieldUnlockResolver.resolve(
            mode: .normal,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldAt,
            currentTime: now
        )

        #expect(result == .unlock)
    }

    @Test("Normal cooldown: more than 30 min since last shield -> unlock")
    func normal_moreThan30Min_unlocks() {
        let now = Date()
        let shieldAt = now.subtracting(minutes: 45)

        let result = ShieldUnlockResolver.resolve(
            mode: .normal,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldAt,
            currentTime: now
        )

        #expect(result == .unlock)
    }

    // MARK: - Night Mode

    @Test("Night: always deny regardless of timestamps")
    func night_alwaysDenies() {
        let now = Date()
        let result = ShieldUnlockResolver.resolve(
            mode: .night,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: now.subtracting(minutes: 60),
            currentTime: now
        )

        #expect(result == .deny)
    }

    @Test("Night: deny even with nil timestamps")
    func night_nilTimestamps_denies() {
        let result = ShieldUnlockResolver.resolve(
            mode: .night,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            currentTime: Date()
        )

        #expect(result == .deny)
    }

    // MARK: - Edge: Boundary Values

    @Test("Morning: exactly 1 second less than 60 min -> deny")
    func morning_oneSecondShort_denies() {
        let now = Date()
        let sleepOffAt = now.addingTimeInterval(-(60 * 60 - 1))

        let result = ShieldUnlockResolver.resolve(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            currentTime: now
        )

        #expect(result == .deny)
    }

    @Test("Normal: exactly 1 second less than 30 min -> deny")
    func normal_oneSecondShort_denies() {
        let now = Date()
        let shieldAt = now.addingTimeInterval(-(30 * 60 - 1))

        let result = ShieldUnlockResolver.resolve(
            mode: .normal,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldAt,
            currentTime: now
        )

        #expect(result == .deny)
    }
}
