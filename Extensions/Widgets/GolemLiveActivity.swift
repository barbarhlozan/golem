import ActivityKit
import GolemKit
import SwiftUI
import WidgetKit

/// The timer in the Dynamic Island.
///
/// iOS ticks the timer by itself; the app only says when it started and
/// when the time runs out. Collapsed, the Island is a single slim line:
/// eyes on the left, timer on the right. When another app shares the
/// Island, iOS gives him only a tiny "minimal" slot, and that shows the
/// timer alone.
///
/// The golem's mood is in the colour, and his line is in the expanded view
/// (shown when a stage pops the Island open, or on a long-press):
/// - waking: white, a calm timer and a bar filling up to the limit
/// - stirring: orange, near the limit
/// - angry: red, past the limit, the timer counting on
/// `LiveTimer` books the stages and their lines.
///
/// The Lock Screen gets the same line. It rarely shows, because you're
/// not scrolling while the phone is locked. Tapping it opens Golem.
struct GolemLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GolemActivityAttributes.self) { context in
            LockScreenTimer(state: context.state, mood: Mood(context))
                .padding()
        } dynamicIsland: { context in
            let mood = Mood(context)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        GolemEyes(color: mood.color)
                        Text(context.state.groupName)
                            .font(.headline)
                            .foregroundStyle(mood.color)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerText(state: context.state, mood: mood, width: 64)
                        .font(.headline.monospacedDigit())
                }
                // The slots beside the camera are narrow, so his line (and,
                // while he's calm, the bar) go in the space below.
                DynamicIslandExpandedRegion(.bottom) {
                    Text(mood.line(context.state))
                        .font(.system(.title3, design: .serif).weight(.semibold))
                        .foregroundStyle(mood.color)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            } compactLeading: {
                // Inset so both eyes clear the Island's rounded end.
                GolemEyes(color: mood.color)
                    .padding(.leading, 6)
            } compactTrailing: {
                TimerText(state: context.state, mood: mood)
                    .font(.system(size: 15, weight: .semibold).monospacedDigit())
            } minimal: {
                // When another app also has a Live Activity (music, a
                // call), iOS shrinks the golem to this tiny slot. The
                // timer matters more than his face there; the colour
                // still tells his mood.
                MinimalTimer(state: context.state, mood: mood)
            }
            .keylineTint(mood == .waking ? nil : mood.color)
        }
    }
}

/// How the golem is right now, and how that looks.
private enum Mood {
    case waking, stirring, angry

    init(_ context: ActivityViewContext<GolemActivityAttributes>) {
        switch context.state.moment {
        // Where the stages can't be booked (older iOS), iOS marks the calm
        // timer stale at the limit: he's angry from then on.
        case .waking: self = context.isStale ? .angry : .waking
        case .stirring: self = .stirring
        case .angry: self = .angry
        }
    }

    var color: Color {
        switch self {
        case .waking: .white
        case .stirring: .orange
        case .angry: .red
        }
    }

    /// His line; a calm timer gone stale has no angry line of its own.
    func line(_ state: GolemActivityAttributes.ContentState) -> String {
        self == .angry && state.moment == .waking
            ? GolemVoice.fallbackLines(.angry)[0]
            : state.line
    }
}

/// The golem's eyes. Uses the "GolemEye" image from this extension's asset
/// catalog when it's there, otherwise the SF Symbol `eye.fill`.
private struct GolemEyes: View {
    let color: Color

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

/// mm:ss counting up. Before the limit it stops at the limit; once he's
/// angry it keeps counting past it.
///
/// Timer texts are greedy and would stretch the Island, so the width is
/// fixed to fit "00:00" and the digits hug the right edge.
private struct TimerText: View {
    let state: GolemActivityAttributes.ContentState
    let mood: Mood
    var width: CGFloat = 46
    /// The calm colour, for the Lock Screen's light background.
    var calmColor: Color?

    var body: some View {
        timer
            .foregroundStyle(mood == .waking ? (calmColor ?? mood.color) : mood.color)
            .multilineTextAlignment(.trailing)
            .frame(width: width, alignment: .trailing)
    }

    @ViewBuilder
    private var timer: some View {
        if mood == .angry {
            Text(state.startedAt, style: .timer)
        } else {
            Text(timerInterval: state.startedAt...state.limitAt, countsDown: false)
        }
    }
}

/// The timer in the tiny round slot iOS gives him when another app shares
/// the Island. It fills the slot and shrinks to fit, so even "12:34" is
/// never cut off, and stays centred. (A short "11s" / "3m" isn't possible:
/// only iOS can tick a timer while you scroll, and it ticks as m:ss.)
private struct MinimalTimer: View {
    let state: GolemActivityAttributes.ContentState
    let mood: Mood

    var body: some View {
        Group {
            if mood == .angry {
                Text(state.startedAt, style: .timer)
            } else {
                Text(timerInterval: state.startedAt...state.limitAt, countsDown: false)
            }
        }
        .font(.system(size: 13, weight: .semibold).monospacedDigit())
        .foregroundStyle(mood.color)
        .multilineTextAlignment(.center)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .frame(maxWidth: .infinity)
    }
}

/// One line on the Lock Screen, only while you're in a group's apps.
private struct LockScreenTimer: View {
    let state: GolemActivityAttributes.ContentState
    let mood: Mood

    var body: some View {
        HStack {
            GolemEyes(color: mood == .waking ? .primary : mood.color)
            Text(state.groupName)
                .font(.headline)
            Spacer()
            TimerText(state: state, mood: mood, width: 80, calmColor: .primary)
                .font(.title2.monospacedDigit())
        }
    }
}
