import GolemKit
import SwiftUI

/// Everything that isn't needed every day: breaks, plea rules, the
/// automation guide, and (full build) Screen Time blocking.
struct SettingsView: View {
    @Environment(GolemModel.self) private var model

    var body: some View {
        @Bindable var model = model

        Form {
            Section {
                NavigationLink("Set up the Shortcuts automations") {
                    SetupGuideView()
                }
            } footer: {
                Text("The automations tell Golem when you open and close your apps, which starts the timer in the Dynamic Island.")
            }

            SettingsSection(settings: $model.settings)

            if Capabilities.screenTime {
                screenTimeSection
            }
        }
        .golemBackground()
        .navigationTitle("Settings")
    }

    @ViewBuilder
    private var screenTimeSection: some View {
        if model.isAuthorized {
            Section {
                if model.settings.isWatching {
                    Button("Stop blocking", role: .destructive) { model.stopWatching() }
                } else {
                    Button("Start blocking") { model.startWatching() }
                }
            } header: {
                Text("Screen Time")
            } footer: {
                Text("Covers a group's apps with the Golem's shield when its time is up. Changes apply the next time you start.")
            }
        } else {
            Section("Screen Time") {
                Text("Golem needs Screen Time access to block apps when your time is up.")
                Button("Allow Screen Time access") {
                    Task { await model.requestPermissions() }
                }
            }
        }
    }
}
