#if DEBUG
import Foundation
import GolemKit

/// Shortcuts to states that are slow to reach by hand, for the debug menu.
/// Debug builds only.
extension GolemModel {
    /// Pretend the group's apps were used one second past its limit.
    func debugPutOverLimit(_ group: WatchGroup) {
        let now = Date.now
        var session = GroupSession()
        session.appOpened(at: now.addingTimeInterval(-TimeInterval(group.limitMinutes * 60 + 1)), breakMinutes: settings.breakMinutes)
        session.stop(at: now)
        store.sessions[group.id] = session
        refresh()
    }

    func debugResetTimers() {
        store.sessions = [:]
        refresh()
    }

    /// iOS doesn't show Golem's notifications while Golem is open,
    /// so this one comes a few seconds later: leave the app to see it.
    func debugSendTimeUp(_ group: WatchGroup, in seconds: TimeInterval = 5) {
        GolemNotifications.scheduleTimeUp(
            groupID: group.id,
            groupName: group.name,
            minutes: group.limitMinutes,
            at: .now.addingTimeInterval(seconds)
        )
    }

    /// One line per group with the raw timer values.
    func debugSessionLines() -> [String] {
        let sessions = store.sessions
        return settings.groups.map { group in
            guard let session = sessions[group.id] else { return "\(group.name): no session" }
            let used = Int(session.elapsed(at: .now))
            let state = session.isRunning ? "running" : "paused"
            let opened = session.lastOpenedAt?.formatted(date: .omitted, time: .standard) ?? "never"
            let bonus = Int(session.bonusSeconds)
            return "\(group.name): \(used) s, \(state), bonus \(bonus) s, opened \(opened)"
        }
    }
}
#endif
