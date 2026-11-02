#if DEBUG
import Foundation
import GolemKit
import UIKit

/// Shortcuts to states that are slow to reach by hand, for the debug menu.
/// Debug builds only.
extension GolemModel {
    /// Pretend the group's apps were used a minute past its limit (resting
    /// gives a second back per second, so it stays over for a minute).
    func debugPutOverLimit(_ group: WatchGroup) {
        debugPut(group, secondsBeforeLimit: -60)
    }

    /// Pretend the group's apps were used until a few seconds before its
    /// limit. Then "Open" shows the Island popping open at the limit.
    func debugPutNearLimit(_ group: WatchGroup) {
        debugPut(group, secondsBeforeLimit: 20)
    }

    private func debugPut(_ group: WatchGroup, secondsBeforeLimit: TimeInterval) {
        let now = Date.now
        let used = TimeInterval(group.limitMinutes * 60) - secondsBeforeLimit
        var session = GroupSession()
        session.appOpened(at: now.addingTimeInterval(-used))
        session.stop(at: now)
        store.sessions[group.id] = session
        refresh()
    }

    /// "Open" a few seconds later, so you can be in another app by then,
    /// like when the automation runs. Only updates a timer that's already
    /// there: iOS lets an app start one from the background only through
    /// a Shortcuts action.
    func debugOpenLater(_ group: WatchGroup, in seconds: TimeInterval = 4) {
        let task = UIApplication.shared.beginBackgroundTask()
        Task {
            try? await Task.sleep(for: .seconds(seconds))
            await simulateAppOpened(in: group)
            UIApplication.shared.endBackgroundTask(task)
        }
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
