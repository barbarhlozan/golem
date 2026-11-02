#if os(iOS)
import ActivityKit
import Foundation

/// What the Dynamic Island / Lock Screen timer needs to draw itself.
/// Shared by the app (which starts it) and the widget extension (which draws it).
public struct GolemActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        /// When the timer would have shown 0:00 (now minus time already used).
        public var startedAt: Date

        /// When the group's time runs out.
        public var limitAt: Date

        /// True if the time was already up when the timer appeared.
        public var isOverLimit: Bool

        /// True for the first few seconds. iOS shows a timer started from the
        /// background in its large form for a moment; while this is set,
        /// that form is just the slim line (eyes and time), so it doesn't
        /// drop down over the screen. See `LiveTimer.settle`.
        public var isStarting: Bool

        public init(startedAt: Date, limitAt: Date, isOverLimit: Bool, isStarting: Bool = false) {
            self.startedAt = startedAt
            self.limitAt = limitAt
            self.isOverLimit = isOverLimit
            self.isStarting = isStarting
        }
    }

    /// Which group it is, so tapping the timer opens that group's plea.
    public var groupID: UUID
    public var groupName: String

    public init(groupID: UUID, groupName: String) {
        self.groupID = groupID
        self.groupName = groupName
    }
}
#endif
