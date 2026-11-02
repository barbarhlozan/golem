import Foundation

/// The golem's lines on the home screen and in the first run.
///
/// Kept apart from `GolemVoice.swift` so the Island's wording can be
/// rewritten there without touching these (and vice versa).
extension GolemVoice {
    // MARK: Home

    public static let homeTitle = "Golem"

    // The big line under the golem, and the smaller one under it. He's an
    // old, majestic creature, not a baby having a nap: short, grave lines.
    // Each detail stays one short line, so the rows below don't jump.
    public static let homeAsleep = "The Golem sleeps."
    public static let homeAsleepDetail = "Do not wake him."
    /// Time flowing back, every group within its limit.
    public static let homeSettling = "The Golem settles."
    /// Time flowing back, a group still past its limit.
    public static let homeRumbling = "The Golem rumbles."
    public static func homeSettlingDetail(group: String, time: String) -> String {
        "\(group): \(time) until he sleeps"
    }
    public static func homeRumblingDetail(group: String, time: String) -> String {
        "\(group): \(time) until he quiets"
    }
    /// Full build: a Screen Time shield keeps him up.
    public static let homeKeepingWatch = "The Golem keeps watch."
    public static let homeKeepingWatchDetail = "Until midnight."

    /// Until any automation has told Golem an app opened.
    public static let homeUnseenDetail = "He has not yet seen an app open."
    public static let homeSetUpButton = "Set up automations"

    // MARK: Group rows

    public static func groupLimit(minutes: Int) -> String {
        "\(minutes) min limit"
    }

    public static let groupFresh = "Fresh"
    /// While the golem rests and the used time flows back.
    public static func groupResting(time: String) -> String {
        "Resting, \(time) to go"
    }
    public static func groupOverLimit(time: String) -> String {
        "Over the limit, \(time) to go"
    }

    public static func groupToday(visits: Int, longest: String) -> String {
        switch visits {
        case 0: "No visits today"
        case 1: "Today: one visit, \(longest)"
        default: "Today: \(visits) visits, longest \(longest)"
        }
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
