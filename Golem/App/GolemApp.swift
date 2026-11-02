import GolemKit
import SwiftUI

@main
struct GolemApp: App {
    @UIApplicationDelegateAdaptor private var notifications: NotificationHandler
    @State private var model = GolemModel()
    @AppStorage(OnboardingView.doneKey) private var hasOnboarded = false

    init() {
        Theme.styleNavigationBars()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    HomeView()
                } else {
                    OnboardingView()
                }
            }
                .environment(model)
                .golemStyle()
                .onAppear {
                    notifications.onTalkRequest = { model.requestTalk(groupID: $0) }
                }
                // golem://talk/<id> from the Dynamic Island / Lock Screen timer.
                .onOpenURL { url in
                    if let groupID = DeepLink.talkGroupID(from: url) {
                        model.requestTalk(groupID: groupID)
                    }
                }
        }
    }
}
