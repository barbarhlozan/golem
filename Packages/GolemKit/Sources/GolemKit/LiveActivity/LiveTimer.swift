#if os(iOS)
@preconcurrency import ActivityKit
import Foundation
import OSLog

/// Shows and hides the Golem's timer in the Dynamic Island and on the Lock Screen.
///
/// There is at most one timer at a time: the group you're in right now.
public enum LiveTimer {
    public static func show(groupName: String, session: GroupSession, limitMinutes: Int, at now: Date) async {
        await hide()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.notice("Live Activities are turned off for Golem")
            return
        }

        let limitAt = session.limitDate(limitMinutes: limitMinutes, at: now)
        let isOverLimit = session.isOverLimit(limitMinutes: limitMinutes, at: now)
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

        do {
            let activity = try Activity.request(
                attributes: GolemActivityAttributes(groupName: groupName),
                content: content
            )
            // Back in the group's apps although the time is up: pop the
            // Island open so it can't be missed.
            if isOverLimit {
                await activity.update(content, alertConfiguration: AlertConfiguration(
                    title: LocalizedStringResource(stringLiteral: GolemVoice.angryAlertTitle),
                    body: LocalizedStringResource(stringLiteral: GolemVoice.angryAlertBody(groupName: groupName)),
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
        }
    }

    private static let logger = Logger(subsystem: "cz.hlozanek.golem", category: "LiveTimer")
}
#endif
