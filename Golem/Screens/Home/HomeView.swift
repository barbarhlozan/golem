import GolemKit
import SwiftUI

/// The main screen: the golem big, how he feels and why, then a ledger of
/// your groups. Everything else (automations, blocking, the debug menu) is
/// behind the gear in `SettingsView`.
///
/// It's always dark (`Theme.night`): the white golem reads best on the
/// ink of his own outline.
struct HomeView: View {
    @Environment(GolemModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    @State private var isShowingSettings = false
    @State private var isShowingSetupGuide = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    GolemMood(isShowingSetupGuide: $isShowingSetupGuide)
                    ledger
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(Theme.night)
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

    /// Groups as ruled rows on the dark page, not cards, so the golem
    /// stays the one thing that stands out.
    private var ledger: some View {
        @Bindable var model = model

        return VStack(spacing: 0) {
            ForEach($model.settings.groups) { $group in
                NavigationLink {
                    GroupEditView(group: $group)
                } label: {
                    GroupRow(
                        group: group,
                        usedSeconds: model.usedSeconds(of: group),
                        isOverLimit: model.isOverLimit(group)
                    )
                }
                .buttonStyle(.plain)
                Divider().overlay(Theme.ink.opacity(0.25))
            }

            Button {
                model.addGroup()
            } label: {
                Label(GolemVoice.newGroupButton, systemImage: "plus")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .overlay(alignment: .top) {
            Divider().overlay(Theme.ink.opacity(0.25))
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Settings", systemImage: "gearshape") { isShowingSettings = true }
        }
    }
}

#Preview {
    HomeView()
        .environment(GolemModel())
}
