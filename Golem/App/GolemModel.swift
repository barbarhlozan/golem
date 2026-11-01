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
    /// Internal, not private, for the debug menu (`GolemModel+Debug`).
    let store = SharedStore()

    var settings: GolemSettings {
        didSet { store.settings = settings }
    }

    /// Whether the user allowed Golem to use Screen Time (full build only).
    private(set) var isAuthorized: Bool

    /// Groups whose time is up, either by the Shortcuts timer or the
    /// Screen Time shield. Each needs a plea before more scrolling.
    private(set) var groupsNeedingPlea: [WatchGroup] = []

    /// Whether the golem is awake on the home screen. Only a Screen Time
    /// shield keeps him up: otherwise you've left the apps (you're in Golem)
    /// and he's asleep, resting, even if a group is still over its limit.
    private(set) var isGolemAwake = false

    /// A plea someone asked for by tapping a notification or the timer.
    /// Nil group: no group named, plead for the most recent one.
    private(set) var pleaRequest: PleaRequest?

    struct PleaRequest: Equatable {
        let groupID: UUID?
    }

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

    /// When `refresh` last ran. The timers live in `SharedStore`, which
    /// SwiftUI can't observe; reading this makes a view redraw on refresh.
    private(set) var refreshedAt = Date.now

    /// Re-reads state the Shortcuts actions or extensions may have changed.
    func refresh() {
        refreshedAt = .now
        isAuthorized = Self.screenTimeAuthorized

        // Most recently used first (see `SessionTracker.groupsOverLimit`).
        let overLimit = SessionTracker(store: store).groupsOverLimit(at: .now)
        let shielded = settings.groups.filter { store.shieldedGroupIDs.contains($0.id) }
        groupsNeedingPlea = overLimit + shielded.filter { group in
            !overLimit.contains { $0.id == group.id }
        }
        isGolemAwake = !shielded.isEmpty
    }

    /// Golem is in front, so none of the watched apps can be: stop any
    /// timer still running. This catches "closed" events that never came.
    func appBecameActive() async {
        await SessionCoordinator.stopAll(reason: "Golem opened")
        refresh()
    }

    // MARK: Groups

    func addGroup() {
        settings.groups.append(WatchGroup(name: "New group", limitMinutes: 5))
    }

    func deleteGroup(id: UUID) {
        settings.groups.removeAll { $0.id == id }
        refresh()
    }

    /// Time used in the group's current session (it flows back, a second
    /// per second, while the golem rests; the home screen refreshes every
    /// second to show that).
    func usedSeconds(of group: WatchGroup) -> TimeInterval {
        let now = refreshedAt
        return SessionTracker(store: store).session(for: group.id, at: now).elapsed(at: now)
    }

    /// Whether the group's golem is resting (its time flowing back).
    func isResting(_ group: WatchGroup) -> Bool {
        SessionTracker(store: store).isResting(group.id, at: refreshedAt)
    }

    func needsPlea(_ group: WatchGroup) -> Bool {
        groupsNeedingPlea.contains { $0.id == group.id }
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

    func requestPlea(groupID: UUID?) {
        pleaRequest = PleaRequest(groupID: groupID)
    }

    /// Which group to plead for now, if any. After a tap on the timer or a
    /// notification: the tapped group if its time is really up, otherwise
    /// the group you were in most recently. Without a tap, only a group you
    /// left past its limit just now: after "Sorry. Sleep well." he stays
    /// asleep when you come back. Clears the request.
    func takeGroupToPlead() -> WatchGroup? {
        refresh()
        guard let request = pleaRequest else {
            let justLeft = SessionTracker(store: store).groupsJustLeftOverLimit(at: .now)
            return groupsNeedingPlea.first { group in justLeft.contains { $0.id == group.id } }
        }
        pleaRequest = nil
        return groupsNeedingPlea.first { $0.id == request.groupID } ?? groupsNeedingPlea.first
    }

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
