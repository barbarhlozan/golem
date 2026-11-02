#if os(iOS)
@preconcurrency import ActivityKit
import Foundation
import OSLog

/// Shows and hides the Golem's timer in the Dynamic Island.
///
/// One timer stays alive between visits. When you leave the apps it turns
/// empty ("away") instead of ending, and when you come back it's updated.
/// That's because iOS shows a timer *started* from the background in its
/// large form for a moment, dropping down over the screen; an update
/// without an alert just widens the Island to the sides. Only the very
/// first visit (or one after iOS ended the timer, at most 8 hours later)
/// starts a new one.
///
/// Within the limit the golem is only watching: a calm timer, no fuss.
/// At the limit he wakes up properly and the Island pops open with his
/// question. Golem's code doesn't run while you scroll, so that pop-up is
/// booked in advance: on iOS 26+ an "angry" Live Activity is scheduled to
/// start by itself at the limit, with an alert. It's cancelled if you leave
/// before then. On older iOS the timer just turns red at the limit (its
/// stale date) and a "time's up" notification fires instead.
///
/// Past the limit he keeps demanding an answer every few seconds: more
/// pop-ups are booked the same way. Reopening an app past the limit pops
/// the Island open again and books the next ones.
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

    public static func show(group: WatchGroup, session: GroupSession, at now: Date) async {
        let state = State(
            groupID: group.id,
            groupName: group.name,
            startedAt: session.startDate(at: now),
            limitAt: session.limitDate(limitMinutes: group.limitMinutes, at: now),
            isOverLimit: session.isOverLimit(limitMinutes: group.limitMinutes, at: now)
        )

        if state.isOverLimit {
            await showAngry(state, at: now)
        } else {
            await showWatching(state)
        }
    }

    /// You've left the apps: cancel the booked pop-ups and empty the timer.
    public static func hide() async {
        guard let timer = await keepOne(alsoKeeping: []), !timer.content.state.isAway else { return }
        var away = timer.content.state
        away.isAway = true
        away.isOverLimit = false
        await timer.update(ActivityContent(state: away, staleDate: nil))
        logger.info("Timer away")
    }

    // MARK: Within the limit

    private static func showWatching(_ state: State) async {
        // Already booked for this limit (e.g. switching between the group's apps).
        let popUps = Activity<GolemActivityAttributes>.activities.filter {
            isPending($0) && $0.content.state.groupID == state.groupID && $0.content.state.limitAt == state.limitAt
        }
        // At the limit iOS marks it stale and redraws it red. On iOS 26+
        // the booked pop-ups take over the Island from then on.
        let content = ActivityContent(state: state, staleDate: state.limitAt)

        if let timer = await keepOne(alsoKeeping: popUps) {
            await timer.update(content)
        } else {
            start(content)
        }
        logger.info("Watching \(state.groupName)")

        if popUps.isEmpty {
            schedulePopUps(state, from: state.limitAt)
        }
    }

    /// How often the golem demands an answer once you're past the limit.
    static let popUpInterval: TimeInterval = 10

    /// iOS allows an app 5 Live Activities at a time (booked ones count),
    /// so one timer plus 4 pop-ups. That's 40 s of demands; reopening an
    /// app past the limit books 4 more.
    static let maxActivities = 5

    private static func schedulePopUps(_ state: State, from first: Date) {
        guard #available(iOS 26.0, *), canShow else { return }
        var angry = state
        angry.isOverLimit = true
        for index in 0..<(maxActivities - 1) {
            let start = first.addingTimeInterval(Double(index) * popUpInterval)
            do {
                _ = try Activity.request(
                    attributes: GolemActivityAttributes(),
                    // The newest one takes the Island.
                    content: angryContent(angry, relevance: start.timeIntervalSinceReferenceDate),
                    style: .standard,
                    alertConfiguration: alert(groupName: state.groupName),
                    start: start
                )
            } catch {
                logger.error("Couldn't book pop-up \(index): \(error.localizedDescription)")
                return
            }
        }
        logger.info("Pop-ups booked for \(state.groupName) from \(first)")
    }

    // MARK: Past the limit

    /// Back in the group's apps although the time is up: pop the Island
    /// open so it can't be missed, every time, and book the next demands.
    private static func showAngry(_ state: State, at now: Date) async {
        let content = angryContent(state, relevance: now.timeIntervalSinceReferenceDate)
        let alert = alert(groupName: state.groupName)

        if let timer = await keepOne(alsoKeeping: []) {
            await timer.update(content, alertConfiguration: alert)
        } else if let timer = start(content) {
            await timer.update(content, alertConfiguration: alert)
        }
        logger.info("Angry for \(state.groupName)")
        schedulePopUps(state, from: now.addingTimeInterval(popUpInterval))
    }

    // MARK: Helpers

    /// Keeps one running timer (the calm one if there is one) and the given
    /// booked pop-ups, and ends everything else to make room. Golem's code
    /// runs now, so it can tidy up used-up and booked pop-ups.
    private static func keepOne(alsoKeeping kept: [Activity<GolemActivityAttributes>]) async -> Activity<GolemActivityAttributes>? {
        let all = Activity<GolemActivityAttributes>.activities
        let running = all.filter { $0.activityState == .active || $0.activityState == .stale }
        let timer = running.min { ($0.content.relevanceScore) < ($1.content.relevanceScore) }
        let keep = Set(kept.map(\.id) + [timer?.id].compactMap { $0 })
        for other in all where !keep.contains(other.id) {
            await other.end(nil, dismissalPolicy: .immediate)
        }
        return timer
    }

    /// The first visit, or iOS ended the old timer: start a new one. This
    /// is the moment iOS shows it large when you're in another app.
    @discardableResult
    private static func start(_ content: ActivityContent<State>) -> Activity<GolemActivityAttributes>? {
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

    /// The angry one wins the Island's main spot over the calm one.
    private static func angryContent(_ state: State, relevance: Double) -> ActivityContent<State> {
        ActivityContent(state: state, staleDate: nil, relevanceScore: relevance)
    }

    /// On iPhones with a Dynamic Island the alert shows the expanded view;
    /// this text is for the Apple Watch and iPhones without one.
    private static func alert(groupName: String) -> AlertConfiguration {
        AlertConfiguration(
            title: LocalizedStringResource(stringLiteral: GolemVoice.islandQuestion),
            body: LocalizedStringResource(stringLiteral: GolemVoice.islandAlertBody(groupName: groupName)),
            sound: .named(knockSound)
        )
    }

    /// A soft knock instead of the default alert sound, which (with its
    /// buzz) was too much every 10 s. In the app's bundle.
    private static let knockSound = "golem-knock.caf"

    private static func isPending(_ activity: Activity<GolemActivityAttributes>) -> Bool {
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
