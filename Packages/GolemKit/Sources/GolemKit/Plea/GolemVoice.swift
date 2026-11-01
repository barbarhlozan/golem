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

    // Past the limit he speaks for himself here, like on the plea screen.

    public static let islandQuestion = "Why are you keeping me awake?"

    /// The alert's text where there's no Dynamic Island (e.g. Apple Watch).
    public static func islandAlertBody(groupName: String) -> String {
        "Your \(groupName) time is up. Tap to answer."
    }

    // MARK: Plea screen
    //
    // Here the golem speaks for himself ("I"), because you're talking to him
    // face to face. So does the Island past the limit. Everywhere else
    // he's "he".

    public static let pleaQuestion = "Why must I stay awake and guard you from the doom?"
    public static let pleaPlaceholder = "Because…"

    /// The golem's reply under the text box, as you write.
    public static func pleaHint(
        obstacles: [PleaRules.Obstacle],
        hasStartedWriting: Bool,
        grantedMinutes: Int
    ) -> String {
        guard hasStartedWriting else { return "Start writing. I'm listening." }

        var secondsLeft: Int?
        var lettersLeft: Int?
        for obstacle in obstacles {
            switch obstacle {
            case .mustWait(let seconds): secondsLeft = seconds
            case .reasonTooShort(let letters): lettersLeft = letters
            }
        }

        switch (secondsLeft, lettersLeft) {
        case let (seconds?, letters?):
            return "I read slowly. \(seconds)s · \(moreLetters(letters))"
        case let (seconds?, nil):
            return "I read slowly. \(seconds)s"
        case let (nil, letters?):
            return "Not convinced. \(moreLetters(letters))"
        case (nil, nil):
            return "Fine. \(grantedMinutes) minutes, no more."
        }
    }

    private static func moreLetters(_ count: Int) -> String {
        count == 1 ? "1 more letter" : "\(count) more letters"
    }

    public static func overLimitTitle(groupName: String) -> String {
        "\(groupName): he wants to sleep"
    }

    public static func grantButton(minutes: Int) -> String {
        "Keep me up \(minutes) more minutes"
    }

    public static let giveUpButton = "Let him sleep"
}
