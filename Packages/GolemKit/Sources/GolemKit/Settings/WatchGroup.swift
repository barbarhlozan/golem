import Foundation

/// A set of apps that share one timer, e.g. "Reels" for Instagram + TikTok.
///
/// Switching between apps of the same group keeps the same timer running.
/// Each group has its own limit; the plea rules are shared by all groups.
public struct WatchGroup: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var limitMinutes: Int

    /// The apps picked for this group in Screen Time (an encoded
    /// `FamilyActivitySelection`). Only used by the full, Screen Time build;
    /// in GolemLite the apps are chosen in the Shortcuts automations instead.
    public var appSelectionData: Data?

    public init(id: UUID = UUID(), name: String, limitMinutes: Int, appSelectionData: Data? = nil) {
        self.id = id
        self.name = name
        self.limitMinutes = limitMinutes
        self.appSelectionData = appSelectionData
    }

    /// The range offered in the app's settings.
    public static let allowedLimitMinutes = 1...60
}
