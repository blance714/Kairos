import ManagedSettings
import KairosKit
import Foundation

// Make sure this class name matches NSExtensionPrincipalClass in Info.plist.
class ShieldActionExtension: ShieldActionDelegate {

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }

    // MARK: - Private

    private func handleAction(
        _ action: ShieldAction,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)

        case .secondaryButtonPressed:
            let state = KairosSharedState.shared
            let unlockAction = ShieldUnlockResolver.resolve(
                mode: state.currentMode,
                sleepFocusOffTimestamp: state.sleepFocusOffTimestamp,
                lastShieldTimestamp: state.lastShieldTimestamp
            )

            switch unlockAction {
            case .deny:
                completionHandler(.close)

            case .unlock:
                clearAllShields()
                completionHandler(.close)
            }

        @unknown default:
            completionHandler(.close)
        }
    }

    private func clearAllShields() {
        ManagedSettingsStore(named: .morningLock).clearAllSettings()
        ManagedSettingsStore(named: .cooldownLock).clearAllSettings()
        ManagedSettingsStore(named: .quotaLock).clearAllSettings()
    }
}
