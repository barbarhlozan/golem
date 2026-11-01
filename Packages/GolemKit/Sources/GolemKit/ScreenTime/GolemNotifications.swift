import UserNotifications

/// Local notifications sent by the extensions. Tapping any of them opens the app.
public enum GolemNotifications {
    public static func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
    }

    /// "You've been scrolling for N min."
    public static func sendLimitReached(minutes: Int) {
        send(
            id: "limitReached",
            title: GolemVoice.limitReachedTitle,
            body: GolemVoice.limitReachedBody(minutes: minutes)
        )
    }

    /// Sent when "Plead with the Golem" is tapped on the shield.
    /// Extensions can't open the app themselves, so this is the doorway.
    public static func sendPleaInvitation() {
        send(
            id: "plea",
            title: GolemVoice.pleaNotificationTitle,
            body: GolemVoice.pleaNotificationBody
        )
    }

    private static func send(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
