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
    /// Screen Time shield. While one is, you can talk to the golem.
    private(set) var groupsOverLimit: [WatchGroup] = []

    /// Whether the golem is awake on the home screen. Only a Screen Time
    /// shield keeps him up: otherwise you've left the apps (you're in Golem)
    /// and he's asleep, resting, even if a group is still over its limit.
    private(set) var isGolemAwake = false

    /// A talk someone asked for by tapping the timer, a notification or the
    /// shield. Nil group: none named, talk about the most recent one.
    private(set) var talkRequest: TalkRequest?

    struct TalkRequest: Equatable {
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
        groupsOverLimit = overLimit + shielded.filter { group in
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

    func isOverLimit(_ group: WatchGroup) -> Bool {
        groupsOverLimit.contains { $0.id == group.id }
    }

    /// How far past its limit the group is (zero within it). Shrinks while
    /// the golem rests.
    func overBySeconds(of group: WatchGroup) -> TimeInterval {
        let now = refreshedAt
        return SessionTracker(store: store).session(for: group.id, at: now)
            .overBy(limitMinutes: group.limitMinutes, at: now)
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

    // MARK: Talking to the golem

    func requestTalk(groupID: UUID?) {
        talkRequest = TalkRequest(groupID: groupID)
    }

    /// Which group to talk about after a tap: the tapped one, or without
    /// one named, the group over its limit you were in most recently.
    /// Clears the request. Nothing opens by itself without a tap.
    func takeGroupToTalk() -> WatchGroup? {
        guard let request = talkRequest else { return nil }
        talkRequest = nil
        refresh()
        if let id = request.groupID, let group = settings.group(id: id) {
            return group
        }
        return groupsOverLimit.first
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
