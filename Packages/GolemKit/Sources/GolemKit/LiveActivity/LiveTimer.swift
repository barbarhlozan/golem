#if os(iOS)
@preconcurrency import ActivityKit
import Foundation
import OSLog

/// Shows and hides the Golem's timer in the Dynamic Island.
///
/// The timer exists only while you're in a group's apps: leaving ends it,
/// so nothing lingers on the Lock Screen or in the background. iOS shows a
/// timer *started* from the background large for a moment; that's where
/// the golem says he's waking up. Switching between a group's apps keeps
/// the same timer.
///
/// Then he speaks up in stages, each its own Live Activity that pops the
/// Island open with an alert and a new line (`GolemLines`):
///
///   1. waking   white   when you open the app (the timer itself)
///   2. stirring orange  at 80% of the limit
///   3. angry    red     at the limit, and again 1 and 2 minutes later
///
/// Golem's code doesn't run while you scroll, so stages 2 and 3 are booked
/// in advance to start by themselves (iOS 26+). iOS allows an app 5 Live
/// Activities at a time, booked ones included: the timer, one stirring and
/// three angry. Reopening an app past the limit pops the Island open again
/// and books the next round. On older iOS the timer just turns red at the
/// limit (its stale date) and a "time's up" notification fires instead.
///
/// Call it through `SessionCoordinator`, which makes sure events are
/// handled one after another (a "show" racing a "hide" left the Island up).
public enum LiveTimer {
    /// Whether iOS can pop the Island open at the limit by itself.
    /// When it can, the "time's up" notification isn't needed.
    public static var popsOpenAtLimit: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }

    public typealias State = GolemActivityAttributes.ContentState
    private typealias Timer = Activity<GolemActivityAttributes>

    /// When the golem starts stirring, as a share of the limit.
    static let stirringAt = GolemMoment.stirringShare

    /// How often he asks again once you're past the limit.
    static let angryInterval: TimeInterval = 60

    /// iOS allows an app 5 Live Activities at a time (booked ones count).
    static let maxActivities = 5

    public static func show(group: WatchGroup, session: GroupSession, at now: Date) async {
        let startedAt = session.startDate(at: now)
        let limitAt = session.limitDate(limitMinutes: group.limitMinutes, at: now)
        let isOverLimit = session.isOverLimit(limitMinutes: group.limitMinutes, at: now)

        func state(_ moment: GolemMoment) -> State {
            State(
                groupID: group.id, groupName: group.name,
                startedAt: startedAt, limitAt: limitAt,
                moment: moment, line: GolemLines.next(moment)
            )
        }

        if isOverLimit {
            await showAngry(state(.angry), at: now)
        } else {
            let stirringAt = startedAt.addingTimeInterval(limitAt.timeIntervalSince(startedAt) * Self.stirringAt)
            await showWatching(group: group, startedAt: startedAt, limitAt: limitAt, stirringAt: stirringAt, at: now, state: state)
        }
    }

    /// You've left the apps: end the timer and cancel the booked stages.
    public static func hide() async {
        for activity in Timer.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        logger.info("Timer ended")
    }

    // MARK: Within the limit

    private static func showWatching(
        group: WatchGroup,
        startedAt: Date,
        limitAt: Date,
        stirringAt: Date,
        at now: Date,
        state: (GolemMoment) -> State
    ) async {
        // Already booked for this limit (e.g. switching between the group's apps).
        let booked = Timer.activities.filter {
            isPending($0) && $0.content.state.groupID == group.id && $0.content.state.limitAt == limitAt
        }

        if let timer = await keepOne(alsoKeeping: booked) {
            // Keep his current line; only the times change.
            var updated = timer.content.state
            updated.startedAt = startedAt
            updated.limitAt = limitAt
            await timer.update(calm(updated))
        } else {
            start(calm(state(.waking)))
        }
        logger.info("Watching \(group.name)")

        guard booked.isEmpty else { return }
        var stages: [(GolemMoment, Date)] = []
        if stirringAt > now { stages.append((.stirring, stirringAt)) }
        let angryCount = maxActivities - 1 - stages.count
        for index in 0..<angryCount {
            stages.append((.angry, limitAt.addingTimeInterval(Double(index) * angryInterval)))
        }
        book(stages, state: state)
    }

    /// The calm timer. At the limit iOS marks it stale and redraws it red,
    /// for iPhones that can't book the stages (older iOS).
    private static func calm(_ state: State) -> ActivityContent<State> {
        ActivityContent(state: state, staleDate: state.limitAt, relevanceScore: 0)
    }

    // MARK: Past the limit

    /// Back in the group's apps although the time is up: pop the Island
    /// open so it can't be missed, every time, and book the next demands.
    private static func showAngry(_ angry: State, at now: Date) async {
        let content = popUp(angry, at: now)
        let alert = alert(for: angry)

        if let timer = await keepOne(alsoKeeping: []) {
            await timer.update(content, alertConfiguration: alert)
        } else if let timer = start(content) {
            await timer.update(content, alertConfiguration: alert)
        }
        logger.info("Angry for \(angry.groupName)")

        let next = (1..<maxActivities).map { (GolemMoment.angry, now.addingTimeInterval(Double($0) * angryInterval)) }
        book(next, state: { moment in
            var state = angry
            state.moment = moment
            state.line = GolemLines.next(moment)
            return state
        })
    }

    // MARK: Helpers

    /// Books Live Activities that start by themselves at the given times,
    /// each popping the Island open with its own line (iOS 26+).
    private static func book(_ stages: [(GolemMoment, Date)], state: (GolemMoment) -> State) {
        guard #available(iOS 26.0, *), canShow else { return }
        for (moment, date) in stages {
            let stage = state(moment)
            do {
                _ = try Activity.request(
                    attributes: GolemActivityAttributes(),
                    content: popUp(stage, at: date),
                    style: .standard,
                    alertConfiguration: alert(for: stage),
                    start: date
                )
            } catch {
                logger.error("Couldn't book \(moment.rawValue) at \(date): \(error.localizedDescription)")
                return
            }
        }
        logger.info("Booked \(stages.count) stages")
    }

    /// A stage's content. The newest one takes the Island's main spot.
    private static func popUp(_ state: State, at date: Date) -> ActivityContent<State> {
        ActivityContent(state: state, staleDate: nil, relevanceScore: date.timeIntervalSinceReferenceDate)
    }

    /// Keeps one running timer (the calm one if there is one) and the given
    /// booked stages, and ends everything else to make room. Golem's code
    /// runs now, so it can tidy up used-up and booked stages.
    private static func keepOne(alsoKeeping kept: [Timer]) async -> Timer? {
        let all = Timer.activities
        let running = all.filter { $0.activityState == .active || $0.activityState == .stale }
        let timer = running.min { $0.content.relevanceScore < $1.content.relevanceScore }
        let keep = Set(kept.map(\.id) + [timer?.id].compactMap { $0 })
        for other in all where !keep.contains(other.id) {
            await other.end(nil, dismissalPolicy: .immediate)
        }
        return timer
    }

    /// A new visit: start a new timer. This is the moment iOS shows it
    /// large for a moment when you're in another app.
    @discardableResult
    private static func start(_ content: ActivityContent<State>) -> Timer? {
        guard canShow else { return nil }
        do {
            let timer = try Activity.request(attributes: GolemActivityAttributes(), content: content)
            logger.info("Timer started")
            return timer
        } catch {
            logger.error("Couldn't start the live timer: \(error.localizedDescription)")
            return nil
        }
    }

    /// On iPhones with a Dynamic Island the alert shows the expanded view
    /// (with his line); this text is for the Apple Watch and iPhones
    /// without one.
    private static func alert(for state: State) -> AlertConfiguration {
        AlertConfiguration(
            title: LocalizedStringResource(stringLiteral: state.line),
            body: LocalizedStringResource(stringLiteral: GolemVoice.islandAlertBody(groupName: state.groupName)),
            sound: .named(knockSound)
        )
    }

    /// A soft knock instead of the default alert sound. In the app's bundle.
    private static let knockSound = "golem-knock.caf"

    private static func isPending(_ activity: Timer) -> Bool {
        if #available(iOS 26.0, *) { return activity.activityState == .pending }
        return false
    }

    private static var canShow: Bool {
        let enabled = ActivityAuthorizationInfo().areActivitiesEnabled
        if !enabled { logger.notice("Live Activities are turned off for Golem") }
        return enabled
    }

    private static let logger = Logger(subsystem: "cz.hlozanek.golem", category: "LiveTimer")
}
#endif
