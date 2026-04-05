import FamilyControls
@testable import Kairos

/// In-memory test double for `KairosSharedStateProtocol`.
/// Records reads/writes so tests can assert on side-effects without
/// touching the real App Group UserDefaults.
final class FakeSharedState: KairosSharedStateProtocol {

    // MARK: - Onboarding

    var onboardingCompleted: Bool = false

    // MARK: - Authorization

    var authorizationGranted: Bool = false

    // MARK: - App Selection

    /// Set to true before init to simulate a pre-existing generalSelection.
    var prepopulateGeneralSelection: Bool = false
    /// Set to true before init to simulate a pre-existing novelSelection.
    var prepopulateNovelSelection: Bool = false

    private var _generalSelection: FamilyActivitySelection?
    private var _novelSelection: FamilyActivitySelection?

    // Observation flags
    private(set) var generalSelectionWasSet: Bool = false
    private(set) var generalSelectionWasRead: Bool = false
    private(set) var novelSelectionWasSet: Bool = false
    private(set) var novelSelectionWasRead: Bool = false

    var generalSelection: FamilyActivitySelection? {
        get {
            generalSelectionWasRead = true
            if prepopulateGeneralSelection && _generalSelection == nil {
                return FamilyActivitySelection()
            }
            return _generalSelection
        }
        set {
            generalSelectionWasSet = true
            _generalSelection = newValue
        }
    }

    var novelSelection: FamilyActivitySelection? {
        get {
            novelSelectionWasRead = true
            if prepopulateNovelSelection && _novelSelection == nil {
                return FamilyActivitySelection()
            }
            return _novelSelection
        }
        set {
            novelSelectionWasSet = true
            _novelSelection = newValue
        }
    }
}
