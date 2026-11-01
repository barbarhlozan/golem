#if os(iOS)
@preconcurrency import ActivityKit
import Foundation
import OSLog

/// Shows and hides the Golem's timer in the Dynamic Island and on the Lock Screen.
///
/// There is at most one timer at a time: the group you're in right now.
/// Call it through `SessionCoordinator`, which makes sure events are
/// handled one after another (a "show" racing a "hide" left the Island up).
public enum LiveTimer {
    public static func show(group: WatchGroup, session: GroupSession, at now: Date) async {
        let limitAt = session.limitDate(limitMinutes: group.limitMinutes, at: now)
        let isOverLimit = session.isOverLimit(limitMinutes: group.limitMinutes, at: now)
        let content = ActivityContent(
            state: GolemActivityAttributes.ContentState(
                startedAt: session.startDate(at: now),
                limitAt: limitAt,
                isOverLimit: isOverLimit
            ),
            // At the limit iOS marks the timer stale and redraws it, which is
            // how the golem turns angry (red) without any code running then.
            staleDate: isOverLimit ? nil : limitAt
        )

        // Still showing this group (e.g. switching apps inside it):
        // update in place instead of flickering it away and back.
        let current = Activity<GolemActivityAttributes>.activities
        if let existing = current.first(where: { $0.attributes.groupID == group.id }),
           existing.activityState == .active {
            await existing.update(content)
            for other in current where other.id != existing.id {
                await other.end(nil, dismissalPolicy: .immediate)
            }
            return
        }

        await hide()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.notice("Live Activities are turned off for Golem")
            return
        }

        do {
            let activity = try Activity.request(
                attributes: GolemActivityAttributes(groupID: group.id, groupName: group.name),
                content: content
            )
            logger.info("Timer shown for \(group.name)")
            // Back in the group's apps although the time is up: pop the
            // Island open so it can't be missed.
            if isOverLimit {
                await activity.update(content, alertConfiguration: AlertConfiguration(
                    title: LocalizedStringResource(stringLiteral: GolemVoice.angryAlertTitle),
                    body: LocalizedStringResource(stringLiteral: GolemVoice.angryAlertBody(groupName: group.name)),
                    sound: .default
                ))
            }
        } catch {
            logger.error("Couldn't start the live timer: \(error.localizedDescription)")
        }
    }

    public static func hide() async {
        for activity in Activity<GolemActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
            logger.info("Timer hidden for \(activity.attributes.groupName)")
        }
    }

    private static let logger = Logger(subsystem: "cz.hlozanek.golem", category: "LiveTimer")
}
#endif
