import GolemKit
import SwiftUI

@main
struct GolemApp: App {
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
        }
    }
}
