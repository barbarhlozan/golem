import ActivityKit
import GolemKit
import SwiftUI
import WidgetKit

/// The timer in the Dynamic Island and on the Lock Screen.
///
/// iOS ticks the timer by itself; the app only says when it started and
/// when the time runs out. Once the limit is reached the timer stops there.
/// The Island is kept to a single slim line: eye on the left, timer on the right.
struct GolemLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GolemActivityAttributes.self) { context in
            LockScreenTimer(groupName: context.attributes.groupName, state: context.state)
                .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                // Long-press: still one line, just with the group's name.
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        GolemEye(state: context.state)
                        Text(context.attributes.groupName)
                            .font(.headline)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerText(state: context.state, width: 64)
                        .font(.headline.monospacedDigit())
                }
            } compactLeading: {
                // Inset so both eyes clear the Island's rounded end.
                GolemEye(state: context.state)
                    .padding(.leading, 6)
            } compactTrailing: {
                TimerText(state: context.state)
                    .font(.system(size: 15, weight: .semibold).monospacedDigit())
            } minimal: {
                GolemEye(state: context.state)
            }
        }
    }
}

/// The golem's eyes. Uses the "GolemEye" image from this extension's asset
/// catalog when it's there, otherwise the SF Symbol `eye.fill`.
/// White on the black Island, even past the limit (the owner prefers it);
/// pass `.primary` where the background is light.
private struct GolemEye: View {
    let state: GolemActivityAttributes.ContentState
    var color: Color = .white

    var body: some View {
        icon
            .foregroundStyle(color)
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

/// mm:ss counting up, stopping at the limit. If the time was already up,
/// it keeps counting past the limit instead.
///
/// Timer texts are greedy and would stretch the Island, so the width is
/// fixed to fit "00:00" and the digits hug the right edge.
private struct TimerText: View {
    let state: GolemActivityAttributes.ContentState
    var width: CGFloat = 46
    /// White on the black Island; pass `.primary` where the background is light.
    var color: Color = .white

    var body: some View {
        timer
            .multilineTextAlignment(.trailing)
            .frame(width: width, alignment: .trailing)
    }

    @ViewBuilder
    private var timer: some View {
        if state.isOverLimit {
            Text(state.startedAt, style: .timer)
                .foregroundStyle(color)
        } else {
            Text(timerInterval: state.startedAt...state.limitAt, countsDown: false)
                .foregroundStyle(color)
        }
    }
}

private struct TimerProgress: View {
    let state: GolemActivityAttributes.ContentState

    var body: some View {
        if state.isOverLimit {
            Text(GolemVoice.timeUpLabel)
                .foregroundStyle(.red)
        } else {
            ProgressView(timerInterval: state.startedAt...state.limitAt, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .tint(.orange)
        }
    }
}

private struct LockScreenTimer: View {
    let groupName: String
    let state: GolemActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                GolemEye(state: state, color: .primary)
                Text(groupName)
                    .font(.headline)
                Spacer()
                TimerText(state: state, width: 80, color: .primary)
                    .font(.title2.monospacedDigit())
            }
            TimerProgress(state: state)
        }
    }
}
