import FamilyControls
import GolemKit
import SwiftUI

/// The main (and for now only) screen: setup, status and the way into a plea.
struct HomeView: View {
    @Environment(GolemModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    @State private var isPickingApps = false
    @State private var isPleading = false

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Form {
                if !model.isAuthorized {
                    authorizationSection
                } else {
                    if model.isShieldUp {
                        shieldSection
                    }
                    appsSection
                    SettingsSection(settings: $model.settings)
                    watchingSection
                    if GolemModel.isPreviewMode {
                        previewSection
                    }
                }
            }
            .navigationTitle("Golem")
            .familyActivityPicker(isPresented: $isPickingApps, selection: $model.watchedApps)
            .sheet(isPresented: $isPleading) {
                PleaView()
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
        .onChange(of: scenePhase) {
            if scenePhase == .active { model.refresh() }
        }
    }

    // MARK: Sections

    private var authorizationSection: some View {
        Section {
            Text("Golem needs Screen Time access to notice when you start doomscrolling.")
            Button("Allow Screen Time access") {
                Task { await model.requestAuthorization() }
            }
        }
    }

    private var shieldSection: some View {
        Section {
            Label(GolemVoice.shieldTitle, systemImage: "eye.fill")
                .font(.headline)
            Button(GolemVoice.pleadButton) { isPleading = true }
        }
    }

    private var appsSection: some View {
        Section("Watched apps") {
            Button(model.watchedApps.isEmpty ? "Choose apps…" : "Change apps…") {
                isPickingApps = true
            }
            if !model.watchedApps.isEmpty {
                WatchedAppsSummary(selection: model.watchedApps)
            }
        }
    }

    private var watchingSection: some View {
        Section {
            if model.settings.isWatching {
                Button("Stop watching", role: .destructive) { model.stopWatching() }
            } else {
                Button("Start watching") { model.startWatching() }
                    .disabled(model.watchedApps.isEmpty && !GolemModel.isPreviewMode)
            }
        } footer: {
            if model.settings.isWatching {
                Text("Changes to the limit apply the next time you start watching.")
            }
        }
    }

    private var previewSection: some View {
        Section {
            Button("Simulate limit reached") { model.simulateLimitReached() }
                .disabled(!model.settings.isWatching || model.isShieldUp)
        } header: {
            Text("Preview mode")
        } footer: {
            Text("The simulator has no Screen Time, so app picking, monitoring and the real shield only work on an iPhone. Use this to try the plea flow.")
        }
    }
}

/// Shows the icons of the picked apps. iOS only lets us draw them via `Label(token)`.
private struct WatchedAppsSummary: View {
    let selection: FamilyActivitySelection

    var body: some View {
        ForEach(Array(selection.applicationTokens), id: \.self) { token in
            Label(token)
        }
        ForEach(Array(selection.categoryTokens), id: \.self) { token in
            Label(token)
        }
        ForEach(Array(selection.webDomainTokens), id: \.self) { token in
            Label(token)
        }
    }
}

#Preview {
    HomeView()
        .environment(GolemModel())
}
