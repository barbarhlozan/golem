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

        let state = GolemActivityAttributes.ContentState(
            startedAt: session.startDate(at: now),
            limitAt: session.limitDate(limitMinutes: limitMinutes, at: now),
            isOverLimit: session.isOverLimit(limitMinutes: limitMinutes, at: now)
        )
        do {
            _ = try Activity.request(
                attributes: GolemActivityAttributes(groupName: groupName),
                content: ActivityContent(state: state, staleDate: nil)
            )
        } catch {
            logger.error("Couldn't start the live timer: \(error.localizedDescription)")
        }
    }

    private static let logger = Logger(subsystem: "cz.hlozanek.golem", category: "LiveTimer")

    public static func hide() async {
        for activity in Activity<GolemActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
#endif
