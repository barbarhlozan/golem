import Foundation

/// Every sentence the Golem says, in one place, so its personality
/// can be rewritten without hunting through screens and extensions.
///
/// The character: the golem wants to sleep. Scrolling wakes him up and
/// makes him watch over you. Within your limit he puts up with it; near it
/// he stirs, and past it he's grumpy and keeps asking why he's awake.
/// Nothing has to be earned from him: leave, and your time flows back.
public enum GolemVoice {
    // MARK: Shield screen (full build)

    public static let shieldTitle = "You woke the Golem"

    public static func shieldSubtitle(appName: String?, minutes: Int?) -> String {
        let app = appName ?? "this"
        guard let minutes else { return "He's been watching you scroll \(app). He'd rather be asleep." }
        return "He's watched you scroll \(app) for \(minutes) min. He'd rather be asleep."
    }

    public static let closeButton = "Close app"

    // MARK: Notifications (before iOS 26)

    public static let limitReachedTitle = "The Golem is awake. And grumpy."

    public static func limitReachedBody(groupName: String, minutes: Int) -> String {
        "\(minutes) min of \(groupName) and he still can't sleep."
    }

    // MARK: Live timer

    /// The alert's text where there's no Dynamic Island (e.g. Apple Watch).
    public static func islandAlertBody(groupName: String) -> String {
        "Your \(groupName) time is up."
    }

    // MARK: His lines in the Island
    //
    // Short and plain, about the golem rather than from him: "The golem
    // woke up." The lines come from `GolemLines`: written ahead by the
    // on-device model where there is one, otherwise these hand-written ones.

    /// The hand-written lines for each moment, used when there's no
    /// on-device model or its lines haven't been written yet.
    public static func fallbackLines(_ moment: GolemMoment) -> [String] {
        switch moment {
        case .waking:
            [
                "The golem woke up.",
                "The golem is awake now.",
                "The golem is watching.",
                "The protector is watching.",
                "The golem opens his eyes.",
            ]
        case .stirring:
            [
                "The golem is getting restless.",
                "The golem stirs.",
                "Almost time. The golem knows.",
                "The protector is getting uneasy.",
                "The golem counts the minutes.",
            ]
        case .angry:
            [
                "The golem is angry.",
                "Time is up. The golem is watching.",
                "The golem wants to sleep.",
                "The protector is still awake.",
                "The golem asks why you're here.",
                "Still here. The golem sees it.",
            ]
        }
    }

    /// What the on-device model is asked for: a batch of short lines for
    /// one moment, about the golem. The hand-written lines above are the
    /// example of the tone.
    public static let writerInstructions = """
        You write very short lines for an iPhone's Dynamic Island, about the Golem:         an old clay golem from Prague, a protector who guards the user's attention and wants to sleep.         Every time the user opens a social media app, the golem wakes up and watches.         Write about the golem in the third person, in plain, simple words,         like "The golem woke up.", "The golem is watching." or "The protector is watching."         Each line is at most 6 words and one short sentence.         No "I", no clever wordplay, no questions to the user, no hashtags or emoji,         and never mention AI, apps or phones.
        """

    public static func writerPrompt(_ moment: GolemMoment, count: Int) -> String {
        let moment = switch moment {
        case .waking: "the user just opened the app; the golem wakes up and starts watching"
        case .stirring: "the user is close to their time limit; the golem is getting restless"
        case .angry: "the user is past their time limit and still scrolling; the golem is angry and wants to sleep"
        }
        return "Write \(count) different lines for this moment: \(moment)."
    }
}
