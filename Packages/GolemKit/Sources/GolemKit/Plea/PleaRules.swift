import Foundation

/// The friction you must get through before the Golem grants more time.
///
/// To change how pleading works, start here: the plea screen only asks
/// these rules what is still missing.
public struct PleaRules: Codable, Equatable, Sendable {
    /// How long the golem takes to read, counted from your first letter.
    /// The wait starts when you start writing, not when the screen opens,
    /// so you can't just sit it out: you have to be explaining yourself.
    public var waitSeconds: Int

    /// How many characters your reason has to have.
    public var minimumReasonLength: Int

    /// How much extra time a successful plea buys.
    public var grantedMinutes: Int

    public init(waitSeconds: Int, minimumReasonLength: Int, grantedMinutes: Int) {
        self.waitSeconds = waitSeconds
        self.minimumReasonLength = minimumReasonLength
        self.grantedMinutes = grantedMinutes
    }

    public static let `default` = PleaRules(
        waitSeconds: 10,
        minimumReasonLength: 20,
        grantedMinutes: 5
    )

    /// What is still standing between you and more time.
    public enum Obstacle: Hashable, Sendable {
        case mustWait(secondsLeft: Int)
        case reasonTooShort(charactersLeft: Int)
    }

    /// Lists every unmet requirement. An empty list means the plea is granted.
    /// `secondsWriting` counts from the first letter typed (0 before that).
    public func obstacles(secondsWriting: Int, reason: String) -> [Obstacle] {
        var obstacles: [Obstacle] = []

        let secondsLeft = waitSeconds - secondsWriting
        if secondsLeft > 0 {
            obstacles.append(.mustWait(secondsLeft: secondsLeft))
        }

        let reasonLength = reason.trimmingCharacters(in: .whitespacesAndNewlines).count
        let charactersLeft = minimumReasonLength - reasonLength
        if charactersLeft > 0 {
            obstacles.append(.reasonTooShort(charactersLeft: charactersLeft))
        }

        return obstacles
    }

    public func isGranted(secondsWriting: Int, reason: String) -> Bool {
        obstacles(secondsWriting: secondsWriting, reason: reason).isEmpty
    }
}
