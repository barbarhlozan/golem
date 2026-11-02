import GolemKit
import SwiftUI

/// The top of the home screen: the golem big, a line on how he feels, and
/// a smaller one saying why, so the screen answers "am I OK?" at a glance.
///
/// His phase comes from the group that worries him most (see `focus`), and
/// its colour is the Island's: what you'd walk back into if you opened that
/// group's apps now. As the time flows back it steps down, red, orange,
/// white, and he falls asleep. Until he has seen an app open, he points to
/// the automations instead.
struct GolemMood: View {
    @Environment(GolemModel.self) private var model
    @Binding var isShowingSetupGuide: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text(GolemVoice.homeTitle)
                .font(.custom(Theme.headingFontName, size: 48, relativeTo: .largeTitle))
                .fontDesign(nil)

            LivingGolem(phase: phase, isWarm: moment != .waking, wokenAt: model.wokenFromAppAt)
                .padding(.vertical, 8)

            Text(line)
                .font(.custom(Theme.headingFontName, size: 34, relativeTo: .title))
                .fontDesign(nil)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            // Always takes one line's room (even when there's nothing to say)
            // and digits keep their width, so the rows below stay put as the
            // time ticks and the mood changes.
            Text(detail ?? " ")
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if !model.hasSeenAnApp {
                Button(GolemVoice.homeSetUpButton) { isShowingSetupGuide = true }
                    .buttonStyle(.golemPrimary)
                    .padding(.top, 8)
            }
        }
        .multilineTextAlignment(.center)
        .animation(.easeInOut(duration: 1), value: moment)
    }

    // MARK: State

    private struct Focus {
        let group: WatchGroup
        let usedSeconds: TimeInterval
        let moment: GolemMoment
    }

    /// The group that worries him most: the hottest colour first (still
    /// over its limit, then near it), then the one needing the longest rest.
    private var focus: Focus? {
        model.settings.groups
            .map { group in
                let used = model.usedSeconds(of: group)
                let moment = model.isOverLimit(group)
                    ? .angry
                    : GolemMoment(usedSeconds: used, limitSeconds: TimeInterval(group.limitMinutes * 60))
                return Focus(group: group, usedSeconds: used, moment: moment)
            }
            .filter { $0.usedSeconds >= 1 }
            .max { ($0.moment.heat, $0.usedSeconds) < ($1.moment.heat, $1.usedSeconds) }
    }

    private var phase: LivingGolem.Phase {
        if model.isGolemAwake { return .keepingWatch }
        guard let focus else { return .asleep }
        return focus.moment == .angry ? .restless : .settling
    }

    /// The Island's colour for the focus group; white while all is calm.
    private var moment: GolemMoment {
        model.isGolemAwake ? .angry : focus?.moment ?? .waking
    }

    private var color: Color { Theme.color(for: moment) }


    private var line: String {
        switch phase {
        case .keepingWatch: GolemVoice.homeKeepingWatch
        case .restless: GolemVoice.homeRumbling
        case .settling: GolemVoice.homeSettling
        case .asleep: GolemVoice.homeAsleep
        }
    }

    /// Only a time, or nothing: asleep, he needs no explanation.
    private var detail: String? {
        switch phase {
        case .keepingWatch:
            return GolemVoice.homeKeepingWatchDetail
        case .asleep:
            return model.hasSeenAnApp ? nil : GolemVoice.homeUnseenDetail
        case .restless, .settling:
            guard let focus else { return nil }
            if focus.moment == .angry {
                let overBy = focus.usedSeconds - TimeInterval(focus.group.limitMinutes * 60)
                return GolemVoice.homeRumblingDetail(time: overBy.minutesSeconds)
            }
            return GolemVoice.homeSettlingDetail(time: focus.usedSeconds.minutesSeconds)
        }
    }
}

private extension GolemMoment {
    /// For picking the hottest group: white < orange < red.
    var heat: Int {
        switch self {
        case .waking: 0
        case .stirring: 1
        case .angry: 2
        }
    }
}

extension TimeInterval {
    /// "4:12", for the home screen's times.
    var minutesSeconds: String {
        Duration.seconds(rounded()).formatted(.time(pattern: .minuteSecond))
    }
}
