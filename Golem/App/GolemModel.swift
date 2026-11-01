import FamilyControls
import Foundation
import GolemKit
import Observation

/// The app's state and the actions the screens can take.
///
/// Screens read from here and call its methods; they never talk to
/// Screen Time or the shared store directly.
@MainActor
@Observable
final class GolemModel {
    private let store = SharedStore()

    var settings: GolemSettings {
        didSet { store.settings = settings }
    }

    /// Whether the user allowed Golem to use Screen Time (full build only).
    private(set) var isAuthorized: Bool

    /// Groups whose time is up, either by the Shortcuts timer or the
    /// Screen Time shield. Each needs a plea before more scrolling.
    private(set) var groupsNeedingPlea: [WatchGroup] = []

    /// The last thing that went wrong, shown to the user.
    var errorMessage: String?

    init() {
        settings = store.settings
        isAuthorized = Self.screenTimeAuthorized
        refresh()
    }

    private static var screenTimeAuthorized: Bool {
        Capabilities.screenTime && AuthorizationCenter.shared.authorizationStatus == .approved
    }

    /// Re-reads state the Shortcuts actions or extensions may have changed.
    func refresh() {
        isAuthorized = Self.screenTimeAuthorized

        let overLimit = SessionTracker(store: store).groupsOverLimit(at: .now)
        let shielded = store.shieldedGroupIDs
        groupsNeedingPlea = settings.groups.filter { group in
            shielded.contains(group.id) || overLimit.contains { $0.id == group.id }
        }
    }

    // MARK: Groups

    func addGroup() {
        settings.groups.append(WatchGroup(name: "New group", limitMinutes: 5))
    }

    func deleteGroups(at offsets: IndexSet) {
        settings.groups.remove(atOffsets: offsets)
        refresh()
    }

    // MARK: Permissions

    func requestPermissions() async {
        await GolemNotifications.requestPermission()
        guard Capabilities.screenTime else { return }
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            errorMessage = "Screen Time access was not granted: \(error.localizedDescription)"
        }
        refresh()
    }

    // MARK: Screen Time watching (full build only)

    func startWatching() {
        do {
            try Monitoring.startAll(settings.groups)
            settings.isWatching = true
        } catch {
            errorMessage = "Couldn't start watching: \(error.localizedDescription)"
        }
    }

    func stopWatching() {
        Monitoring.stopAll()
        Shields.lowerAll(store: store)
        settings.isWatching = false
        refresh()
    }

    // MARK: Pleading

    /// Called when a plea succeeded: the group gets `grantedMinutes` more.
    func grantMoreTime(for group: WatchGroup) {
        SessionTracker(store: store).grantMoreTime(groupID: group.id, at: .now)

        if Capabilities.screenTime, store.shieldedGroupIDs.contains(group.id) {
            Shields.lower(groupID: group.id, store: store)
            do {
                try Monitoring.start(group, limitMinutes: settings.pleaRules.grantedMinutes)
            } catch {
                errorMessage = "Couldn't restart the timer: \(error.localizedDescription)"
            }
        }
        refresh()
    }

    // MARK: Testing without Shortcuts

    func simulateAppOpened(in group: WatchGroup) async {
        await SessionCoordinator.appOpened(groupID: group.id)
        refresh()
    }

    func simulateAppClosed(in group: WatchGroup) async {
        await SessionCoordinator.appClosed(groupID: group.id)
        refresh()
    }
}
