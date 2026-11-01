import GolemKit
import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Decides what the shield over a blocked app looks like.
/// iOS draws it; we can only choose colors, icon, texts and button labels.
final class GolemShieldConfiguration: ShieldConfigurationDataSource {
    private let store = SharedStore()

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        golemShield(appName: application.localizedDisplayName)
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        golemShield(appName: application.localizedDisplayName)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        golemShield(appName: webDomain.domain)
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        golemShield(appName: webDomain.domain)
    }

    private func golemShield(appName: String?) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: .black,
            icon: UIImage(systemName: "eye.fill"),
            title: .init(text: GolemVoice.shieldTitle, color: .white),
            subtitle: .init(
                text: GolemVoice.shieldSubtitle(appName: appName, minutes: store.settings.limitMinutes),
                color: .lightGray
            ),
            primaryButtonLabel: .init(text: GolemVoice.closeButton, color: .black),
            primaryButtonBackgroundColor: .white,
            secondaryButtonLabel: .init(text: GolemVoice.pleadButton, color: .white)
        )
    }
}
