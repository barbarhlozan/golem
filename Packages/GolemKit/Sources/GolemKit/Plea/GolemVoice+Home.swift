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

    // MARK: First run

    public static let introTitle = "Meet the Golem"
    public static let introBody = "He wants to sleep. Every scroll wakes him, and once you're past your limit he gets angry. Then you'll have to plead for more time."

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
