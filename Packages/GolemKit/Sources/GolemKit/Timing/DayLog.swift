import Foundation

/// Today's visits per group, for the home screen ("3 visits today, longest 4:12").
///
/// Golem doesn't add up your whole day (iOS's Screen Time already does);
/// it counts visits, and how long the longest one lasted, because that's
/// what the golem cares about: staying in one go. Only today is kept, so
/// the log starts over at midnight.
public struct DayLog: Codable, Equatable, Sendable {
    public struct Entry: Codable, Equatable, Sendable {
        public var visits = 0
        public var longestSeconds: TimeInterval = 0

        public init(visits: Int = 0, longestSeconds: TimeInterval = 0) {
            self.visits = visits
            self.longestSeconds = longestSeconds
        }
    }

    /// The start of the day the entries belong to.
    public private(set) var day: Date?
    private var entries: [UUID: Entry] = [:]

    public init() {}

    /// The group's visits today (empty if the log is from another day).
    public func entry(for groupID: UUID, at now: Date, calendar: Calendar = .current) -> Entry {
        guard let day, calendar.isDate(day, inSameDayAs: now) else { return Entry() }
        return entries[groupID] ?? Entry()
    }

    /// Whether the golem has seen any app open today.
    public func isEmpty(at now: Date, calendar: Calendar = .current) -> Bool {
        guard let day, calendar.isDate(day, inSameDayAs: now) else { return true }
        return entries.isEmpty
    }

    public mutating func visitStarted(groupID: UUID, at now: Date, calendar: Calendar = .current) {
        startDayIfNeeded(at: now, calendar: calendar)
        entries[groupID, default: Entry()].visits += 1
    }

    public mutating func visitEnded(groupID: UUID, lasting seconds: TimeInterval, at now: Date, calendar: Calendar = .current) {
        // A visit across midnight counts as today's first.
        if startDayIfNeeded(at: now, calendar: calendar) {
            entries[groupID] = Entry(visits: 1)
        }
        var entry = entries[groupID, default: Entry(visits: 1)]
        entry.longestSeconds = max(entry.longestSeconds, seconds)
        entries[groupID] = entry
    }

    /// Returns true when it started a new day.
    @discardableResult
    private mutating func startDayIfNeeded(at now: Date, calendar: Calendar) -> Bool {
        if let day, calendar.isDate(day, inSameDayAs: now) { return false }
        day = calendar.startOfDay(for: now)
        entries = [:]
        return true
    }
}
