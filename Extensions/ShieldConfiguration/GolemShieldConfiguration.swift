import GolemKit
import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Decides what the shield over a blocked app looks like.
/// iOS draws it; we can only choose colors, icon, texts and button labels.
final class GolemShieldConfiguration: ShieldConfigurationDataSource {
    private let store = SharedStore()

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        golemShield(appName: application.localizedDisplayName, minutes: limitMinutes(of: application))
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        golemShield(appName: application.localizedDisplayName, minutes: limitMinutes(of: application))
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        golemShield(appName: webDomain.domain, minutes: nil)
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        golemShield(appName: webDomain.domain, minutes: nil)
    }

    /// The limit of the group this app belongs to, if we can tell.
    private func limitMinutes(of application: Application) -> Int? {
        store.settings.groups.first { $0.contains(application.token) }?.limitMinutes
    }

    private func golemShield(appName: String?, minutes: Int?) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: .black,
            icon: UIImage(systemName: "eye.fill"),
            title: .init(text: GolemVoice.shieldTitle, color: .white),
            subtitle: .init(
                text: GolemVoice.shieldSubtitle(appName: appName, minutes: minutes),
                color: .lightGray
            ),
            primaryButtonLabel: .init(text: GolemVoice.closeButton, color: .black),
            primaryButtonBackgroundColor: .white
        )
    }
}
