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
        public var groupID: UUID
        public var groupName: String

        /// When the timer would have shown 0:00 (now minus time already used).
        public var startedAt: Date

        /// When the group's time runs out.
        public var limitAt: Date

        /// How the golem is: waking (white), stirring (orange) or angry (red).
        public var moment: GolemMoment

        /// What he says in the expanded Island at this moment.
        public var line: String

        public init(groupID: UUID, groupName: String, startedAt: Date, limitAt: Date, moment: GolemMoment, line: String) {
            self.groupID = groupID
            self.groupName = groupName
            self.startedAt = startedAt
            self.limitAt = limitAt
            self.moment = moment
            self.line = line
        }
    }

    public init() {}
}
#endif
