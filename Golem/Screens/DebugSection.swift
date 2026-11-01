#if DEBUG
import GolemKit
import SwiftUI

/// Debug builds only: pretend an app of a group was opened or closed,
/// exactly as the Shortcuts automations would. Handy in the Simulator.
///
/// The Dynamic Island shows the timer once you leave Golem (swipe home).
struct DebugSection: View {
    @Environment(GolemModel.self) private var model

    var body: some View {
        Section {
            ForEach(model.settings.groups) { group in
                HStack {
                    Text(group.name)
                    Spacer()
                    Button("Open") {
                        Task { await model.simulateAppOpened(in: group) }
                    }
                    .buttonStyle(.bordered)
                    Button("Close") {
                        Task { await model.simulateAppClosed(in: group) }
                    }
                    .buttonStyle(.bordered)
                }
            }
        } header: {
            Text("Test without Shortcuts")
        } footer: {
            Text("Acts like the automations. Swipe home after Open to see the timer.")
        }
    }
}
#endif
