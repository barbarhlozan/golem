#if os(iOS)
import ActivityKit
import Foundation

/// What the Dynamic Island / Lock Screen timer needs to draw itself.
/// Shared by the app (which starts it) and the widget extension (which draws it).
///
/// Everything lives in the changing `ContentState`, the group included,
/// so one timer can be updated in place (e.g. switching a group's apps).
public struct GolemActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        /// Which group it is, so tapping the timer opens a talk about that group.
        public var groupID: UUID
        public var groupName: String

        /// When the timer would have shown 0:00 (now minus time already used).
        public var startedAt: Date

        /// When the group's time runs out.
        public var limitAt: Date

        /// True if the time was already up when the timer appeared.
        public var isOverLimit: Bool

        public init(groupID: UUID, groupName: String, startedAt: Date, limitAt: Date, isOverLimit: Bool) {
            self.groupID = groupID
            self.groupName = groupName
            self.startedAt = startedAt
            self.limitAt = limitAt
            self.isOverLimit = isOverLimit
        }
    }

    public init() {}
}
#endif
