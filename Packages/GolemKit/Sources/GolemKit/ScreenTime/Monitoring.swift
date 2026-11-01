#if os(iOS)
@preconcurrency import DeviceActivity
import Foundation

extension DeviceActivityName {
    /// The single all-day monitoring schedule Golem uses.
    public static let golem = Self("golem")
}

extension DeviceActivityEvent.Name {
    /// Fired when the watched apps have been used for the current limit.
    public static let limitReached = Self("limitReached")
}

/// Asks iOS to wake the Monitor extension once the watched apps
/// have been used for a given number of minutes.
public enum Monitoring {
    /// Starts (or restarts) counting from zero.
    ///
    /// Restarting is how we approximate "minutes in a row": usage before
    /// this call is ignored (`includesPastActivity: false`), so after a
    /// successful plea the count starts fresh.
    public static func start(limitMinutes: Int, store: SharedStore = SharedStore()) throws {
        let selection = WatchedApps.load(from: store)

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
        center.stopMonitoring([.golem])
        try center.startMonitoring(.golem, during: allDay, events: [.limitReached: limitReached])
    }

    public static func stop() {
        DeviceActivityCenter().stopMonitoring([.golem])
    }
}
#endif
