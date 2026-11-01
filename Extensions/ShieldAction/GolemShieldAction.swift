import GolemKit
import ManagedSettings

/// Handles taps on the shield's buttons.
///
/// - Close app → leave the app.
/// - Plead with the Golem → send a notification that opens Golem's plea
///   screen (extensions can't open the app directly) and keep the shield up.
final class GolemShieldAction: ShieldActionDelegate {
    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(respond(to: action))
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(respond(to: action))
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(respond(to: action))
    }

    private func respond(to action: ShieldAction) -> ShieldActionResponse {
        switch action {
        case .primaryButtonPressed:
            return .close
        case .secondaryButtonPressed:
            GolemNotifications.sendPleaInvitation()
            return .defer
        default:
            // Golem's shield has no submenu items (newer iOS versions allow them).
            return .close
        }
    }
}
