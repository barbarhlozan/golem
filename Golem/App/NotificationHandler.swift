import GolemKit
import UIKit
import UserNotifications

/// Turns a tapped notification into "open the plea for this group".
///
/// It has to be the notification center's delegate before launch finishes,
/// or a tap that cold-starts Golem is lost, so it's set up in the app
/// delegate rather than in a view.
final class NotificationHandler: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    /// Set by `GolemApp`; receives the tapped notification's group.
    @MainActor var onPleaRequest: ((UUID?) -> Void)?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let groupID = GolemNotifications.groupID(of: response.notification.request.content)
        Task { @MainActor in onPleaRequest?(groupID) }
        completionHandler()
    }
}
