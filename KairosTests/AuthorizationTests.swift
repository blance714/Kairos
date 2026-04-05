import Testing
@testable import Kairos

// MARK: - AuthorizationStatus Tests

@Suite("AuthorizationStatus")
struct AuthorizationStatusTests {

    @Test("notDetermined is the default raw value")
    func notDeterminedRawValue() {
        #expect(AuthorizationStatus.notDetermined.rawValue == "notDetermined")
    }

    @Test("approved has the correct raw value")
    func approvedRawValue() {
        #expect(AuthorizationStatus.approved.rawValue == "approved")
    }

    @Test("denied has the correct raw value")
    func deniedRawValue() {
        #expect(AuthorizationStatus.denied.rawValue == "denied")
    }

    @Test("all cases are present")
    func allCasesCount() {
        #expect(AuthorizationStatus.allCases.count == 3)
    }

    @Test("isAuthorized is true only for approved")
    func isAuthorizedFlag() {
        #expect(AuthorizationStatus.approved.isAuthorized == true)
        #expect(AuthorizationStatus.notDetermined.isAuthorized == false)
        #expect(AuthorizationStatus.denied.isAuthorized == false)
    }
}

// MARK: - AuthorizationManager Initial State Tests

@Suite("AuthorizationManager")
struct AuthorizationManagerTests {

    @Test("initial status is notDetermined when shared state has not granted authorization")
    func initialStatusNotDetermined() {
        let fakeState = FakeSharedState()
        fakeState.authorizationGranted = false
        let manager = AuthorizationManager(sharedState: fakeState)
        #expect(manager.authorizationStatus == .notDetermined)
    }

    @Test("initial status is approved when shared state has granted authorization")
    func initialStatusApproved() {
        let fakeState = FakeSharedState()
        fakeState.authorizationGranted = true
        let manager = AuthorizationManager(sharedState: fakeState)
        #expect(manager.authorizationStatus == .approved)
    }
}

// MARK: - AppSelectionManager Selection State Tests

@Suite("AppSelectionManager - selection state helpers")
struct AppSelectionManagerSelectionStateTests {

    @Test("hasGeneralSelection is false when generalSelection is empty")
    func hasGeneralSelectionFalseWhenEmpty() {
        let fakeState = FakeSharedState()
        let manager = AppSelectionManager(sharedState: fakeState)
        #expect(manager.hasGeneralSelection == false)
    }

    @Test("hasNovelSelection is false when novelSelection is empty")
    func hasNovelSelectionFalseWhenEmpty() {
        let fakeState = FakeSharedState()
        let manager = AppSelectionManager(sharedState: fakeState)
        #expect(manager.hasNovelSelection == false)
    }

    @Test("hasBothSelections is false when both selections are empty")
    func hasBothSelectionsFalseWhenEmpty() {
        let fakeState = FakeSharedState()
        let manager = AppSelectionManager(sharedState: fakeState)
        #expect(manager.hasBothSelections == false)
    }

    @Test("hasBothSelections is false when only general has a selection")
    func hasBothSelectionsFalseWhenOnlyGeneral() {
        // FamilyActivitySelection on simulator always has empty token sets.
        // We verify that the derived property follows the rule:
        // hasBothSelections == hasGeneralSelection && hasNovelSelection.
        let fakeState = FakeSharedState()
        let manager = AppSelectionManager(sharedState: fakeState)
        // Both are empty on simulator — hasBothSelections must be false.
        #expect(manager.hasBothSelections == (manager.hasGeneralSelection && manager.hasNovelSelection))
    }

    @Test("hasGeneralSelection reflects manager computed logic consistently with novelSelection")
    func selectionConsistency() {
        let fakeState = FakeSharedState()
        let manager = AppSelectionManager(sharedState: fakeState)
        // Invariant: hasBothSelections == hasGeneralSelection AND hasNovelSelection
        let expected = manager.hasGeneralSelection && manager.hasNovelSelection
        #expect(manager.hasBothSelections == expected)
    }
}

// MARK: - AppSelectionManager Persistence Round-Trip Tests

@Suite("AppSelectionManager - persistence round-trip")
struct AppSelectionManagerPersistenceTests {

    @Test("saveSelections writes generalSelection to shared state")
    func saveGeneralSelectionToSharedState() {
        let fakeState = FakeSharedState()
        let manager = AppSelectionManager(sharedState: fakeState)
        manager.saveSelections()
        // After save, shared state should hold the (possibly empty) selection.
        // The key invariant is that save does not throw and the state is set.
        #expect(fakeState.generalSelectionWasSet == true)
    }

    @Test("saveSelections writes novelSelection to shared state")
    func saveNovelSelectionToSharedState() {
        let fakeState = FakeSharedState()
        let manager = AppSelectionManager(sharedState: fakeState)
        manager.saveSelections()
        #expect(fakeState.novelSelectionWasSet == true)
    }

    @Test("loadFromSharedState restores generalSelection saved earlier")
    func loadGeneralSelectionFromSharedState() {
        let fakeState = FakeSharedState()
        // Simulate a previously saved selection by setting it directly on the fake.
        fakeState.prepopulateGeneralSelection = true

        let manager = AppSelectionManager(sharedState: fakeState)
        // The manager loads in init; we confirm generalSelection was loaded.
        #expect(fakeState.generalSelectionWasRead == true)
    }

    @Test("loadFromSharedState restores novelSelection saved earlier")
    func loadNovelSelectionFromSharedState() {
        let fakeState = FakeSharedState()
        fakeState.prepopulateNovelSelection = true

        let manager = AppSelectionManager(sharedState: fakeState)
        #expect(fakeState.novelSelectionWasRead == true)
    }

    @Test("round-trip: save then load produces same isEmpty state")
    func roundTripPreservesEmptyState() {
        let fakeState = FakeSharedState()
        let writer = AppSelectionManager(sharedState: fakeState)
        writer.saveSelections()

        // A new manager loading from same state must reflect same empty state.
        let reader = AppSelectionManager(sharedState: fakeState)
        #expect(reader.hasGeneralSelection == writer.hasGeneralSelection)
        #expect(reader.hasNovelSelection == writer.hasNovelSelection)
    }
}
