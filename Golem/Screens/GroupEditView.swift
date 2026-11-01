import FamilyControls
import GolemKit
import SwiftUI

/// Name, limit and (with Screen Time) the apps of one group.
struct GroupEditView: View {
    @Binding var group: WatchGroup

    @Environment(GolemModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var isPickingApps = false

    var body: some View {
        Form {
            Section("Name") {
                TextField("e.g. Reels", text: $group.name)
            }

            Section("Limit") {
                Stepper(
                    "Step in after \(group.limitMinutes) min",
                    value: $group.limitMinutes,
                    in: WatchGroup.allowedLimitMinutes
                )
            }

            if Capabilities.screenTime {
                Section("Apps to block") {
                    Button(group.appSelection.isEmpty ? "Choose apps…" : "Change apps…") {
                        isPickingApps = true
                    }
                    AppTokensList(selection: group.appSelection)
                }
            }

            Section {
                Button("Delete group", role: .destructive) {
                    let id = group.id
                    dismiss()
                    // After the screen is gone: removing the group while
                    // this view still holds a binding to it would crash.
                    Task {
                        try? await Task.sleep(for: .milliseconds(500))
                        model.deleteGroup(id: id)
                    }
                }
            } footer: {
                Text("Also delete its two automations in Shortcuts.")
            }
        }
        .golemBackground()
        .navigationTitle(group.name)
        .familyActivityPicker(isPresented: $isPickingApps, selection: $group.appSelection)
    }
}

/// Shows the icons of the picked apps. iOS only lets us draw them via `Label(token)`.
private struct AppTokensList: View {
    let selection: FamilyActivitySelection

    var body: some View {
        ForEach(Array(selection.applicationTokens), id: \.self) { token in
            Label(token)
        }
        ForEach(Array(selection.categoryTokens), id: \.self) { token in
            Label(token)
        }
        ForEach(Array(selection.webDomainTokens), id: \.self) { token in
            Label(token)
        }
    }
}
