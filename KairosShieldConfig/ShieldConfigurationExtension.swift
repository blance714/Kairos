import ManagedSettings
import ManagedSettingsUI
import UIKit
import KairosKit

// Make sure this class name matches NSExtensionPrincipalClass in Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        buildConfiguration()
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        buildConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        buildConfiguration()
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        buildConfiguration()
    }

    // MARK: - Private

    private func buildConfiguration() -> ShieldConfiguration {
        let state = KairosSharedState.shared
        let text = ShieldTextBuilder.build(
            mode: state.currentMode,
            sleepFocusOffTimestamp: state.sleepFocusOffTimestamp,
            lastShieldTimestamp: state.lastShieldTimestamp
        )

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: .secondarySystemBackground,
            title: ShieldConfiguration.Label(text: text.title, color: .label),
            subtitle: ShieldConfiguration.Label(text: text.subtitle, color: .secondaryLabel),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: text.primaryButtonLabel,
                color: .white
            ),
            primaryButtonBackgroundColor: .systemBlue,
            secondaryButtonLabel: text.secondaryButtonLabel.map {
                ShieldConfiguration.Label(text: $0, color: .systemBlue)
            }
        )
    }
}
