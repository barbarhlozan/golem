import GolemKit
import SwiftUI

/// The main screen: the golem big, how he feels and why, then your groups.
/// Everything else (automations, blocking, the debug menu) is behind the
/// gear in `SettingsView`.
///
/// It follows Apple's conventions: the buttons ("+" to add a group, the
/// gear) live in the navigation bar, and the groups are a real
/// list, so rows highlight when tapped and swipe left to delete. It's
/// always dark (`Theme.night`): the white golem reads best on the ink of
/// his own outline.
struct HomeView: View {
    @Environment(GolemModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    @State private var isShowingSettings = false
    @State private var isShowingSetupGuide = false
    // Heights for centring the content when it fits (`topMargin`). They're
    // the screen's and the rows' own, which moving the content doesn't
    // change, so measuring can't loop.
    @State private var screenHeight: CGFloat = 0
    @State private var moodHeight: CGFloat = 0
    @State private var rowHeights: [UUID: CGFloat] = [:]

    var body: some View {
        NavigationStack {
            List {
                GolemMood(isShowingSetupGuide: $isShowingSetupGuide)
                    .frame(maxWidth: .infinity)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { moodHeight = $0 }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 24, bottom: 16, trailing: 24))

                groups
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, topMargin, for: .scrollContent)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { screenHeight = $0 }
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
        .task {
            await model.requestPermissions()
        }
        // While the golem rests, used time flows back by the second: re-read
        // it so the rows and his mood keep up.
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

    // MARK: Parts

    /// One row per group, with thin lines only between them. The row draws
    /// its own arrow (next to the limit), so the list's built-in one is
    /// hidden by putting the link behind the row.
    private var groups: some View {
        @Bindable var model = model
        let firstID = model.settings.groups.first?.id
        let lastID = model.settings.groups.last?.id

        return ForEach($model.settings.groups) { $group in
            GroupRow(
                group: group,
                usedSeconds: model.usedSeconds(of: group),
                isOverLimit: model.isOverLimit(group)
            )
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { rowHeights[group.id] = $0 }
            .background {
                NavigationLink {
                    GroupEditView(group: $group)
                } label: {
                    EmptyView()
                }
                .opacity(0)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24))
            .listRowSeparatorTint(Theme.ink.opacity(0.25))
            .listRowSeparator(group.id == firstID ? .hidden : .automatic, edges: .top)
            .listRowSeparator(group.id == lastID ? .hidden : .automatic, edges: .bottom)
        }
        .onDelete { offsets in
            let ids = offsets.map { model.settings.groups[$0].id }
            ids.forEach(model.deleteGroup(id:))
        }
    }

    /// When everything fits, half the free room goes above it, so it sits
    /// in the middle instead of leaving the bottom empty. A little less
    /// than half: optical centre sits slightly above the real one.
    private var topMargin: CGFloat {
        let content = moodHeight + 16 + model.settings.groups.reduce(0) { $0 + (rowHeights[$1.id] ?? 0) }
        return max(0, (screenHeight - content) / 2 - 40)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(GolemVoice.newGroupButton, systemImage: "plus") { model.addGroup() }
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
