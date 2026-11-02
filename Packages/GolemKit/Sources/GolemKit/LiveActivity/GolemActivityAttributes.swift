#if os(iOS)
import ActivityKit
import Foundation

/// What the Dynamic Island / Lock Screen timer needs to draw itself.
/// Shared by the app (which starts it) and the widget extension (which draws it).
///
/// Everything lives in the changing `ContentState`, the group included:
/// Golem keeps one timer alive between visits and only updates it (see
/// `LiveTimer`), so it must be able to switch groups.
public struct GolemActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        /// Which group it is, so tapping the timer opens that group's plea.
        public var groupID: UUID
        public var groupName: String

        /// When the timer would have shown 0:00 (now minus time already used).
        public var startedAt: Date

        /// When the group's time runs out.
        public var limitAt: Date

        /// True if the time was already up when the timer appeared.
        public var isOverLimit: Bool

        /// You've left the apps: the timer stays alive but shows nothing.
        public var isAway: Bool

        public init(groupID: UUID, groupName: String, startedAt: Date, limitAt: Date, isOverLimit: Bool, isAway: Bool = false) {
            self.groupID = groupID
            self.groupName = groupName
            self.startedAt = startedAt
            self.limitAt = limitAt
            self.isOverLimit = isOverLimit
            self.isAway = isAway
        }
    }

    public init() {}
}
#endif
