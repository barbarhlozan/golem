import DeviceActivity
import GolemKit

/// iOS wakes this extension in the background when something happens
/// in the monitoring schedule. It has no UI and only a few seconds to run.
final class GolemMonitor: DeviceActivityMonitor {
    private let store = SharedStore()

    /// The watched apps were used for the current limit: step in.
    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        guard event == .limitReached else { return }

        Shields.raise(store: store)
        GolemNotifications.sendLimitReached(minutes: store.settings.limitMinutes)
    }

    /// A new day began: start with a clean slate.
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        Shields.lower(store: store)
    }
}
