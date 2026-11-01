import Foundation

/// The golem's lines on the home screen and in the first run.
///
/// Kept apart from `GolemVoice.swift` so the plea's wording can be
/// rewritten there without touching these (and vice versa).
extension GolemVoice {
    // MARK: Home

    public static let homeAsleep = "He's asleep. Keep it that way."
    public static let homeAngry = "He's awake, and he's not happy."
    public static let groupRested = "Rested"

    public static func groupUsage(used: String, limitMinutes: Int) -> String {
        "\(used) of \(limitMinutes) min"
    }

    /// Under a group's bar while the golem rests and the time flows back.
    public static func groupResting(freshIn: String) -> String {
        "Resting · fresh in \(freshIn)"
    }

    // MARK: First run

    /// The story pages at the start of the first run, in order: title and
    /// text. Each page has its own drawing ("Onboarding1"…"Onboarding6").
    public static func storyPages(breakMinutes: Int) -> [(title: String, body: String)] {
        [
            ("Meet your golem",
             "The Golem guards your attention. You wake it up by opening an app you've chosen to track."),
            ("One session at a time",
             "It doesn't count your whole day, because iOS already does that. The Golem only watches how long you stay in a tracked app in one go."),
            ("Put the golem back to sleep",
             "If you leave the app before your limit, the Golem goes back to sleep."),
            ("Break from the awakening",
             "While you're out of the app, your time slowly flows back. Stay out for \(breakMinutes) minutes and it's fully reset, so you can wake the golem up again."),
            ("Stay too long and it gets angry",
             "When you pass your limit, the Golem will interrupt you and ask why you're still there."),
            ("Plead your case",
             "Give the Golem a good reason and it might grant you more time."),
        ]
    }

    public static let groupsTitle = "What wakes him"
    public static let groupsBody = "Apps in a group share one timer and one limit. Start with these, or rename them."

    public static let notificationsTitle = "He'll tell you"
    public static let notificationsBody = "When your time is up, the Golem sends a notification. Tap it to plead with him."
    public static let allowNotificationsButton = "Allow notifications"

    public static let automationsTitle = "Let him watch"
    public static let automationsBody = "iOS only tells the Golem you opened an app through a Shortcuts automation. You set it up once, two per group."

    public static let continueButton = "Continue"
    public static let finishButton = "Done"
}
