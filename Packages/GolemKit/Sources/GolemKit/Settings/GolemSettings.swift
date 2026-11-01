import Foundation

/// Everything the user can tune. Stored as JSON in the shared container,
/// so the app and every extension see the same values.
public struct GolemSettings: Codable, Equatable, Sendable {
    /// Whether Screen Time is watching the groups' apps (full build only).
    public var isWatching: Bool

    /// The groups of apps, each with its own timer and limit.
    public var groups: [WatchGroup]

    /// How long you must stay away from a group's apps before its
    /// timer starts again from zero.
    public var breakMinutes: Int

    /// What you have to do to get more time. Shared by all groups.
    public var pleaRules: PleaRules

    public init(isWatching: Bool, groups: [WatchGroup], breakMinutes: Int, pleaRules: PleaRules) {
        self.isWatching = isWatching
        self.groups = groups
        self.breakMinutes = breakMinutes
        self.pleaRules = pleaRules
    }

    public static let `default` = GolemSettings(
        isWatching: false,
        groups: [
            WatchGroup(name: "Social", limitMinutes: 5),
            WatchGroup(name: "News", limitMinutes: 10),
        ],
        breakMinutes: 10,
        pleaRules: .default
    )

    public func group(id: UUID) -> WatchGroup? {
        groups.first { $0.id == id }
    }
}
