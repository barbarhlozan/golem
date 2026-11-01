import Foundation
import GolemKit
import OSLog

/// What happens when an app of a group is opened or closed:
/// update the group's timer, the Dynamic Island, and the "time's up" notification.
///
/// Called by the Shortcuts actions (and the debug buttons on the home screen).
enum SessionCoordinator {
    static func appOpened(groupID: UUID, at now: Date = .now) async {
        let store = SharedStore()
        guard let group = store.settings.group(id: groupID) else {
            logger.error("App opened for an unknown group \(groupID)")
            return
        }

        let session = SessionTracker(store: store).appOpened(groupID: groupID, at: now)
        logger.info("Opened \(group.name), \(Int(session.elapsed(at: now)))s used")
        await LiveTimer.show(groupName: group.name, session: session, limitMinutes: group.limitMinutes, at: now)

        // Fires immediately if the time is already up.
        GolemNotifications.scheduleTimeUp(
            groupName: group.name,
            minutes: group.limitMinutes,
            at: session.limitDate(limitMinutes: group.limitMinutes, at: now)
        )
    }

    static func appClosed(groupID: UUID, at now: Date = .now) async {
        // Ignored when it's just a switch between two apps of the group.
        guard SessionTracker().appClosed(groupID: groupID, at: now) else {
            logger.info("Close ignored (switching apps or not running)")
            return
        }
        logger.info("Closed group \(groupID)")

        GolemNotifications.cancelTimeUp()
        await LiveTimer.hide()
    }

    private static let logger = Logger(subsystem: "cz.hlozanek.golem", category: "Sessions")
}
