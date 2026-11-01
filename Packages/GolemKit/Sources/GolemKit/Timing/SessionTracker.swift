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
        for id in sessions.keys where id != groupID {
            sessions[id]?.appClosed(at: now)
        }

        var session = sessions[groupID] ?? GroupSession()
        session.appOpened(at: now, breakMinutes: store.settings.breakMinutes)
        sessions[groupID] = session

        store.sessions = sessions
        return session
    }

    /// Returns false when the event was ignored (e.g. part of switching apps).
    @discardableResult
    public func appClosed(groupID: UUID, at now: Date) -> Bool {
        guard var session = store.sessions[groupID] else { return false }
        let didStop = session.appClosed(at: now)
        store.sessions[groupID] = session
        return didStop
    }

    /// A successful plea for one group.
    public func grantMoreTime(groupID: UUID, at now: Date) {
        let settings = store.settings
        guard let group = settings.group(id: groupID) else { return }

        var session = session(for: groupID, at: now)
        session.grant(minutes: settings.pleaRules.grantedMinutes, limitMinutes: group.limitMinutes, at: now)
        store.sessions[groupID] = session
    }

    /// The group's session as it should be seen now (reset after a break).
    public func session(for groupID: UUID, at now: Date) -> GroupSession {
        (store.sessions[groupID] ?? GroupSession())
            .afterBreak(of: store.settings.breakMinutes, at: now)
    }

    /// Groups that have used up their time and need a plea.
    public func groupsOverLimit(at now: Date) -> [WatchGroup] {
        store.settings.groups.filter { group in
            session(for: group.id, at: now).isOverLimit(limitMinutes: group.limitMinutes, at: now)
        }
    }
}
