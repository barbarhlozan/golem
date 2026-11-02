import Foundation

/// Every sentence the Golem says, in one place, so its personality
/// can be rewritten without hunting through screens and extensions.
///
/// The character: the golem wants to sleep. Scrolling wakes him up and
/// makes him watch over you. Within your limit he puts up with it; past it
/// he's grumpy. Nothing has to be earned from him: while your time flows
/// back you can simply talk to him, and he talks back.
public enum GolemVoice {
    // MARK: Shield screen (full build)

    public static let shieldTitle = "You woke the Golem"

    public static func shieldSubtitle(appName: String?, minutes: Int?) -> String {
        let app = appName ?? "this"
        guard let minutes else { return "He's been watching you scroll \(app). He'd rather be asleep." }
        return "He's watched you scroll \(app) for \(minutes) min. He'd rather be asleep."
    }

    public static let closeButton = "Close app"
    public static let talkButton = "Talk to the golem"

    // MARK: Notifications

    public static let limitReachedTitle = "The Golem is awake. And grumpy."

    public static func limitReachedBody(groupName: String, minutes: Int) -> String {
        "\(minutes) min of \(groupName) and he still can't sleep. Tap to talk to him."
    }

    public static let talkNotificationTitle = "The Golem is listening"
    public static let talkNotificationBody = "Tap to talk to him while your time flows back."

    // MARK: Live timer

    // Past the limit he speaks for himself here, like in the conversation.

    public static let islandQuestion = "Why are you keeping me awake?"

    /// On the Lock Screen between visits, when the timer has nothing to show.
    public static let lockScreenAsleep = "The Golem is asleep."

    /// The alert's text where there's no Dynamic Island (e.g. Apple Watch).
    public static func islandAlertBody(groupName: String) -> String {
        "Your \(groupName) time is up. Tap to talk to me."
    }

    // MARK: Home screen

    /// The card on the home screen while a group is over its limit.
    public static let talkCardTitle = "Talk to the golem"

    public static func talkCardSubtitle(groupName: String, overBy: String) -> String {
        "\(groupName): \(overBy) over your limit"
    }

    // MARK: Conversation
    //
    // Here the golem speaks for himself ("I"), because you're talking to him
    // face to face. So does the Island past the limit. Everywhere else
    // he's "he".

    /// His first words when the conversation opens.
    public static func talkOpening(groupName: String, overBy: String?) -> String {
        guard let overBy else {
            return "You woke me for \(groupName). Fine. What's on your mind?"
        }
        return "You kept me up \(overBy) past your \(groupName) limit. I'm awake now. Talk, while your time flows back."
    }

    public static let talkPlaceholder = "Say something…"
    public static let talkSendButton = "Send"
    public static let talkThinking = "…"
    public static let talkSleepButton = "Sleep well"

    /// Under the conversation: how long until the group is back under its limit.
    public static func talkBackUnder(in time: String) -> String {
        "Back under your limit in \(time)"
    }

    public static let talkBackUnderNow = "You're back under your limit."

    /// What the on-device model is told about who it is. The facts change
    /// with each conversation; the character doesn't.
    public static func talkInstructions(groupName: String, limitMinutes: Int, overBy: String?) -> String {
        let situation = overBy.map {
            "They are \($0) past their \(limitMinutes)-minute limit for \(groupName). Their time flows back one second for every second they stay away."
        } ?? "They opened \(groupName), which woke you, but they're still within their \(limitMinutes)-minute limit."

        return """
        You are the Golem, an old clay golem from Prague who guards this person's attention. \
        You want to sleep. Every time they scroll \(groupName), you're woken up and must watch over them. \
        \(situation)
        Speak as "I". Reply in one to three short sentences. Be dry, a little grumpy and sleepy, but you \
        care about them. Ask them simple questions about their day or what's pulling them in. Nudge them \
        to put the phone down and do something away from screens, but never lecture or moralise. \
        Never mention being an AI, a model or an app. Reply in the language they write in.
        """
    }

    /// His replies when there's no on-device model (older iPhones, Apple
    /// Intelligence off). Picked in turn, so they don't repeat right away.
    public static let talkFallbackReplies = [
        "Hm.",
        "I hear you. My eyes are still open.",
        "Every second you stay away, I get one back.",
        "Put it down. Look at something far away.",
        "Tell me something that isn't on a screen.",
        "I was dreaming of the river. Go outside, it's still there.",
        "Grumble. Go on.",
        "Then rest. Both of us.",
    ]
}
