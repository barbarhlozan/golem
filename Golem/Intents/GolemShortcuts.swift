import AppIntents

/// Lists Golem's actions in the Shortcuts app as soon as Golem is installed,
/// so when you build an automation they're right under "Golem" in the
/// action list instead of needing a search.
struct GolemShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AppOpenedIntent(),
            phrases: ["\(.applicationName) app opened"],
            shortTitle: "App Opened",
            systemImageName: "eye"
        )
        AppShortcut(
            intent: AppClosedIntent(),
            phrases: ["\(.applicationName) app closed"],
            shortTitle: "App Closed",
            systemImageName: "eye.slash"
        )
        AppShortcut(
            intent: StopTimerIntent(),
            phrases: ["Stop \(.applicationName) timer", "Stop the \(.applicationName)"],
            shortTitle: "Stop Timer",
            systemImageName: "stop.circle"
        )
    }
}
