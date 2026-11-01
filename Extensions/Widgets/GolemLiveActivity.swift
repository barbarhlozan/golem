import ActivityKit
import GolemKit
import SwiftUI
import WidgetKit

/// The timer in the Dynamic Island and on the Lock Screen.
///
/// iOS ticks the timer by itself; the app only says when it started and
/// when the time runs out. Once the limit is reached the timer stops there.
struct GolemLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GolemActivityAttributes.self) { context in
            LockScreenTimer(groupName: context.attributes.groupName, state: context.state)
                .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.groupName, systemImage: "eye.fill")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerText(state: context.state)
                        .font(.title2.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    TimerProgress(state: context.state)
                }
            } compactLeading: {
                Image(systemName: "eye.fill")
                    .foregroundStyle(context.state.isOverLimit ? .red : .orange)
            } compactTrailing: {
                TimerText(state: context.state)
                    .monospacedDigit()
                    .frame(maxWidth: 44)
            } minimal: {
                Image(systemName: "eye.fill")
                    .foregroundStyle(context.state.isOverLimit ? .red : .orange)
            }
        }
    }
}

/// mm:ss counting up, stopping at the limit. Red if already over.
private struct TimerText: View {
    let state: GolemActivityAttributes.ContentState

    var body: some View {
        if state.isOverLimit {
            Text(state.startedAt, style: .timer)
                .foregroundStyle(.red)
        } else {
            Text(timerInterval: state.startedAt...state.limitAt, countsDown: false)
                .foregroundStyle(.orange)
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
                Label(groupName, systemImage: "eye.fill")
                    .font(.headline)
                Spacer()
                TimerText(state: state)
                    .font(.title2.monospacedDigit())
            }
            TimerProgress(state: state)
        }
    }
}
