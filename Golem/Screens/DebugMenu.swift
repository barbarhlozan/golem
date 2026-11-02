#if DEBUG
import GolemKit
import SwiftUI

/// Debug builds only: every state the app can be in, one tap away.
/// Behind the ladybug on the home screen, so the real screens stay clean.
struct DebugMenu: View {

    @Environment(GolemModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @AppStorage(OnboardingView.doneKey) private var hasOnboarded = false

    var body: some View {
        NavigationStack {
            Form {
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
                    Text("Act like the automations")
                } footer: {
                    Text("After Open, swipe home to see the timer. Coming back to Golem stops it.")
                }

                ForEach(model.settings.groups) { group in
                    Section(group.name) {
                        Button("Open in 4 s (go to another app)") { model.debugOpenLater(group) }
                        Button("Put 20 s before the limit") { model.debugPutNearLimit(group) }
                        Button("Put over the limit") { model.debugPutOverLimit(group) }
                        Button("Send time's-up in 5 s") { model.debugSendTimeUp(group) }
                    }
                }

                Section {
                    Button("Reset all timers", role: .destructive) { model.debugResetTimers() }
                    Button("Replay the first run") {
                        dismiss()
                        hasOnboarded = false
                    }
                }

                Section("Timers") {
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(model.debugSessionLines(), id: \.self) { line in
                                Text(line)
                            }
                        }
                        .font(.footnote.monospaced())
                    }
                }
            }
            .navigationTitle("Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
#endif
