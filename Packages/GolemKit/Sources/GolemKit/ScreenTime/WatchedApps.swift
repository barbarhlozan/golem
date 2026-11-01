#if os(iOS)
import FamilyControls
import Foundation

/// The apps (and categories / websites) the user asked the Golem to watch.
///
/// iOS never tells us *which* apps these are — only opaque tokens —
/// so we store the picker's selection as-is and hand it back to iOS.
public enum WatchedApps {
    public static func load(from store: SharedStore = SharedStore()) -> FamilyActivitySelection {
        guard let data = store.appSelectionData,
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return FamilyActivitySelection() }
        return selection
    }

    public static func save(_ selection: FamilyActivitySelection, to store: SharedStore = SharedStore()) {
        store.appSelectionData = try? JSONEncoder().encode(selection)
    }
}

extension FamilyActivitySelection {
    /// True when the user hasn't picked anything yet.
    public var isEmpty: Bool {
        applicationTokens.isEmpty && categoryTokens.isEmpty && webDomainTokens.isEmpty
    }
}
#endif
