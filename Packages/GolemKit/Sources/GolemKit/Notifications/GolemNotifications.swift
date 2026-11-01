import Foundation
import UserNotifications

/// Local notifications. Tapping any of them opens the app,
/// which then offers the plea screen.
public enum GolemNotifications {
    private enum ID {
        static let timeUp = "timeUp"
        static let plea = "plea"
    }

    public static func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
    }

    /// "Time's up" for a group, now or at a given moment.
    public static func scheduleTimeUp(groupName: String, minutes: Int, at date: Date = .now) {
        send(
            id: ID.timeUp,
            title: GolemVoice.limitReachedTitle,
            body: GolemVoice.limitReachedBody(groupName: groupName, minutes: minutes),
            at: date
        )
    }

    /// Called when you leave the group's apps before the time is up.
    public static func cancelTimeUp() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [ID.timeUp])
    }

    /// Sent when "Plead with the Golem" is tapped on the shield.
    /// Extensions can't open the app themselves, so this is the doorway.
    public static func sendPleaInvitation() {
        send(
            id: ID.plea,
            title: GolemVoice.pleaNotificationTitle,
            body: GolemVoice.pleaNotificationBody,
            at: .now
        )
    }

    private static func send(id: String, title: String, body: String, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let delay = date.timeIntervalSinceNow
        let trigger = delay > 1 ? UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false) : nil

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
