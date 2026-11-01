import Foundation

/// The friction you must get through before the Golem grants more time.
///
/// To change how pleading works, start here: the plea screen only asks
/// these rules what is still missing.
public struct PleaRules: Codable, Equatable, Sendable {
    /// How long you have to sit and wait before you may plead.
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
        waitSeconds: 30,
        minimumReasonLength: 20,
        grantedMinutes: 5
    )

    /// What is still standing between you and more time.
    public enum Obstacle: Hashable, Sendable {
        case mustWait(secondsLeft: Int)
        case reasonTooShort(charactersLeft: Int)
    }

    /// Lists every unmet requirement. An empty list means the plea is granted.
    public func obstacles(secondsWaited: Int, reason: String) -> [Obstacle] {
        var obstacles: [Obstacle] = []

        let secondsLeft = waitSeconds - secondsWaited
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

    public func isGranted(secondsWaited: Int, reason: String) -> Bool {
        obstacles(secondsWaited: secondsWaited, reason: reason).isEmpty
    }
}
