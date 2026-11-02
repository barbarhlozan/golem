import Foundation
import UserNotifications

/// Local notifications (before iOS 26, where the Island can't pop open at
/// the limit by itself). Tapping one opens the app. Each carries its
/// group's ID (`groupID(of:)`).
public enum GolemNotifications {
    private enum ID {
        static let timeUp = "timeUp"
    }

    private static let groupIDKey = "groupID"

    /// The group a tapped notification was about, if it names one.
    public static func groupID(of content: UNNotificationContent) -> UUID? {
        (content.userInfo[groupIDKey] as? String).flatMap(UUID.init(uuidString:))
    }

    public static func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
    }

    /// "Time's up" for a group, now or at a given moment.
    public static func scheduleTimeUp(groupID: UUID, groupName: String, minutes: Int, at date: Date = .now) {
        send(
            id: ID.timeUp,
            groupID: groupID,
            title: GolemVoice.limitReachedTitle,
            body: GolemVoice.limitReachedBody(groupName: groupName, minutes: minutes),
            at: date
        )
    }

    /// Called when you leave the group's apps before the time is up.
    public static func cancelTimeUp() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [ID.timeUp])
    }

    private static func send(id: String, groupID: UUID?, title: String, body: String, at date: Date) {
        let content = UNMutableNotificationContent()
        if let groupID {
            content.userInfo = [groupIDKey: groupID.uuidString]
        }
        content.title = title
        content.body = body
        content.sound = .default

        let delay = date.timeIntervalSinceNow
        let trigger = delay > 1 ? UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false) : nil

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
