import Foundation

/// The golem's lines on the home screen and in the first run.
///
/// Kept apart from `GolemVoice.swift` so the Island's wording can be
/// rewritten there without touching these (and vice versa).
extension GolemVoice {
    // MARK: Home

    public static let homeTitle = "Golem"

    // The big line under the golem: what he's doing right now, so it's in
    // the present continuous. Under it, only a time when there is one:
    // asleep, he needs no explanation.
    public static let homeAsleep = "The Golem is sleeping."
    /// Time flowing back, every group within its limit.
    public static let homeSettling = "The Golem is falling asleep."
    /// Time flowing back, a group still past its limit.
    public static let homeRumbling = "The Golem is rumbling."
    public static func homeSettlingDetail(time: String) -> String {
        "\(time) until he falls asleep"
    }
    public static func homeRumblingDetail(time: String) -> String {
        "\(time) until he calms down"
    }
    /// Full build: a Screen Time shield keeps him up.
    public static let homeKeepingWatch = "The Golem is keeping watch."
    public static let homeKeepingWatchDetail = "Until midnight."

    /// Until any automation has told Golem an app opened.
    public static let homeUnseenDetail = "He has not yet seen an app open."
    public static let homeSetUpButton = "Set up automations"

    // MARK: Group rows

    public static func groupLimit(minutes: Int) -> String {
        "\(minutes) min limit"
    }

    /// While the golem rests and the used time flows back.
    public static func groupResting(time: String) -> String {
        "Resting, \(time) to go"
    }
    public static func groupOverLimit(time: String) -> String {
        "Over the limit, \(time) to go"
    }

    public static let newGroupButton = "New group"

    // MARK: First run

    /// The story pages at the start of the first run, in order: title and
    /// text. Each page has its own drawing ("Onboarding1"…"Onboarding6").
    public static func storyPages() -> [(title: String, body: String)] {
        [
            ("Meet your golem",
             "The Golem guards your attention. You wake it up by opening an app you've chosen to track."),
            ("One session at a time",
             "It doesn't count your whole day, because iOS already does that. The Golem only watches how long you stay in a tracked app in one go."),
            ("Put the golem back to sleep",
             "If you leave the app before your limit, the Golem goes back to sleep."),
            ("Break from the awakening",
             "Every second you stay out of the app gives a second back. Stay out as long as you were in, and you can wake the golem up fresh again."),
            ("Stay too long and it gets angry",
             "When you pass your limit, the Golem will interrupt you and ask why you're still there."),
            ("Orange, then red",
             "Near your limit the Golem stirs and the Island turns orange. Past it, it turns red and the Golem keeps asking why you're still there."),
        ]
    }

    public static let groupsTitle = "What wakes him"
    public static let groupsBody = "Apps in a group share one timer and one limit. Start with these, or rename them."

    public static let notificationsTitle = "He'll tell you"
    public static let notificationsBody = "On older iPhones, the Golem sends a notification when your time is up."
    public static let allowNotificationsButton = "Allow notifications"

    public static let automationsTitle = "Let him watch"
    public static let automationsBody = "iOS only tells the Golem you opened an app through a Shortcuts automation. You set it up once, two per group."

    public static let continueButton = "Continue"
    public static let finishButton = "Done"
}
