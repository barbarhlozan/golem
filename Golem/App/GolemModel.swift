import FamilyControls
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

    var watchedApps: FamilyActivitySelection {
        didSet { WatchedApps.save(watchedApps, to: store) }
    }

    /// Whether the user allowed Golem to use Screen Time.
    private(set) var isAuthorized: Bool

    /// True while the watched apps are blocked and a plea is needed.
    private(set) var isShieldUp: Bool

    /// The last thing that went wrong, shown to the user.
    var errorMessage: String?

    init() {
        settings = store.settings
        watchedApps = WatchedApps.load(from: store)
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        isShieldUp = store.isShieldUp
    }

    /// Re-reads state the extensions may have changed while the app was closed.
    func refresh() {
        isShieldUp = store.isShieldUp
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            await GolemNotifications.requestPermission()
        } catch {
            errorMessage = "Screen Time access was not granted: \(error.localizedDescription)"
        }
        refresh()
    }

    func startWatching() {
        do {
            try Monitoring.start(limitMinutes: settings.limitMinutes, store: store)
            settings.isWatching = true
        } catch {
            errorMessage = "Couldn't start watching: \(error.localizedDescription)"
        }
    }

    func stopWatching() {
        Monitoring.stop()
        Shields.lower(store: store)
        settings.isWatching = false
        refresh()
    }

    /// Called when a plea succeeded: unblock the apps and give
    /// `grantedMinutes` before the Golem steps in again.
    func grantMoreTime() {
        Shields.lower(store: store)
        do {
            try Monitoring.start(limitMinutes: settings.pleaRules.grantedMinutes, store: store)
        } catch {
            errorMessage = "Couldn't restart the timer: \(error.localizedDescription)"
        }
        refresh()
    }
}
