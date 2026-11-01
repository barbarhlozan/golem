import SwiftUI

@main
struct GolemApp: App {
    @State private var model = GolemModel()

    init() {
        Theme.styleNavigationBars()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(model)
                .golemStyle()
        }
    }
}
