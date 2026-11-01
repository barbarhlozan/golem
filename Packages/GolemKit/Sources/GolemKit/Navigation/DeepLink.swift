import Foundation

/// The `golem://` links that open the plea for one group, from the
/// Dynamic Island, the Lock Screen timer, or a notification.
///
/// Without the group in the link, Golem would have to guess which group
/// you were pleading for.
public enum DeepLink {
    public static let scheme = "golem"

    /// `golem://plea/<group id>`
    public static func plea(groupID: UUID) -> URL {
        URL(string: "\(scheme)://plea/\(groupID.uuidString)")!
    }

    /// The group of a plea link, or nil for any other URL.
    public static func pleaGroupID(from url: URL) -> UUID? {
        guard url.scheme == scheme, url.host == "plea" else { return nil }
        return UUID(uuidString: url.lastPathComponent)
    }
}
