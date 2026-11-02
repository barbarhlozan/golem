import Foundation

/// Everything the user can tune. Stored as JSON in the shared container,
/// so the app and every extension see the same values.
public struct GolemSettings: Codable, Equatable, Sendable {
    /// Whether Screen Time is watching the groups' apps (full build only).
    public var isWatching: Bool

    /// The groups of apps, each with its own timer and limit.
    public var groups: [WatchGroup]

    public init(isWatching: Bool, groups: [WatchGroup]) {
        self.isWatching = isWatching
        self.groups = groups
    }

    /// Two starter groups to show the idea; users rename, add and delete
    /// groups as they like (e.g. one group per app).
    public static let `default` = GolemSettings(
        isWatching: false,
        groups: [
            WatchGroup(name: "Reels", limitMinutes: 5),   // Instagram, TikTok, YouTube Shorts…
            WatchGroup(name: "Feeds", limitMinutes: 10),  // X, Bluesky, Threads…
        ]
    )

    public func group(id: UUID) -> WatchGroup? {
        groups.first { $0.id == id }
    }
}
