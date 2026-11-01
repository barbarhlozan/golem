import Foundation

/// The App Group shared by the app and its extensions.
/// Must match `com.apple.security.application-groups` in project.yml.
public enum AppGroup {
    public static let id = "group.cz.hlozanek.golem"
}

/// Small key-value storage that the app and all extensions can read and write.
///
/// Extensions run in separate processes, so this (App Group UserDefaults)
/// is how they talk to each other.
public struct SharedStore: Sendable {
    private enum Key {
        static let settings = "settings"
        static let appSelection = "appSelection"
        static let isShieldUp = "isShieldUp"
    }

    private let suiteName: String

    /// Pass a different suite name in tests to stay isolated.
    public init(suiteName: String = AppGroup.id) {
        self.suiteName = suiteName
    }

    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    public var settings: GolemSettings {
        get {
            guard let data = defaults.data(forKey: Key.settings),
                  let settings = try? JSONDecoder().decode(GolemSettings.self, from: data)
            else { return .default }
            return settings
        }
        nonmutating set {
            defaults.set(try? JSONEncoder().encode(newValue), forKey: Key.settings)
        }
    }

    /// The apps the user picked, as encoded `FamilyActivitySelection` data.
    /// Kept as raw data so this file doesn't depend on Screen Time.
    public var appSelectionData: Data? {
        get { defaults.data(forKey: Key.appSelection) }
        nonmutating set { defaults.set(newValue, forKey: Key.appSelection) }
    }

    /// True while the shield covers the watched apps (the limit was reached
    /// and nobody has successfully pleaded yet).
    public var isShieldUp: Bool {
        get { defaults.bool(forKey: Key.isShieldUp) }
        nonmutating set { defaults.set(newValue, forKey: Key.isShieldUp) }
    }
}
