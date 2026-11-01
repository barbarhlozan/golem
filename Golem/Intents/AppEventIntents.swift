import AppIntents

// The two Shortcuts actions Golem offers. Use them in Personal Automations:
//
//   When Instagram or TikTok is opened → Golem: App Opened (Social)
//   When Instagram or TikTok is closed → Golem: App Closed (Social)
//
// They are Live Activity intents, which is what lets them start the
// Dynamic Island timer while Golem itself stays in the background.

struct AppOpenedIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "App Opened"
    static let description = IntentDescription(
        "Starts the Golem's timer for a group. Use it in a “When app is opened” automation."
    )

    @Parameter(title: "Group")
    var group: WatchGroupEntity

    init() {}

    init(group: WatchGroupEntity) {
        self.group = group
    }

    func perform() async throws -> some IntentResult {
        await SessionCoordinator.appOpened(groupID: group.id)
        return .result()
    }
}

struct AppClosedIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "App Closed"
    static let description = IntentDescription(
        "Pauses the Golem's timer for a group. Use it in a “When app is closed” automation."
    )

    @Parameter(title: "Group")
    var group: WatchGroupEntity

    init() {}

    init(group: WatchGroupEntity) {
        self.group = group
    }

    func perform() async throws -> some IntentResult {
        await SessionCoordinator.appClosed(groupID: group.id)
        return .result()
    }
}
