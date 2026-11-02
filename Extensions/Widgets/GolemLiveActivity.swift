import ActivityKit
import GolemKit
import SwiftUI
import WidgetKit

/// The timer in the Dynamic Island.
///
/// iOS ticks the timer by itself; the app only says when it started and
/// when the time runs out. Collapsed, the Island is a single slim line:
/// eyes on the left, timer on the right.
///
/// Within the limit the golem is only watching: white eyes, and a
/// long-press shows the group, the time so far and a bar filling up to
/// the limit. Past it he's awake and angry: red eyes, a red timer counting
/// on, and, expanded, his question in place of the bar. `LiveTimer` makes
/// the Island pop open at that moment.
///
/// While you're away the timer stays alive but empty, so the Island looks
/// as if it weren't there (see `LiveTimer` for why).
///
/// The Lock Screen gets the same line. It rarely shows, because you're
/// not scrolling while the phone is locked.
///
/// Tapping it opens a talk with the golem about its group (`DeepLink`).
struct GolemLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GolemActivityAttributes.self) { context in
            LockScreenTimer(state: context.state, isAngry: isAngry(context))
                .padding()
                .widgetURL(DeepLink.talk(groupID: context.state.groupID))
        } dynamicIsland: { context in
            let angry = isAngry(context)
            let away = context.state.isAway
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    if !away {
                        HStack(spacing: 6) {
                            GolemEyes(isAngry: angry)
                            Text(context.state.groupName)
                                .font(.headline)
                                .foregroundStyle(angry ? .red : .white)
                                .lineLimit(1)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if !away {
                        TimerText(state: context.state, isAngry: angry, width: 64)
                            .font(.headline.monospacedDigit())
                    }
                }
                // The slots beside the camera are narrow, so the bar and the
                // golem's question go in the space below.
                DynamicIslandExpandedRegion(.bottom) {
                    if away {
                        EmptyView()
                    } else if angry {
                        Text(GolemVoice.islandQuestion)
                            .font(.system(.title3, design: .serif).weight(.semibold))
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    } else {
                        LimitBar(state: context.state)
                    }
                }
            } compactLeading: {
                if !away {
                    // Inset so both eyes clear the Island's rounded end.
                    GolemEyes(isAngry: angry)
                        .padding(.leading, 6)
                }
            } compactTrailing: {
                if !away {
                    TimerText(state: context.state, isAngry: angry)
                        .font(.system(size: 15, weight: .semibold).monospacedDigit())
                }
            } minimal: {
                if !away {
                    GolemEyes(isAngry: angry)
                }
            }
            .keylineTint(angry ? .red : nil)
            .widgetURL(DeepLink.talk(groupID: context.state.groupID))
        }
    }

    /// Over the limit: either already when the timer appeared, or since
    /// iOS marked it stale at the limit.
    private func isAngry(_ context: ActivityViewContext<GolemActivityAttributes>) -> Bool {
        !context.state.isAway && (context.state.isOverLimit || context.isStale)
    }
}

/// The golem's eyes. Uses the "GolemEye" image from this extension's asset
/// catalog when it's there, otherwise the SF Symbol `eye.fill`.
/// White while he's watching, red once he's angry.
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

/// A thin bar filling up towards the limit. iOS animates it on its own.
private struct LimitBar: View {
    let state: GolemActivityAttributes.ContentState

    var body: some View {
        ProgressView(timerInterval: state.startedAt...state.limitAt, countsDown: false) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .tint(.white)
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }
}

/// One line on the Lock Screen. While you're away the timer stays alive
/// (see `LiveTimer`), so it says he's asleep instead.
private struct LockScreenTimer: View {
    let state: GolemActivityAttributes.ContentState
    let isAngry: Bool

    var body: some View {
        HStack {
            if state.isAway {
                Text(GolemVoice.lockScreenAsleep)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                GolemEyes(isAngry: isAngry, calmColor: .primary)
                Text(state.groupName)
                    .font(.headline)
                Spacer()
                TimerText(state: state, isAngry: isAngry, width: 80, calmColor: .primary)
                    .font(.title2.monospacedDigit())
            }
        }
    }
}
