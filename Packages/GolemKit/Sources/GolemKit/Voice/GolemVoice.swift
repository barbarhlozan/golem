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
    // In the Island he speaks for himself ("I"). The lines come from
    // `GolemLines`: written ahead by the on-device model where there is
    // one, otherwise these hand-written ones.

    /// The hand-written lines for each moment, used when there's no
    /// on-device model or its lines haven't been written yet.
    public static func fallbackLines(_ moment: GolemMoment) -> [String] {
        switch moment {
        case .waking:
            [
                "Mm. I'm up. I'm watching.",
                "You opened it again. I'm awake now.",
                "One eye open. Go on.",
                "I was dreaming of the river. Fine.",
                "Awake. Briefly, I hope.",
            ]
        case .stirring:
            [
                "Almost time. I'm getting restless.",
                "Nearly your limit. Start wrapping up.",
                "My eyes are getting heavy. Are yours?",
                "A minute or so left. I'm counting.",
                "I'm stirring. Don't make me stand up.",
            ]
        case .angry:
            [
                "Why are you keeping me awake?",
                "Past your limit. I'm still here.",
                "I should be asleep. So should your thumb.",
                "Every second here is one I don't sleep.",
                "Put it down. Let us both rest.",
                "Still scrolling? I'm still watching.",
            ]
        }
    }

    /// What the on-device model is asked for: a batch of short lines for
    /// one moment, in the golem's voice.
    public static let writerInstructions = """
        You are the Golem, an old clay golem from Prague who guards a person's attention. \
        You want to sleep, but every time they open a social media app you wake up and must watch them scroll. \
        You write very short lines that appear in the iPhone's Dynamic Island. \
        Each line is at most 8 words, spoken as "I", dry, sleepy and a little grumpy, but caring. \
        Never lecture, never use hashtags or emoji, never mention being an AI or an app.
        """

    public static func writerPrompt(_ moment: GolemMoment, count: Int) -> String {
        let moment = switch moment {
        case .waking: "they just opened the app and woke you up; you start watching"
        case .stirring: "they are close to their time limit; you're getting restless"
        case .angry: "they are past their time limit and still scrolling; you're annoyed and want to know why you're kept awake"
        }
        return "Write \(count) different lines for this moment: \(moment)."
    }
}
