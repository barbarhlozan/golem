import GolemKit
import SwiftUI

@main
struct GolemApp: App {
    @UIApplicationDelegateAdaptor private var notifications: NotificationHandler
    @State private var model = GolemModel()

    init() {
        Theme.styleNavigationBars()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(model)
                .golemStyle()
                .onAppear {
                    notifications.onPleaRequest = { model.requestPlea(groupID: $0) }
                }
                // golem://plea/<id> from the Dynamic Island / Lock Screen timer.
                .onOpenURL { url in
                    if let groupID = DeepLink.pleaGroupID(from: url) {
                        model.requestPlea(groupID: groupID)
                    }
                }
        }
    }
}
