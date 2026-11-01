import Foundation

/// Everything the user can tune. Stored as JSON in the shared App Group,
/// so the app and every extension see the same values.
public struct GolemSettings: Codable, Equatable, Sendable {
    /// Whether the Golem is currently watching the chosen apps.
    public var isWatching: Bool

    /// How long you may scroll before the Golem steps in.
    /// Screen Time counts in whole minutes, so this is minutes, not seconds.
    public var limitMinutes: Int

    /// What you have to do to get more time.
    public var pleaRules: PleaRules

    public init(isWatching: Bool, limitMinutes: Int, pleaRules: PleaRules) {
        self.isWatching = isWatching
        self.limitMinutes = limitMinutes
        self.pleaRules = pleaRules
    }

    public static let `default` = GolemSettings(
        isWatching: false,
        limitMinutes: 3,
        pleaRules: .default
    )

    /// The range offered in the app's settings.
    public static let allowedLimitMinutes = 1...60
}
