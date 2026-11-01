import Foundation
import OSLog

/// What happens when an app of a group is opened or closed:
/// update the group's timer, the Dynamic Island, and the "time's up" notification.
///
/// Called by the Shortcuts actions, the timer's Stop button, the app when it
/// comes to the front, and the debug buttons. It lives in GolemKit so the
/// widget extension can compile the Stop button's intent too.
///
/// Events are handled strictly one after another. Shortcuts can deliver
/// "opened" and "closed" a moment apart, and when they overlapped, a late
/// "show" put the Island (and a "time's up" notification) back after the
/// "closed" had already stopped the timer.
@MainActor
public enum SessionCoordinator {
    public static func appOpened(groupID: UUID, at now: Date = .now) async {
        await serially {
            let store = SharedStore()
            guard let group = store.settings.group(id: groupID) else {
                logger.error("App opened for an unknown group \(groupID)")
                return
            }

            let session = SessionTracker(store: store).appOpened(groupID: groupID, at: now)
            logger.info("Opened \(group.name), \(Int(session.elapsed(at: now)))s used")

            // Fires immediately if the time is already up.
            GolemNotifications.scheduleTimeUp(
                groupID: group.id,
                groupName: group.name,
                minutes: group.limitMinutes,
                at: session.limitDate(limitMinutes: group.limitMinutes, at: now)
            )
            #if os(iOS)
            await LiveTimer.show(group: group, session: session, at: now)
            #endif
        }
    }

    public static func appClosed(groupID: UUID, at now: Date = .now) async {
        await serially {
            // Ignored when it's just a switch between two apps of the group.
            guard SessionTracker().appClosed(groupID: groupID, at: now) else {
                logger.info("Close ignored (switching apps or not running)")
                return
            }
            logger.info("Closed group \(groupID)")
            await clearTimer()
        }
    }

    /// Stops whatever is running. Used when Golem itself is in front
    /// (so no watched app can be) and by the timer's Stop button, because
    /// locking the phone inside an app never sends "closed".
    public static func stopAll(reason: String, at now: Date = .now) async {
        await serially {
            let didStop = SessionTracker().stopAll(at: now)
            logger.info("Stop all (\(reason)): \(didStop ? "stopped" : "nothing was running")")
            await clearTimer()
        }
    }

    private static func clearTimer() async {
        GolemNotifications.cancelTimeUp()
        #if os(iOS)
        await LiveTimer.hide()
        #endif
    }

    // MARK: One event at a time

    private static var last: Task<Void, Never>?

    private static func serially(_ work: @escaping @MainActor () async -> Void) async {
        let previous = last
        let task = Task { @MainActor in
            await previous?.value
            await work()
        }
        last = task
        await task.value
    }

    private static let logger = Logger(subsystem: "cz.hlozanek.golem", category: "Sessions")
}
