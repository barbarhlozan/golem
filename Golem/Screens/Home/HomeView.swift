import GolemKit
import SwiftUI

/// The main screen: the golem big, how he feels and why, and your groups
/// as small chips under him. Everything else (automations, blocking, the
/// debug menu) is behind the gear in `SettingsView`.
///
/// It follows Apple's conventions: the buttons ("+" to add a group, the
/// gear) live in the navigation bar. It's always dark (`Theme.night`):
/// the white golem reads best on the ink of his own outline.
///
/// On opening, the golem fades in out of the dark, and then the chips
/// float up after him (`GroupChips`).
struct HomeView: View {
    @Environment(GolemModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isShowingSettings = false
    @State private var isShowingSetupGuide = false
    /// False for the first frame, so the entrance has something to animate from.
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            GeometryReader { screen in
                ScrollView {
                    VStack(spacing: 28) {
                        GolemMood(isShowingSetupGuide: $isShowingSetupGuide)
                            .opacity(hasAppeared ? 1 : 0)
                            .scaleEffect(hasAppeared || reduceMotion ? 1 : 0.94)
                            .blur(radius: hasAppeared || reduceMotion ? 0 : 8)

                        GroupChips(isShown: hasAppeared)
                    }
                    .padding(.horizontal, 24)
                    // Centred when it fits; a little above the middle, where
                    // the eye puts it.
                    .padding(.bottom, 40)
                    .frame(maxWidth: .infinity, minHeight: screen.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .background(Theme.night)
            // No visible title: the golem is the heading. The title is still
            // set, so screens pushed from here get "‹ Golem" as their back
            // button; it's only removed from this bar.
            .navigationTitle(GolemVoice.homeTitle)
            .navigationBarTitleDisplayMode(.inline)
            .hidingBarTitle()
            .toolbar { toolbar }
            .navigationDestination(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .navigationDestination(isPresented: $isShowingSetupGuide) {
                SetupGuideView()
            }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { model.errorMessage != nil },
                    set: { if !$0 { model.errorMessage = nil } }
                ),
                actions: {},
                message: { Text(model.errorMessage ?? "") }
            )
        }
        // The whole stack, so the toolbar's ink turns light too, and the
        // screens pushed from here match the dark page.
        .environment(\.colorScheme, .dark)
        .onAppear {
            withAnimation(.easeOut(duration: reduceMotion ? 0.3 : 1.2)) { hasAppeared = true }
        }
        .task {
            await model.requestPermissions()
        }
        // While the golem rests, used time flows back by the second: re-read
        // it so the chips and his mood keep up.
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                model.refresh()
            }
        }
        .onChange(of: scenePhase, initial: true) {
            guard scenePhase == .active else { return }
            Task { await model.appBecameActive() }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(GolemVoice.newGroupButton, systemImage: "plus") {
                withAnimation(.snappy) { model.addGroup() }
            }
            Button("Settings", systemImage: "gearshape") { isShowingSettings = true }
        }
    }
}

private extension View {
    /// Removes the title from the navigation bar but keeps it for the back
    /// button of pushed screens (iOS 18+; older iOS shows it small).
    @ViewBuilder
    func hidingBarTitle() -> some View {
        if #available(iOS 18.0, *) {
            toolbar(removing: .title)
        } else {
            self
        }
    }
}

#Preview {
    HomeView()
        .environment(GolemModel())
}
