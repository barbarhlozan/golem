#if os(iOS)
@preconcurrency import DeviceActivity
import Foundation

extension DeviceActivityName {
    private static let groupPrefix = "group-"

    /// Each group has its own all-day schedule, so restarting one
    /// group's count doesn't touch the others.
    public static func group(_ id: UUID) -> Self {
        Self(groupPrefix + id.uuidString)
    }

    /// The group a schedule belongs to, if it's one of Golem's.
    public var groupID: UUID? {
        guard rawValue.hasPrefix(Self.groupPrefix) else { return nil }
        return UUID(uuidString: String(rawValue.dropFirst(Self.groupPrefix.count)))
    }
}

extension DeviceActivityEvent.Name {
    /// Fired when a group's apps have been used for its current limit.
    public static let limitReached = Self("limitReached")
}

/// Asks iOS to wake the Monitor extension once a group's apps
/// have been used for a given number of minutes.
public enum Monitoring {
    /// Starts (or restarts) counting a group from zero.
    ///
    /// Restarting is how we approximate "minutes in a row": usage before
    /// this call is ignored (`includesPastActivity: false`).
    public static func start(_ group: WatchGroup, limitMinutes: Int) throws {
        let selection = group.appSelection
        guard !selection.isEmpty else { return }

        let allDay = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        let limitReached = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: limitMinutes),
            includesPastActivity: false
        )

        let center = DeviceActivityCenter()
        center.stopMonitoring([.group(group.id)])
        try center.startMonitoring(.group(group.id), during: allDay, events: [.limitReached: limitReached])
    }

    public static func startAll(_ groups: [WatchGroup]) throws {
        for group in groups {
            try start(group, limitMinutes: group.limitMinutes)
        }
    }

    public static func stopAll() {
        DeviceActivityCenter().stopMonitoring()
    }
}
#endif
