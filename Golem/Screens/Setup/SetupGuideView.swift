import GolemKit
import SwiftUI

/// How to create the Shortcuts automations, as short as iOS allows.
///
/// Golem can't create them itself, and automations can't be shared, so the
/// user builds two per group by hand. Golem's actions are listed in
/// Shortcuts on their own (`GolemShortcuts`), so there's nothing to search.
struct SetupGuideView: View {
    @Environment(GolemModel.self) private var model

    var body: some View {
        List {
            Section {
                AutomationSteps()
            } header: {
                Text("Two automations per group")
            } footer: {
                Text("Groups: \(model.settings.groups.map(\.name).formatted(.list(type: .and))). Each one needs its own pair.")
            }

            Section {
                OpenShortcutsButton()
            }

            Section {
                Text("Go to the Home Screen before you lock the phone. iOS doesn't tell Golem about locking, so the timer keeps counting until you leave the app.")
            } header: {
                Text("Good to know")
            }
        }
        .golemBackground()
        .navigationTitle("Automations")
    }
}
