import GolemKit
import SwiftUI

/// The limit and the plea rules, as editable form rows.
struct SettingsSection: View {
    @Binding var settings: GolemSettings

    var body: some View {
        Section("Limit") {
            Stepper(
                "Step in after \(settings.limitMinutes) min",
                value: $settings.limitMinutes,
                in: GolemSettings.allowedLimitMinutes
            )
        }

        Section("Pleading") {
            Stepper(
                "Wait \(settings.pleaRules.waitSeconds) s",
                value: $settings.pleaRules.waitSeconds,
                in: 0...300,
                step: 10
            )
            Stepper(
                "Reason of \(settings.pleaRules.minimumReasonLength)+ characters",
                value: $settings.pleaRules.minimumReasonLength,
                in: 0...200,
                step: 10
            )
            Stepper(
                "Grants \(settings.pleaRules.grantedMinutes) more min",
                value: $settings.pleaRules.grantedMinutes,
                in: 1...30
            )
        }
    }
}
