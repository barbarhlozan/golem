import ActivityKit
import GolemKit
import SwiftUI
import WidgetKit

/// The timer in the Dynamic Island and on the Lock Screen.
///
/// iOS ticks the timer by itself; the app only says when it started and
/// when the time runs out. The Island is a single slim line: eyes on the
/// left, timer on the right.
///
/// The golem wants to sleep. While you're within the limit his eyes are
/// white; once the time is up he's angry: red eyes, red timer, "Plead with
/// the Golem". The switch happens on its own at the limit, because the app
/// sets the limit as the Live Activity's stale date and iOS redraws it then.
struct GolemLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GolemActivityAttributes.self) { context in
            LockScreenTimer(
                groupName: context.attributes.groupName,
                state: context.state,
                isAngry: isAngry(context)
            )
            .padding()
        } dynamicIsland: { context in
            let angry = isAngry(context)
            return DynamicIsland {
                // Long-press (or a pop-up when reopening an app past the
                // limit): eyes, group and timer on one line…
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        GolemEyes(isAngry: angry)
                        Text(context.attributes.groupName)
                            .font(.headline)
                            .foregroundStyle(angry ? .red : .white)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerText(state: context.state, isAngry: angry, width: 64)
                        .font(.headline.monospacedDigit())
                }
                // …and, once he's angry, the plea in the space below
                // (the slots beside the camera are too narrow for it).
                DynamicIslandExpandedRegion(.bottom) {
                    if angry {
                        Text(GolemVoice.pleadButton)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                }
            } compactLeading: {
                // Inset so both eyes clear the Island's rounded end.
                GolemEyes(isAngry: angry)
                    .padding(.leading, 6)
            } compactTrailing: {
                TimerText(state: context.state, isAngry: angry)
                    .font(.system(size: 15, weight: .semibold).monospacedDigit())
            } minimal: {
                GolemEyes(isAngry: angry)
            }
            .keylineTint(angry ? .red : nil)
        }
    }

    /// Over the limit: either already when the timer appeared, or since
    /// iOS marked it stale at the limit.
    private func isAngry(_ context: ActivityViewContext<GolemActivityAttributes>) -> Bool {
        context.state.isOverLimit || context.isStale
    }
}

/// The golem's eyes. Uses the "GolemEye" image from this extension's asset
/// catalog when it's there, otherwise the SF Symbol `eye.fill`.
/// White while he tolerates you, red once he's angry.
private struct GolemEyes: View {
    let isAngry: Bool
    /// The calm colour: white on the black Island, `.primary` on the Lock Screen.
    var calmColor: Color = .white

    var body: some View {
        icon
            .foregroundStyle(isAngry ? .red : calmColor)
    }

    @ViewBuilder
    private var icon: some View {
        if let custom = UIImage(named: "GolemEye") {
            // The drawing is two eyes side by side, so the frame is wide.
            Image(uiImage: custom)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 16)
        } else {
            Image(systemName: "eye.fill")
        }
    }
}

/// mm:ss counting up. Within the limit it's calm and stops at the limit;
/// once angry it turns red and keeps counting past it.
///
/// Timer texts are greedy and would stretch the Island, so the width is
/// fixed to fit "00:00" and the digits hug the right edge.
private struct TimerText: View {
    let state: GolemActivityAttributes.ContentState
    let isAngry: Bool
    var width: CGFloat = 46
    var calmColor: Color = .white

    var body: some View {
        timer
            .multilineTextAlignment(.trailing)
            .frame(width: width, alignment: .trailing)
    }

    @ViewBuilder
    private var timer: some View {
        if isAngry {
            Text(state.startedAt, style: .timer)
                .foregroundStyle(.red)
        } else {
            Text(timerInterval: state.startedAt...state.limitAt, countsDown: false)
                .foregroundStyle(calmColor)
        }
    }
}

private struct TimerProgress: View {
    let state: GolemActivityAttributes.ContentState
    let isAngry: Bool

    var body: some View {
        if isAngry {
            Text(GolemVoice.pleadButton)
                .foregroundStyle(.red)
        } else {
            ProgressView(timerInterval: state.startedAt...state.limitAt, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .tint(.primary)
        }
    }
}

private struct LockScreenTimer: View {
    let groupName: String
    let state: GolemActivityAttributes.ContentState
    let isAngry: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                GolemEyes(isAngry: isAngry, calmColor: .primary)
                Text(groupName)
                    .font(.headline)
                Spacer()
                TimerText(state: state, isAngry: isAngry, width: 80, calmColor: .primary)
                    .font(.title2.monospacedDigit())
            }
            TimerProgress(state: state, isAngry: isAngry)
        }
    }
}
