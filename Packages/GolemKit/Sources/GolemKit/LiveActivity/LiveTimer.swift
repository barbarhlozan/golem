#if os(iOS)
@preconcurrency import ActivityKit
import Foundation
import OSLog

/// Shows and hides the Golem's timer in the Dynamic Island.
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

    public static func show(group: WatchGroup, session: GroupSession, at now: Date) async {
        let state = GolemActivityAttributes.ContentState(
            startedAt: session.startDate(at: now),
            limitAt: session.limitDate(limitMinutes: group.limitMinutes, at: now),
            isOverLimit: session.isOverLimit(limitMinutes: group.limitMinutes, at: now)
        )
        let attributes = GolemActivityAttributes(groupID: group.id, groupName: group.name)

        if state.isOverLimit {
            await showAngry(attributes, state: state, at: now)
        } else {
            await showWatching(attributes, state: state)
        }
    }

    public static func hide() async {
        // Includes a scheduled pop-up that hasn't started yet.
        for activity in Activity<GolemActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
            logger.info("Timer hidden for \(activity.attributes.groupName)")
        }
    }

    // MARK: Within the limit

    private static func showWatching(_ attributes: GolemActivityAttributes, state: GolemActivityAttributes.ContentState) async {
        // At the limit iOS marks it stale and redraws it red. On iOS 26+
        // the booked pop-ups take over the Island from then on.
        let content = ActivityContent(state: state, staleDate: state.limitAt)
        let all = Activity<GolemActivityAttributes>.activities
        let mine = all.filter { $0.attributes.groupID == attributes.groupID }

        // Still in this group (switching between its apps): update in place
        // instead of flickering it away and back.
        let watching = mine.first { !$0.content.state.isOverLimit && $0.activityState == .active }
        // Already booked for this limit (e.g. switching between the group's apps).
        let popUps = mine.filter { isPending($0) && $0.content.state.limitAt == state.limitAt }
        let keep = Set(popUps.map(\.id) + [watching?.id].compactMap { $0 })
        for other in all where !keep.contains(other.id) {
            await other.end(nil, dismissalPolicy: .immediate)
        }

        if let watching {
            await watching.update(content)
        } else {
            guard canShow else { return }
            do {
                _ = try Activity.request(attributes: attributes, content: content)
                logger.info("Watching \(attributes.groupName)")
            } catch {
                logger.error("Couldn't start the live timer: \(error.localizedDescription)")
            }
        }

        if popUps.isEmpty {
            schedulePopUps(attributes, state: state, from: state.limitAt)
        }
    }

    /// How often the golem demands an answer once you're past the limit.
    static let popUpInterval: TimeInterval = 10

    /// iOS allows an app 5 Live Activities at a time (booked ones count),
    /// so one timer plus 4 pop-ups. That's 40 s of demands; reopening an
    /// app past the limit books 4 more.
    static let maxActivities = 5

    private static func schedulePopUps(_ attributes: GolemActivityAttributes, state: GolemActivityAttributes.ContentState, from first: Date) {
        guard #available(iOS 26.0, *), canShow else { return }
        var angry = state
        angry.isOverLimit = true
        for index in 0..<(maxActivities - 1) {
            let start = first.addingTimeInterval(Double(index) * popUpInterval)
            do {
                _ = try Activity.request(
                    attributes: attributes,
                    // The newest one takes the Island.
                    content: angryContent(angry, relevance: start.timeIntervalSinceReferenceDate),
                    style: .standard,
                    alertConfiguration: alert(groupName: attributes.groupName),
                    start: start
                )
            } catch {
                logger.error("Couldn't book pop-up \(index): \(error.localizedDescription)")
                return
            }
        }
        logger.info("Pop-ups booked for \(attributes.groupName) from \(first)")
    }

    // MARK: Past the limit

    /// Back in the group's apps although the time is up: pop the Island
    /// open so it can't be missed, every time, and book the next demands.
    private static func showAngry(_ attributes: GolemActivityAttributes, state: GolemActivityAttributes.ContentState, at now: Date) async {
        let content = angryContent(state, relevance: now.timeIntervalSinceReferenceDate)
        let all = Activity<GolemActivityAttributes>.activities
        let angry = all.first {
            $0.attributes.groupID == attributes.groupID
                && $0.content.state.isOverLimit
                && $0.activityState == .active
        }
        // Golem's code runs now, so it can clear out the rest (the calm
        // timer, used-up pop-ups, ones still booked) to make room.
        for other in all where other.id != angry?.id {
            await other.end(nil, dismissalPolicy: .immediate)
        }

        let activity: Activity<GolemActivityAttributes>
        if let angry {
            activity = angry
        } else {
            guard canShow else { return }
            do {
                activity = try Activity.request(attributes: attributes, content: content)
            } catch {
                logger.error("Couldn't start the live timer: \(error.localizedDescription)")
                return
            }
        }
        await activity.update(content, alertConfiguration: alert(groupName: attributes.groupName))
        logger.info("Angry for \(attributes.groupName)")
        schedulePopUps(attributes, state: state, from: now.addingTimeInterval(popUpInterval))
    }

    // MARK: Helpers

    /// The angry one wins the Island's main spot over the calm one.
    private static func angryContent(_ state: GolemActivityAttributes.ContentState, relevance: Double) -> ActivityContent<GolemActivityAttributes.ContentState> {
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
