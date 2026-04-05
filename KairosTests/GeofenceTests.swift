import Testing
@testable import Kairos

// MARK: - GeofenceEvent Tests

@Suite("GeofenceEvent Handler")
struct GeofenceEventHandlerTests {

    // MARK: - Enter Region

    @Test("Entering home region returns setAtHome(true)")
    func enteringHomeRegionReturnsSetAtHomeTrue() {
        let handler = GeofenceEventHandler()
        let action = handler.handleEvent(.regionEntered(identifier: GeofenceIdentifier.home))
        #expect(action == .setAtHome(true))
    }

    @Test("Entering unknown region returns no-op")
    func enteringUnknownRegionReturnsNoOp() {
        let handler = GeofenceEventHandler()
        let action = handler.handleEvent(.regionEntered(identifier: "unknown-region"))
        #expect(action == .noOp)
    }

    // MARK: - Exit Region

    @Test("Exiting home region returns setAtHome(false)")
    func exitingHomeRegionReturnsSetAtHomeFalse() {
        let handler = GeofenceEventHandler()
        let action = handler.handleEvent(.regionExited(identifier: GeofenceIdentifier.home))
        #expect(action == .setAtHome(false))
    }

    @Test("Exiting unknown region returns no-op")
    func exitingUnknownRegionReturnsNoOp() {
        let handler = GeofenceEventHandler()
        let action = handler.handleEvent(.regionExited(identifier: "unknown-region"))
        #expect(action == .noOp)
    }

    // MARK: - Unknown / Unsatisfied Condition

    @Test("Unknown condition state returns no-op")
    func unknownConditionStateReturnsNoOp() {
        let handler = GeofenceEventHandler()
        let action = handler.handleEvent(.unknown(identifier: GeofenceIdentifier.home))
        #expect(action == .noOp)
    }

    @Test("Unsatisfied condition returns no-op")
    func unsatisfiedConditionReturnsNoOp() {
        let handler = GeofenceEventHandler()
        let action = handler.handleEvent(.unsatisfied(identifier: GeofenceIdentifier.home))
        #expect(action == .noOp)
    }
}

// MARK: - GeofenceAction Tests

@Suite("GeofenceAction Equality")
struct GeofenceActionTests {

    @Test("setAtHome(true) is not equal to setAtHome(false)")
    func setAtHomeTrueNotEqualToFalse() {
        let trueAction = GeofenceAction.setAtHome(true)
        let falseAction = GeofenceAction.setAtHome(false)
        #expect(trueAction != falseAction)
    }

    @Test("noOp equals noOp")
    func noOpEqualsNoOp() {
        #expect(GeofenceAction.noOp == GeofenceAction.noOp)
    }
}

// MARK: - HomeLocation Storage Tests

@Suite("HomeLocation storage via mock state")
struct HomeLocationStorageTests {

    @Test("Saving home coordinates stores latitude and longitude")
    func savingHomeCoordsStoresValues() {
        let store = MockGeofenceStore()
        store.homeLatitude = 37.3318
        store.homeLongitude = -122.0312
        store.homeLocationSet = true

        #expect(store.homeLatitude == 37.3318)
        #expect(store.homeLongitude == -122.0312)
        #expect(store.homeLocationSet == true)
    }

    @Test("Default home location is not set")
    func defaultHomeLocationIsNotSet() {
        let store = MockGeofenceStore()
        #expect(store.homeLocationSet == false)
        #expect(store.homeLatitude == 0.0)
        #expect(store.homeLongitude == 0.0)
    }

    @Test("isAtHome defaults to false")
    func isAtHomeDefaultsFalse() {
        let store = MockGeofenceStore()
        #expect(store.isAtHome == false)
    }

    @Test("isAtHome can be toggled true then false")
    func isAtHomeCanToggle() {
        let store = MockGeofenceStore()
        store.isAtHome = true
        #expect(store.isAtHome == true)
        store.isAtHome = false
        #expect(store.isAtHome == false)
    }

    @Test("Updating home coordinates preserves isAtHome state")
    func updatingCoordsPreservesAtHome() {
        let store = MockGeofenceStore()
        store.isAtHome = true
        store.homeLatitude = 48.8566
        store.homeLongitude = 2.3522
        store.homeLocationSet = true

        #expect(store.isAtHome == true)
        #expect(store.homeLatitude == 48.8566)
        #expect(store.homeLongitude == 2.3522)
    }
}

// MARK: - GeofenceManager State Application Tests

@Suite("GeofenceManager applies actions to store")
struct GeofenceManagerStateTests {

    @Test("applyAction setAtHome(true) updates store isAtHome")
    func applySetAtHomeTrueUpdatesStore() {
        let store = MockGeofenceStore()
        GeofenceActionApplicator.apply(.setAtHome(true), to: store)
        #expect(store.isAtHome == true)
    }

    @Test("applyAction setAtHome(false) updates store isAtHome")
    func applySetAtHomeFalseUpdatesStore() {
        let store = MockGeofenceStore()
        store.isAtHome = true
        GeofenceActionApplicator.apply(.setAtHome(false), to: store)
        #expect(store.isAtHome == false)
    }

    @Test("applyAction noOp does not change store isAtHome")
    func applyNoOpDoesNotChangeStore() {
        let store = MockGeofenceStore()
        store.isAtHome = true
        GeofenceActionApplicator.apply(.noOp, to: store)
        #expect(store.isAtHome == true)
    }
}

// MARK: - GeofenceConfiguration Tests

@Suite("GeofenceConfiguration")
struct GeofenceConfigurationTests {

    @Test("Default radius is 100 metres")
    func defaultRadiusIs100Metres() {
        let config = GeofenceConfiguration()
        #expect(config.radius == 100.0)
    }

    @Test("Custom radius is stored correctly")
    func customRadiusIsStored() {
        let config = GeofenceConfiguration(radius: 250.0)
        #expect(config.radius == 250.0)
    }

    @Test("Default identifier matches GeofenceIdentifier.home")
    func defaultIdentifierIsHome() {
        let config = GeofenceConfiguration()
        #expect(config.identifier == GeofenceIdentifier.home)
    }
}
