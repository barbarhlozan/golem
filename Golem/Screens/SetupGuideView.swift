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
                step(1, "In **Shortcuts**, tap **Automation** → **+** → **App**.")
                step(2, "Choose the group's apps and tick **Is Opened**. Pick **Run Immediately** and turn off **Notify When Run**.")
                step(3, "Add **Golem › App Opened** and pick the group.")
                step(4, "Do it again with **Is Closed** and **Golem › App Closed**.")
            } header: {
                Text("Two automations per group")
            } footer: {
                Text("Groups: \(groupNames). Each one needs its own pair.")
            }

            Section {
                Button("Open Shortcuts") {
                    if let url = URL(string: "shortcuts://") {
                        UIApplication.shared.open(url)
                    }
                }
            }

            Section {
                Text("Locking the phone inside an app doesn't count as closing it, so the timer keeps going. Tap **\(GolemVoice.stopTimerButton)** on the Lock Screen timer, or just open Golem.")
                Text("Optional: add **Golem › Stop Timer** to a **Sleep** or **Focus** automation, so the timer stops at bedtime.")
            } header: {
                Text("Good to know")
            }
        }
        .navigationTitle("Automations")
    }

    private var groupNames: String {
        model.settings.groups.map(\.name).formatted(.list(type: .and))
    }

    private func step(_ number: Int, _ text: LocalizedStringKey) -> some View {
        Label {
            Text(text)
        } icon: {
            Text("\(number)")
                .font(.headline)
        }
    }
}
