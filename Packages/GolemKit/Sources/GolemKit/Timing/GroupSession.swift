import Foundation

/// The timer of one group: how long you've been in its apps "in a row".
///
/// It is driven by two events, sent by Shortcuts automations:
/// an app of the group was opened, or closed. Time between visits isn't
/// counted. While you're away the golem rests: the used time flows back,
/// shrinking evenly until it's gone after a full break.
public struct GroupSession: Codable, Equatable, Sendable {
    /// Time from earlier visits that already ended.
    public private(set) var countedSeconds: TimeInterval = 0

    /// When the current visit started; nil while you're away.
    public private(set) var runningSince: Date?

    public private(set) var lastOpenedAt: Date?
    public private(set) var lastClosedAt: Date?

    /// Extra time won by pleading.
    public private(set) var bonusSeconds: TimeInterval = 0

    /// Switching between two apps of a group fires "closed" and "opened"
    /// within a moment, in either order. A "closed" this soon after a
    /// second "opened" belongs to the app you left, so it's ignored.
    static let switchGrace: TimeInterval = 3

    public init() {}

    public var isRunning: Bool { runningSince != nil }

    /// Total time in the group's apps for this session.
    public func elapsed(at now: Date) -> TimeInterval {
        countedSeconds + (runningSince.map { now.timeIntervalSince($0) } ?? 0)
    }

    /// How much time you're allowed: the group's limit plus any pleaded bonus.
    public func allowance(limitMinutes: Int) -> TimeInterval {
        TimeInterval(limitMinutes * 60) + bonusSeconds
    }

    public func isOverLimit(limitMinutes: Int, at now: Date) -> Bool {
        elapsed(at: now) >= allowance(limitMinutes: limitMinutes)
    }

    /// The moment the timer would show 0:00 if counting from now on.
    public func startDate(at now: Date) -> Date {
        now.addingTimeInterval(-elapsed(at: now))
    }

    /// The moment the allowance runs out, if you keep scrolling from now on.
    public func limitDate(limitMinutes: Int, at now: Date) -> Date {
        startDate(at: now).addingTimeInterval(allowance(limitMinutes: limitMinutes))
    }

    /// The session as it should be seen now, after resting since you left.
    ///
    /// Used time flows back evenly over the break: halfway through a
    /// 10-minute break, half of it is gone; after the whole break the
    /// session is fresh (pleaded bonus time included).
    ///
    /// The returned session counts its rest from `now`, so it can be stored
    /// as is (e.g. after a plea); the rest then simply carries on from there.
    public func rested(breakMinutes: Int, at now: Date) -> GroupSession {
        guard !isRunning, let closed = lastClosedAt else { return self }

        let breakSeconds = TimeInterval(breakMinutes * 60)
        let away = max(0, now.timeIntervalSince(closed))
        guard breakSeconds > 0, away < breakSeconds else { return GroupSession() }

        var rested = self
        rested.countedSeconds = countedSeconds * (1 - away / breakSeconds)
        rested.lastClosedAt = now
        return rested
    }

    /// How long until the golem is fully rested (the session is fresh),
    /// or nil while you're in the apps or there's nothing to rest from.
    public func restLeft(breakMinutes: Int, at now: Date) -> TimeInterval? {
        guard !isRunning, countedSeconds > 0, let closed = lastClosedAt else { return nil }
        let left = TimeInterval(breakMinutes * 60) - now.timeIntervalSince(closed)
        return left > 0 ? left : nil
    }

    // MARK: Events

    public mutating func appOpened(at now: Date, breakMinutes: Int) {
        if !isRunning {
            self = rested(breakMinutes: breakMinutes, at: now)
            runningSince = now
        }
        lastOpenedAt = now
    }

    /// Returns false when the event was ignored (not running, or part of a switch).
    @discardableResult
    public mutating func appClosed(at now: Date) -> Bool {
        guard let start = runningSince else { return false }

        if let opened = lastOpenedAt, opened > start, now.timeIntervalSince(opened) < Self.switchGrace {
            return false
        }
        return stop(at: now)
    }

    /// Stops the timer no matter what, e.g. when Golem itself comes to the
    /// front (no watched app can be open then).
    /// Returns false when it wasn't running.
    @discardableResult
    public mutating func stop(at now: Date) -> Bool {
        guard let start = runningSince else { return false }
        countedSeconds += max(0, now.timeIntervalSince(start))
        runningSince = nil
        lastClosedAt = now
        return true
    }

    /// A successful plea: from now on you get `minutes` more,
    /// no matter how far over the limit you were.
    public mutating func grant(minutes: Int, limitMinutes: Int, at now: Date) {
        let needed = elapsed(at: now) - TimeInterval(limitMinutes * 60) + TimeInterval(minutes * 60)
        bonusSeconds = max(bonusSeconds, needed)
    }
}
