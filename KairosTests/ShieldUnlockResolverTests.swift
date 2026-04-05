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

    @Test("Morning: nil sleepFocusOffTimestamp → deny (safe default)")
    func morning_nilSleepFocusOff_denies() {
        let result = ShieldUnlockResolver.resolve(
            mode: .morning,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            lastUsageTimestamp: nil,
            currentTime: Date()
        )

        #expect(result == .deny)
    }

    @Test("Morning: less than 60 min since sleep focus off → deny")
    func morning_lessThan60Min_denies() {
        let now = Date()
        let sleepOffAt = now.subtracting(minutes: 30) // 30 min ago

        let result = ShieldUnlockResolver.resolve(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            lastUsageTimestamp: nil,
            currentTime: now
        )

        #expect(result == .deny)
    }

    @Test("Morning: exactly 59 min 59 sec since sleep focus off → deny")
    func morning_59Min59Sec_denies() {
        let now = Date()
        let sleepOffAt = now.subtracting(minutes: 59).addingTimeInterval(-59)

        let result = ShieldUnlockResolver.resolve(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            lastUsageTimestamp: nil,
            currentTime: now
        )

        #expect(result == .deny)
    }

    @Test("Morning: exactly 60 min since sleep focus off → unlock")
    func morning_exactly60Min_unlocks() {
        let now = Date()
        let sleepOffAt = now.subtracting(minutes: 60) // exactly 60 min ago

        let result = ShieldUnlockResolver.resolve(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            lastUsageTimestamp: nil,
            currentTime: now
        )

        #expect(result == .unlock)
    }

    @Test("Morning: more than 60 min since sleep focus off → unlock")
    func morning_moreThan60Min_unlocks() {
        let now = Date()
        let sleepOffAt = now.subtracting(minutes: 90) // 90 min ago

        let result = ShieldUnlockResolver.resolve(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            lastUsageTimestamp: nil,
            currentTime: now
        )

        #expect(result == .unlock)
    }

    @Test("Morning: 60 min + 1 second since sleep focus off → unlock")
    func morning_60MinPlusOneSecond_unlocks() {
        let now = Date()
        let sleepOffAt = now.subtracting(minutes: 60).addingTimeInterval(-1)

        let result = ShieldUnlockResolver.resolve(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            lastUsageTimestamp: nil,
            currentTime: now
        )

        #expect(result == .unlock)
    }

    // MARK: - Normal Mode (cooldown)

    @Test("Normal: nil lastShieldTimestamp → deny (safe default)")
    func normal_nilShieldTimestamp_denies() {
        let result = ShieldUnlockResolver.resolve(
            mode: .normal,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            lastUsageTimestamp: nil,
            currentTime: Date()
        )

        #expect(result == .deny)
    }

    @Test("Normal cooldown: less than 30 min since last shield → deny")
    func normal_lessThan30Min_denies() {
        let now = Date()
        let shieldAt = now.subtracting(minutes: 15) // 15 min ago

        let result = ShieldUnlockResolver.resolve(
            mode: .normal,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldAt,
            lastUsageTimestamp: nil,
            currentTime: now
        )

        #expect(result == .deny)
    }

    @Test("Normal cooldown: exactly 29 min 59 sec since last shield → deny")
    func normal_29Min59Sec_denies() {
        let now = Date()
        let shieldAt = now.subtracting(minutes: 29).addingTimeInterval(-59)

        let result = ShieldUnlockResolver.resolve(
            mode: .normal,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldAt,
            lastUsageTimestamp: nil,
            currentTime: now
        )

        #expect(result == .deny)
    }

    @Test("Normal cooldown: exactly 30 min since last shield → unlock")
    func normal_exactly30Min_unlocks() {
        let now = Date()
        let shieldAt = now.subtracting(minutes: 30) // exactly 30 min ago

        let result = ShieldUnlockResolver.resolve(
            mode: .normal,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldAt,
            lastUsageTimestamp: nil,
            currentTime: now
        )

        #expect(result == .unlock)
    }

    @Test("Normal cooldown: more than 30 min since last shield → unlock")
    func normal_moreThan30Min_unlocks() {
        let now = Date()
        let shieldAt = now.subtracting(minutes: 45) // 45 min ago

        let result = ShieldUnlockResolver.resolve(
            mode: .normal,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldAt,
            lastUsageTimestamp: nil,
            currentTime: now
        )

        #expect(result == .unlock)
    }

    // MARK: - Night Cooldown Mode

    @Test("Night cooldown: nil lastShieldTimestamp and nil lastUsageTimestamp → deny")
    func nightCooldown_nilTimestamps_denies() {
        let result = ShieldUnlockResolver.resolve(
            mode: .nightCooldown,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            lastUsageTimestamp: nil,
            currentTime: Date()
        )

        #expect(result == .deny)
    }

    @Test("Night cooldown: < 30 min since shield, < 30 min since usage → deny")
    func nightCooldown_bothTimestampsRecent_denies() {
        let now = Date()
        let shieldAt = now.subtracting(minutes: 10)
        let usageAt = now.subtracting(minutes: 10)

        let result = ShieldUnlockResolver.resolve(
            mode: .nightCooldown,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldAt,
            lastUsageTimestamp: usageAt,
            currentTime: now
        )

        #expect(result == .deny)
    }

    @Test("Night cooldown: >= 30 min since shield → unlock (shield elapsed takes priority)")
    func nightCooldown_shieldElapsed_unlocks() {
        let now = Date()
        let shieldAt = now.subtracting(minutes: 30) // exactly 30 min → elapsed
        let usageAt = now.subtracting(minutes: 10)  // only 10 min → recent

        let result = ShieldUnlockResolver.resolve(
            mode: .nightCooldown,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldAt,
            lastUsageTimestamp: usageAt,
            currentTime: now
        )

        #expect(result == .unlock)
    }

    @Test("Night cooldown: > 30 min since shield → unlock")
    func nightCooldown_shieldMoreThan30Min_unlocks() {
        let now = Date()
        let shieldAt = now.subtracting(minutes: 45)
        let usageAt = now.subtracting(minutes: 5)

        let result = ShieldUnlockResolver.resolve(
            mode: .nightCooldown,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldAt,
            lastUsageTimestamp: usageAt,
            currentTime: now
        )

        #expect(result == .unlock)
    }

    @Test("Night cooldown: < 30 min since shield, >= 30 min since usage → switchToQuota")
    func nightCooldown_shieldRecent_usageElapsed_switchesToQuota() {
        let now = Date()
        let shieldAt = now.subtracting(minutes: 10) // only 10 min since shield
        let usageAt = now.subtracting(minutes: 30)  // exactly 30 min since usage

        let result = ShieldUnlockResolver.resolve(
            mode: .nightCooldown,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldAt,
            lastUsageTimestamp: usageAt,
            currentTime: now
        )

        #expect(result == .switchToQuota)
    }

    @Test("Night cooldown: < 30 min since shield, > 30 min since usage → switchToQuota")
    func nightCooldown_shieldRecent_usageMoreThan30Min_switchesToQuota() {
        let now = Date()
        let shieldAt = now.subtracting(minutes: 5)
        let usageAt = now.subtracting(minutes: 45)

        let result = ShieldUnlockResolver.resolve(
            mode: .nightCooldown,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldAt,
            lastUsageTimestamp: usageAt,
            currentTime: now
        )

        #expect(result == .switchToQuota)
    }

    @Test("Night cooldown: < 30 min since shield, nil lastUsageTimestamp → deny")
    func nightCooldown_shieldRecent_nilUsage_denies() {
        let now = Date()
        let shieldAt = now.subtracting(minutes: 10)

        let result = ShieldUnlockResolver.resolve(
            mode: .nightCooldown,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldAt,
            lastUsageTimestamp: nil,
            currentTime: now
        )

        #expect(result == .deny)
    }

    @Test("Night cooldown: nil lastShieldTimestamp, >= 30 min since usage → switchToQuota")
    func nightCooldown_nilShield_usageElapsed_switchesToQuota() {
        let now = Date()
        let usageAt = now.subtracting(minutes: 30)

        let result = ShieldUnlockResolver.resolve(
            mode: .nightCooldown,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            lastUsageTimestamp: usageAt,
            currentTime: now
        )

        #expect(result == .switchToQuota)
    }

    // MARK: - Night Quota Mode

    @Test("Night quota: always deny regardless of timestamps")
    func nightQuota_alwaysDenies() {
        let now = Date()
        let result = ShieldUnlockResolver.resolve(
            mode: .nightQuota,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: now.subtracting(minutes: 60), // long past
            lastUsageTimestamp: now.subtracting(minutes: 60),
            currentTime: now
        )

        #expect(result == .deny)
    }

    @Test("Night quota: deny even with nil timestamps")
    func nightQuota_nilTimestamps_denies() {
        let result = ShieldUnlockResolver.resolve(
            mode: .nightQuota,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            lastUsageTimestamp: nil,
            currentTime: Date()
        )

        #expect(result == .deny)
    }

    // MARK: - Night Exhausted Mode

    @Test("Night exhausted: always deny")
    func nightExhausted_alwaysDenies() {
        let now = Date()
        let result = ShieldUnlockResolver.resolve(
            mode: .nightExhausted,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: now.subtracting(minutes: 999),
            lastUsageTimestamp: now.subtracting(minutes: 999),
            currentTime: now
        )

        #expect(result == .deny)
    }

    @Test("Night exhausted: deny even with nil timestamps")
    func nightExhausted_nilTimestamps_denies() {
        let result = ShieldUnlockResolver.resolve(
            mode: .nightExhausted,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            lastUsageTimestamp: nil,
            currentTime: Date()
        )

        #expect(result == .deny)
    }

    // MARK: - Parameterized: All modes with nil timestamps default to deny or switchToQuota

    @Test("All modes with nil timestamps return deny (except handled cases)",
          arguments: [KairosMode.nightQuota, KairosMode.nightExhausted])
    func alwaysDenyModes_nilTimestamps_deny(mode: KairosMode) {
        let result = ShieldUnlockResolver.resolve(
            mode: mode,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: nil,
            lastUsageTimestamp: nil,
            currentTime: Date()
        )

        #expect(result == .deny)
    }

    // MARK: - Edge: Boundary Values

    @Test("Morning: exactly 1 second less than 60 min → deny")
    func morning_oneSecondShort_denies() {
        let now = Date()
        // 60 min - 1 second elapsed = 59 min 59 sec
        let sleepOffAt = now.addingTimeInterval(-(60 * 60 - 1))

        let result = ShieldUnlockResolver.resolve(
            mode: .morning,
            sleepFocusOffTimestamp: sleepOffAt,
            lastShieldTimestamp: nil,
            lastUsageTimestamp: nil,
            currentTime: now
        )

        #expect(result == .deny)
    }

    @Test("Normal: exactly 1 second less than 30 min → deny")
    func normal_oneSecondShort_denies() {
        let now = Date()
        let shieldAt = now.addingTimeInterval(-(30 * 60 - 1))

        let result = ShieldUnlockResolver.resolve(
            mode: .normal,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldAt,
            lastUsageTimestamp: nil,
            currentTime: now
        )

        #expect(result == .deny)
    }

    @Test("Night cooldown: shield exactly 1 sec less than 30 min, usage exactly 30 min → switchToQuota")
    func nightCooldown_shieldOneSecShort_usageExact_switchesToQuota() {
        let now = Date()
        let shieldAt = now.addingTimeInterval(-(30 * 60 - 1))  // 29 min 59 sec ago
        let usageAt = now.subtracting(minutes: 30)              // exactly 30 min ago

        let result = ShieldUnlockResolver.resolve(
            mode: .nightCooldown,
            sleepFocusOffTimestamp: nil,
            lastShieldTimestamp: shieldAt,
            lastUsageTimestamp: usageAt,
            currentTime: now
        )

        #expect(result == .switchToQuota)
    }
}
