import Foundation

/// Applies "app opened / closed" events to the stored group timers.
///
/// Only one group runs at a time: opening an app of another group
/// pauses whatever was running, even if its "closed" event never came.
public struct SessionTracker: Sendable {
    private let store: SharedStore

    public init(store: SharedStore = SharedStore()) {
        self.store = store
    }

    /// Returns the group's session after the event.
    @discardableResult
    public func appOpened(groupID: UUID, at now: Date) -> GroupSession {
        var sessions = store.sessions
        var log = store.dayLog
        for id in sessions.keys where id != groupID {
            let start = sessions[id]?.runningSince
            if sessions[id]?.appClosed(at: now) == true, let start {
                log.visitEnded(groupID: id, lasting: now.timeIntervalSince(start), at: now)
            }
        }

        var session = sessions[groupID] ?? GroupSession()
        if !session.isRunning {
            log.visitStarted(groupID: groupID, at: now)
        }
        session.appOpened(at: now)
        sessions[groupID] = session

        store.sessions = sessions
        store.dayLog = log
        return session
    }

    /// Returns false when the event was ignored (e.g. part of switching apps).
    @discardableResult
    public func appClosed(groupID: UUID, at now: Date) -> Bool {
        guard var session = store.sessions[groupID] else { return false }
        let start = session.runningSince
        let didStop = session.appClosed(at: now)
        store.sessions[groupID] = session
        if didStop, let start {
            store.dayLog.visitEnded(groupID: groupID, lasting: now.timeIntervalSince(start), at: now)
        }
        return didStop
    }

    /// Stops every running group (see `GroupSession.stop`).
    /// Returns false when nothing was running.
    @discardableResult
    public func stopAll(at now: Date) -> Bool {
        var sessions = store.sessions
        var log = store.dayLog
        var didStop = false
        for id in sessions.keys {
            let start = sessions[id]?.runningSince
            if sessions[id]?.stop(at: now) == true, let start {
                log.visitEnded(groupID: id, lasting: now.timeIntervalSince(start), at: now)
                didStop = true
            }
        }
        store.sessions = sessions
        store.dayLog = log
        return didStop
    }

    /// The group whose apps are open right now, if any.
    public func runningGroup() -> WatchGroup? {
        let sessions = store.sessions
        return store.settings.groups.first { sessions[$0.id]?.isRunning == true }
    }

    /// The group's session as it should be seen now (rested since you left).
    public func session(for groupID: UUID, at now: Date) -> GroupSession {
        (store.sessions[groupID] ?? GroupSession())
            .rested(at: now)
    }

    /// Whether the group's golem is resting (time flowing back) right now.
    public func isResting(_ groupID: UUID, at now: Date) -> Bool {
        session(for: groupID, at: now).isResting
    }

    /// Groups that have used up their time, the one you were in most
    /// recently first.
    public func groupsOverLimit(at now: Date) -> [WatchGroup] {
        let overLimit = store.settings.groups.filter { group in
            session(for: group.id, at: now).isOverLimit(limitMinutes: group.limitMinutes, at: now)
        }
        let sessions = store.sessions
        return overLimit.sorted {
            (sessions[$0.id]?.lastOpenedAt ?? .distantPast) > (sessions[$1.id]?.lastOpenedAt ?? .distantPast)
        }
    }
}
