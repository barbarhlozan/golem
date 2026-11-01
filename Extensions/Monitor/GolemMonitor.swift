import DeviceActivity
import GolemKit

/// iOS wakes this extension in the background when something happens
/// in a group's monitoring schedule. It has no UI and only a few seconds to run.
final class GolemMonitor: DeviceActivityMonitor {
    private let store = SharedStore()

    /// A group's apps were used for its current limit: step in.
    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        guard event == .limitReached,
              let groupID = activity.groupID,
              let group = store.settings.group(id: groupID)
        else { return }

        Shields.raise(group, store: store)
        GolemNotifications.scheduleTimeUp(groupName: group.name, minutes: group.limitMinutes)
    }

    /// A new day began: start the group with a clean slate.
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        guard let groupID = activity.groupID else { return }
        Shields.lower(groupID: groupID, store: store)
    }
}
