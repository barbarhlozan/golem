import Foundation

/// Every sentence the Golem says, in one place, so its personality
/// can be rewritten without hunting through screens and extensions.
public enum GolemVoice {
    // MARK: Shield screen

    public static let shieldTitle = "The Golem is watching"

    public static func shieldSubtitle(appName: String?, minutes: Int) -> String {
        let app = appName ?? "this"
        return "You've been on \(app) for \(minutes) min. Is it worth it?"
    }

    public static let closeButton = "Close app"
    public static let pleadButton = "Plead with the Golem"

    // MARK: Notifications

    public static let limitReachedTitle = "Time's up"

    public static func limitReachedBody(minutes: Int) -> String {
        "You've been scrolling for \(minutes) min. The Golem has stepped in."
    }

    public static let pleaNotificationTitle = "The Golem will hear you"
    public static let pleaNotificationBody = "Tap to make your case."

    // MARK: Plea screen

    public static let pleaTitle = "Plead with the Golem"
    public static let pleaReasonPrompt = "Why do you need more time?"

    public static func waitHint(secondsLeft: Int) -> String {
        "The Golem is thinking… \(secondsLeft)s"
    }

    public static func reasonHint(charactersLeft: Int) -> String {
        "Say a bit more (\(charactersLeft) more characters)."
    }

    public static func grantButton(minutes: Int) -> String {
        "Ask for \(minutes) more minutes"
    }

    public static let giveUpButton = "Never mind"
}
