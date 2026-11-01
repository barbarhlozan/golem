#if os(iOS)
@preconcurrency import ManagedSettings

/// Raises and lowers the shield that covers the watched apps.
public enum Shields {
    /// Covers every watched app with the Golem's shield screen.
    public static func raise(store: SharedStore = SharedStore()) {
        let selection = WatchedApps.load(from: store)
        let managedSettings = ManagedSettingsStore()

        managedSettings.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        managedSettings.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        managedSettings.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        managedSettings.shield.webDomainCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)

        store.isShieldUp = true
    }

    /// Removes the shield; the watched apps work normally again.
    public static func lower(store: SharedStore = SharedStore()) {
        ManagedSettingsStore().clearAllSettings()
        store.isShieldUp = false
    }
}
#endif
