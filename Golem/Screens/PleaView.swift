import Combine
import GolemKit
import SwiftUI

/// Where you make your case for more time. The rules live in `PleaRules`;
/// this screen only shows a countdown, a text field, and what's still missing.
struct PleaView: View {
    /// The group whose time is up.
    let group: WatchGroup

    @Environment(GolemModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var secondsWaited = 0
    @State private var reason = ""

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var rules: PleaRules { model.settings.pleaRules }

    private var obstacles: [PleaRules.Obstacle] {
        rules.obstacles(secondsWaited: secondsWaited, reason: reason)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 12) {
                        GolemFigure()
                        Text(GolemVoice.overLimitTitle(groupName: group.name))
                            .golemLine()
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }

                Section(GolemVoice.pleaReasonPrompt) {
                    TextField("Because…", text: $reason, axis: .vertical)
                        .lineLimit(3...6)
                }

                if !obstacles.isEmpty {
                    Section {
                        ForEach(obstacles, id: \.self) { obstacle in
                            Text(hint(for: obstacle))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Button(GolemVoice.grantButton(minutes: rules.grantedMinutes)) {
                        model.grantMoreTime(for: group)
                        dismiss()
                    }
                    .disabled(!obstacles.isEmpty)
                }
            }
            .golemBackground()
            .navigationTitle(GolemVoice.pleaTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(GolemVoice.giveUpButton) { dismiss() }
                }
            }
            .onReceive(ticker) { _ in
                secondsWaited += 1
            }
        }
        .interactiveDismissDisabled()
    }

    private func hint(for obstacle: PleaRules.Obstacle) -> String {
        switch obstacle {
        case .mustWait(let secondsLeft):
            GolemVoice.waitHint(secondsLeft: secondsLeft)
        case .reasonTooShort(let charactersLeft):
            GolemVoice.reasonHint(charactersLeft: charactersLeft)
        }
    }
}
