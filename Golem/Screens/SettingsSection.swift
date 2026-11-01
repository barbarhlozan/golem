import GolemKit
import SwiftUI

/// The break length and the plea rules, as editable form rows.
struct SettingsSection: View {
    @Binding var settings: GolemSettings

    var body: some View {
        Section {
            Stepper(
                "Reset after a \(settings.breakMinutes) min break",
                value: $settings.breakMinutes,
                in: 1...120
            )
        } header: {
            Text("Breaks")
        } footer: {
            Text("Stay away from a group's apps this long and its timer starts again from zero.")
        }

        Section("Pleading") {
            Stepper(
                "Reads for \(settings.pleaRules.waitSeconds) s",
                value: $settings.pleaRules.waitSeconds,
                in: 0...300,
                step: 5
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
