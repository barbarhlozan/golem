#if os(iOS)
import Foundation
@preconcurrency import ManagedSettings

/// Raises and lowers the shield that covers a group's apps.
///
/// Each group gets its own named settings store, so lowering one
/// group's shield leaves the others in place.
public enum Shields {
    /// Covers every app of the group with the Golem's shield screen.
    public static func raise(_ group: WatchGroup, store: SharedStore = SharedStore()) {
        let selection = group.appSelection
        let managedSettings = settingsStore(for: group.id)

        managedSettings.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        managedSettings.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        managedSettings.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        managedSettings.shield.webDomainCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)

        store.shieldedGroupIDs.insert(group.id)
    }

    /// Removes the group's shield; its apps work normally again.
    public static func lower(groupID: UUID, store: SharedStore = SharedStore()) {
        settingsStore(for: groupID).clearAllSettings()
        store.shieldedGroupIDs.remove(groupID)
    }

    public static func lowerAll(store: SharedStore = SharedStore()) {
        for group in store.settings.groups {
            lower(groupID: group.id, store: store)
        }
    }

    private static func settingsStore(for groupID: UUID) -> ManagedSettingsStore {
        ManagedSettingsStore(named: ManagedSettingsStore.Name(groupID.uuidString))
    }
}
#endif
