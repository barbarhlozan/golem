import SwiftUI

/// The four steps of making a group's two automations. Shown in the
/// first run and in the setup guide, so both say exactly the same.
struct AutomationSteps: View {
    var body: some View {
        step(1, "In **Shortcuts**, tap **Automation** → **+** → **App**.")
        step(2, "Choose the group's apps and tick **Is Opened**. Pick **Run Immediately** and turn off **Notify When Run**.")
        step(3, "Add **Golem › App Opened** and pick the group.")
        step(4, "Do it again with **Is Closed** and **Golem › App Closed**.")
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

/// Opens the Shortcuts app, where the automations are made.
struct OpenShortcutsButton: View {
    var body: some View {
        Button("Open Shortcuts") {
            if let url = URL(string: "shortcuts://") {
                UIApplication.shared.open(url)
            }
        }
    }
}
