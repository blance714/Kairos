import FamilyControls
import KairosKit
import Observation
import os

/// Manages two separate FamilyActivitySelection groups: general apps and novel/reading apps.
@Observable
final class AppSelectionManager {

    // MARK: - Properties

    var generalSelection = FamilyActivitySelection()
    var novelSelection = FamilyActivitySelection()

    private let sharedState: any KairosSharedStateProtocol
    private let logger = Logger(subsystem: "org.blance.kairos", category: "AppSelection")

    // MARK: - Computed

    /// Whether the general group has at least one app or category selected.
    var hasGeneralSelection: Bool {
        !generalSelection.applicationTokens.isEmpty
            || !generalSelection.categoryTokens.isEmpty
            || !generalSelection.webDomainTokens.isEmpty
    }

    /// Whether the novel group has at least one app or category selected.
    var hasNovelSelection: Bool {
        !novelSelection.applicationTokens.isEmpty
            || !novelSelection.categoryTokens.isEmpty
            || !novelSelection.webDomainTokens.isEmpty
    }

    /// Whether both groups have at least one selection.
    var hasBothSelections: Bool {
        hasGeneralSelection && hasNovelSelection
    }

    // MARK: - Init

    /// Production initializer — uses the real singleton.
    convenience init() {
        self.init(sharedState: KairosSharedState.shared)
    }

    /// Testable initializer — accepts an injected shared state.
    init(sharedState: any KairosSharedStateProtocol) {
        self.sharedState = sharedState
        loadFromSharedState()
    }

    // MARK: - Persistence

    /// Save both selections to shared state for cross-target access.
    func saveSelections() {
        sharedState.generalSelection = generalSelection
        sharedState.novelSelection = novelSelection
        logger.info("Saved app selections to shared state")
    }

    /// Load previously saved selections from shared state.
    func loadFromSharedState() {
        if let saved = sharedState.generalSelection {
            generalSelection = saved
        }
        if let saved = sharedState.novelSelection {
            novelSelection = saved
        }
        logger.debug("Loaded app selections from shared state")
    }
}
