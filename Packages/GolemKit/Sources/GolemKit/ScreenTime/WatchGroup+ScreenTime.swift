#if os(iOS)
import FamilyControls
import Foundation
import ManagedSettings

/// The apps (and categories / websites) picked for a group in Screen Time.
///
/// iOS never tells us *which* apps these are — only opaque tokens —
/// so we store the picker's selection as-is and hand it back to iOS.
extension WatchGroup {
    public var appSelection: FamilyActivitySelection {
        get {
            guard let data = appSelectionData,
                  let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            else { return FamilyActivitySelection() }
            return selection
        }
        set { appSelectionData = try? JSONEncoder().encode(newValue) }
    }

    /// Whether this group's Screen Time selection includes the given app.
    public func contains(_ application: ApplicationToken?) -> Bool {
        guard let application else { return false }
        return appSelection.applicationTokens.contains(application)
    }
}

extension FamilyActivitySelection {
    /// True when the user hasn't picked anything yet.
    public var isEmpty: Bool {
        applicationTokens.isEmpty && categoryTokens.isEmpty && webDomainTokens.isEmpty
    }
}
#endif
