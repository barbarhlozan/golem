import GolemKit
import SwiftUI

/// The main screen: groups, settings, and the way into a plea.
struct HomeView: View {
    @Environment(GolemModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    @State private var pleadingGroup: WatchGroup?

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Form {
                if !model.groupsNeedingPlea.isEmpty {
                    overLimitSection
                }
                if Capabilities.screenTime && !model.isAuthorized {
                    authorizationSection
                }
                groupsSection
                SettingsSection(settings: $model.settings)
                setupSection
                if Capabilities.screenTime && model.isAuthorized {
                    watchingSection
                }
                #if DEBUG
                DebugSection()
                #endif
            }
            .navigationTitle("Golem")
            .sheet(item: $pleadingGroup) { group in
                PleaView(group: group)
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
        .task {
            await model.requestPermissions()
        }
        .onChange(of: scenePhase) {
            guard scenePhase == .active else { return }
            model.refresh()
            // Arriving from a "time's up" notification or the timer:
            // go straight to the plea.
            if pleadingGroup == nil {
                pleadingGroup = model.groupsNeedingPlea.first
            }
        }
    }

    // MARK: Sections

    private var overLimitSection: some View {
        Section(GolemVoice.shieldTitle) {
            ForEach(model.groupsNeedingPlea) { group in
                Button {
                    pleadingGroup = group
                } label: {
                    LabeledContent(GolemVoice.overLimitTitle(groupName: group.name)) {
                        Text(GolemVoice.pleadButton)
                    }
                }
            }
        }
    }

    private var authorizationSection: some View {
        Section {
            Text("Golem needs Screen Time access to block apps when your time is up.")
            Button("Allow Screen Time access") {
                Task { await model.requestPermissions() }
            }
        }
    }

    private var groupsSection: some View {
        @Bindable var model = model

        return Section {
            ForEach($model.settings.groups) { $group in
                NavigationLink {
                    GroupEditView(group: $group)
                } label: {
                    LabeledContent(group.name, value: "\(group.limitMinutes) min")
                }
            }
            .onDelete { model.deleteGroups(at: $0) }

            Button("Add group") { model.addGroup() }
        } header: {
            Text("Groups")
        } footer: {
            Text("Apps in the same group share one timer. Each group has its own limit.")
        }
    }

    private var setupSection: some View {
        Section {
            NavigationLink("Set up the Shortcuts automations") {
                SetupGuideView()
            }
        } footer: {
            Text("The automations tell Golem when you open and close your apps, which starts the timer in the Dynamic Island.")
        }
    }

    private var watchingSection: some View {
        Section {
            if model.settings.isWatching {
                Button("Stop blocking", role: .destructive) { model.stopWatching() }
            } else {
                Button("Start blocking") { model.startWatching() }
            }
        } footer: {
            Text("Covers a group's apps with the Golem's shield when its time is up. Changes apply the next time you start.")
        }
    }
}

#Preview {
    HomeView()
        .environment(GolemModel())
}
