import Foundation

/// Every sentence the Golem says, in one place, so its personality
/// can be rewritten without hunting through screens and extensions.
///
/// The character: the golem wants to sleep. Scrolling wakes him up and
/// makes him watch over you. Within your limit he puts up with it; past it
/// he's grumpy, and you have to plead for him to stay up a little longer.
public enum GolemVoice {
    // MARK: Shield screen (and the home screen's "time's up" section)

    public static let shieldTitle = "You woke the Golem"

    public static func shieldSubtitle(appName: String?, minutes: Int?) -> String {
        let app = appName ?? "this"
        guard let minutes else { return "He's been watching you scroll \(app). He'd rather be asleep." }
        return "He's watched you scroll \(app) for \(minutes) min. He'd rather be asleep."
    }

    public static let closeButton = "Close app"
    public static let pleadButton = "Plead with the Golem"

    // MARK: Notifications

    public static let limitReachedTitle = "The Golem is awake. And grumpy."

    public static func limitReachedBody(groupName: String, minutes: Int) -> String {
        "\(minutes) min of \(groupName) and he still can't sleep. Tap to plead with him."
    }

    public static let pleaNotificationTitle = "The Golem will hear you"
    public static let pleaNotificationBody = "Make it quick. He wants to sleep."

    // MARK: Live timer

    /// Shown when the Island pops open because you're back past your limit.
    public static let angryAlertTitle = "The Golem is up again"

    public static func angryAlertBody(groupName: String) -> String {
        "Your \(groupName) time is up. Plead with him or let him sleep."
    }

    // MARK: Plea screen

    public static let pleaTitle = "Plead with the Golem"
    public static let pleaReasonPrompt = "Why must he stay awake?"

    public static func overLimitTitle(groupName: String) -> String {
        "\(groupName): he wants to sleep"
    }

    public static func waitHint(secondsLeft: Int) -> String {
        "The Golem grumbles… \(secondsLeft)s"
    }

    public static func reasonHint(charactersLeft: Int) -> String {
        "He's not convinced. Say more (\(charactersLeft) characters)."
    }

    public static func grantButton(minutes: Int) -> String {
        "Keep him up \(minutes) more minutes"
    }

    public static let giveUpButton = "Let him sleep"
}

// Added by the flow fixes; kept apart so the wording rewrite can fold it in.
extension GolemVoice {
    /// The button on the Lock Screen timer. Locking the phone inside an
    /// app doesn't stop the timer, so this lets you put him back to sleep.
    public static let stopTimerButton = "Let him sleep"
}
