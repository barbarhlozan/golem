import Foundation

/// The App Group container shared by the app and its extensions.
/// Must match `com.apple.security.application-groups` in project.yml.
public enum SharedContainer {
    public static let id = "group.cz.hlozanek.golem"
}

/// Small key-value storage that the app and all extensions can read and write.
///
/// Extensions run in separate processes, so this (App Group UserDefaults)
/// is how they talk to each other. GolemLite has no App Group; there the
/// same storage simply stays inside the app, which is all it needs.
public struct SharedStore: Sendable {
    private enum Key {
        static let settings = "settings"
        static let sessions = "sessions"
        static let shieldedGroupIDs = "shieldedGroupIDs"
        static let lineBook = "lineBook"
    }

    private let suiteName: String

    /// Pass a different suite name in tests to stay isolated.
    public init(suiteName: String = SharedContainer.id) {
        self.suiteName = suiteName
    }

    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    public var settings: GolemSettings {
        get {
            if let settings = decoded(GolemSettings.self, forKey: Key.settings) {
                return settings
            }
            // Save the defaults on first use, so the default groups keep
            // the same IDs everywhere (Shortcuts automations refer to them).
            encode(GolemSettings.default, forKey: Key.settings)
            return .default
        }
        nonmutating set { encode(newValue, forKey: Key.settings) }
    }

    /// The running or paused timer of each group, by group ID.
    public var sessions: [UUID: GroupSession] {
        get { decoded([UUID: GroupSession].self, forKey: Key.sessions) ?? [:] }
        nonmutating set { encode(newValue, forKey: Key.sessions) }
    }

    /// The golem's lines written ahead for the Dynamic Island (`GolemLines`).
    public var lineBook: LineBook {
        get { decoded(LineBook.self, forKey: Key.lineBook) ?? LineBook() }
        nonmutating set { encode(newValue, forKey: Key.lineBook) }
    }

    /// Groups whose apps are currently covered by the Screen Time shield.
    public var shieldedGroupIDs: Set<UUID> {
        get { decoded(Set<UUID>.self, forKey: Key.shieldedGroupIDs) ?? [] }
        nonmutating set { encode(newValue, forKey: Key.shieldedGroupIDs) }
    }

    private func decoded<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func encode(_ value: some Encodable, forKey key: String) {
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }
}
