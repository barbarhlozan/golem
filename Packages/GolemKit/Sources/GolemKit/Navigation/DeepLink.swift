import Foundation

/// The `golem://` links that open the conversation with the golem for one
/// group, from the Dynamic Island, the Lock Screen timer, or a notification.
///
/// Without the group in the link, Golem would have to guess which group
/// you came from.
public enum DeepLink {
    public static let scheme = "golem"

    /// `golem://talk/<group id>`
    public static func talk(groupID: UUID) -> URL {
        URL(string: "\(scheme)://talk/\(groupID.uuidString)")!
    }

    /// The group of a talk link, or nil for any other URL.
    public static func talkGroupID(from url: URL) -> UUID? {
        guard url.scheme == scheme, url.host == "talk" else { return nil }
        return UUID(uuidString: url.lastPathComponent)
    }
}
