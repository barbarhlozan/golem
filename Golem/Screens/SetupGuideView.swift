import GolemKit
import SwiftUI

/// Step-by-step instructions for the Shortcuts automations.
/// Golem can't create them itself; iOS only lets the user do that.
struct SetupGuideView: View {
    @Environment(GolemModel.self) private var model

    var body: some View {
        List {
            Section {
                Text("For each group, create two automations in the Shortcuts app: one for when its apps open, one for when they close.")
            }

            ForEach(model.settings.groups) { group in
                Section(group.name) {
                    step(1, "Open **Shortcuts** → **Automation** → **+** → **App**.")
                    step(2, "Choose the apps for \(group.name), tick **Is Opened**, and choose **Run Immediately**.")
                    step(3, "Add the action **Golem › App Opened** and set the group to **\(group.name)**.")
                    step(4, "Repeat with **Is Closed** and the action **Golem › App Closed**.")
                }
            }

            Section {
                Button("Open Shortcuts") {
                    if let url = URL(string: "shortcuts://") {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
        .navigationTitle("Automations")
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
