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
/// Reopening an app past the limit pops the Island open again.
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
            await showAngry(attributes, state: state)
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
        // the scheduled pop-up takes the Island's main spot then, and this
        // one stays beside it as a small bubble with red eyes.
        let content = ActivityContent(state: state, staleDate: state.limitAt)
        let all = Activity<GolemActivityAttributes>.activities
        let mine = all.filter { $0.attributes.groupID == attributes.groupID }

        // Still in this group (switching between its apps): update in place
        // instead of flickering it away and back.
        let watching = mine.first { !$0.content.state.isOverLimit && $0.activityState == .active }
        let popUp = mine.first { isPending($0) && $0.content.state.limitAt == state.limitAt }
        for other in all where other.id != watching?.id && other.id != popUp?.id {
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

        if popUp == nil {
            schedulePopUp(attributes, state: state)
        }
    }

    private static func schedulePopUp(_ attributes: GolemActivityAttributes, state: GolemActivityAttributes.ContentState) {
        guard #available(iOS 26.0, *), canShow else { return }
        var angry = state
        angry.isOverLimit = true
        do {
            _ = try Activity.request(
                attributes: attributes,
                content: angryContent(angry),
                style: .standard,
                alertConfiguration: alert(groupName: attributes.groupName),
                start: state.limitAt
            )
            logger.info("Pop-up booked for \(attributes.groupName) at \(state.limitAt)")
        } catch {
            logger.error("Couldn't book the pop-up: \(error.localizedDescription)")
        }
    }

    // MARK: Past the limit

    /// Back in the group's apps although the time is up: pop the Island
    /// open so it can't be missed, every time.
    private static func showAngry(_ attributes: GolemActivityAttributes, state: GolemActivityAttributes.ContentState) async {
        let content = angryContent(state)
        let all = Activity<GolemActivityAttributes>.activities
        let angry = all.first {
            $0.attributes.groupID == attributes.groupID
                && $0.content.state.isOverLimit
                && $0.activityState == .active
        }
        // Golem's code runs now, so the calm one (the extra bubble) can go.
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
    }

    // MARK: Helpers

    /// The angry one wins the Island's main spot over the calm one.
    private static func angryContent(_ state: GolemActivityAttributes.ContentState) -> ActivityContent<GolemActivityAttributes.ContentState> {
        ActivityContent(state: state, staleDate: nil, relevanceScore: 100)
    }

    /// On iPhones with a Dynamic Island the alert shows the expanded view;
    /// this text is for the Apple Watch and iPhones without one.
    private static func alert(groupName: String) -> AlertConfiguration {
        AlertConfiguration(
            title: LocalizedStringResource(stringLiteral: GolemVoice.islandQuestion),
            body: LocalizedStringResource(stringLiteral: GolemVoice.islandAlertBody(groupName: groupName)),
            sound: .default
        )
    }

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
