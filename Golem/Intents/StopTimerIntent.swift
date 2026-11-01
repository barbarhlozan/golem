import AppIntents
import GolemKit

/// "Stop the timer", for when the "closed" automation can't fire.
///
/// Locking the phone inside Instagram never counts as closing it, so the
/// timer would keep running in your pocket. This intent is the Stop button
/// on the Lock Screen timer, and a Shortcuts action you can add to a Sleep
/// or Focus automation.
///
/// It's compiled into the widget extension too (the button needs the type),
/// but as a Live Activity intent it always runs in the app's process.
struct StopTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Stop Timer"
    static let description = IntentDescription(
        "Stops the Golem's timer, as if you'd closed the app."
    )

    init() {}

    func perform() async throws -> some IntentResult {
        await SessionCoordinator.stopAll(reason: "Stop Timer action")
        return .result()
    }
}
