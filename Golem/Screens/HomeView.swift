import GolemKit
import SwiftUI

/// The main screen: the golem and how he feels, your groups, and the way
/// into a plea. Everything else (breaks, plea rules, automations, blocking)
/// is behind the gear in `SettingsView`.
struct HomeView: View {
    @Environment(GolemModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    @State private var pleadingGroup: WatchGroup?
    @State private var isShowingSettings = false
    @State private var isShowingDebug = false
    /// The debug menu asks for a plea; shown once that sheet is gone.
    @State private var pleaAfterDebug: WatchGroup?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    GolemMood(isAngry: !model.groupsNeedingPlea.isEmpty)
                        .padding(.bottom, 8)

                    ForEach(model.groupsNeedingPlea) { group in
                        PleaCard(group: group) { pleadingGroup = group }
                    }

                    groups
                }
                .padding()
            }
            .background(Theme.paper)
            .navigationTitle("Golem")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .navigationDestination(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .fullScreenCover(item: $pleadingGroup) { group in
                PleaView(group: group)
            }
            #if DEBUG
            .sheet(isPresented: $isShowingDebug, onDismiss: {
                pleadingGroup = pleaAfterDebug
                pleaAfterDebug = nil
            }) {
                DebugMenu { group in
                    pleaAfterDebug = group
                    isShowingDebug = false
                }
            }
            #endif
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
        .onChange(of: scenePhase, initial: true) {
            guard scenePhase == .active else { return }
            Task {
                await model.appBecameActive()
                offerPlea()
            }
        }
        // A tapped notification or timer names its group.
        .onChange(of: model.pleaRequest) {
            guard let request = model.pleaRequest else { return }
            offerPlea(replacing: request.groupID != nil)
        }
    }

    /// Whenever Golem comes to the front with a group's time up (from a
    /// notification, the timer, or just opening it): go straight to the
    /// plea, for the group that was tapped if one was.
    /// `replacing`: a tap named a group, which wins over the one Golem
    /// picked itself a moment earlier when it came to the front.
    private func offerPlea(replacing: Bool = false) {
        guard pleadingGroup == nil || replacing else { return }
        if let group = model.takeGroupToPlead() {
            pleadingGroup = group
        }
    }

    // MARK: Parts

    private var groups: some View {
        @Bindable var model = model

        return VStack(spacing: 12) {
            ForEach($model.settings.groups) { $group in
                NavigationLink {
                    GroupEditView(group: $group)
                } label: {
                    GroupCard(
                        group: group,
                        usedSeconds: model.usedSeconds(of: group),
                        isOverLimit: model.needsPlea(group)
                    )
                }
                .buttonStyle(.plain)
            }

            Button {
                model.addGroup()
            } label: {
                Label("New group", systemImage: "plus")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .golemCard()
            }
            .buttonStyle(.plain)
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        #if DEBUG
        ToolbarItem(placement: .topBarLeading) {
            Button("Debug", systemImage: "ladybug") { isShowingDebug = true }
        }
        #endif
        ToolbarItem(placement: .topBarTrailing) {
            Button("Settings", systemImage: "gearshape") { isShowingSettings = true }
        }
    }
}

/// The golem and one line on how he feels: asleep while every group is
/// within its limit, angry once one is over.
private struct GolemMood: View {
    let isAngry: Bool

    var body: some View {
        VStack(spacing: 12) {
            GolemFigure(height: 200, isAsleep: !isAngry)
            Text(isAngry ? GolemVoice.homeAngry : GolemVoice.homeAsleep)
                .golemLine()
                .multilineTextAlignment(.center)
                .foregroundStyle(isAngry ? .red : Theme.ink)
        }
    }
}

/// "Reels: he wants to sleep — Plead with the Golem", in red.
private struct PleaCard: View {
    let group: WatchGroup
    let plead: () -> Void

    var body: some View {
        Button(action: plead) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(GolemVoice.overLimitTitle(groupName: group.name))
                        .font(.headline)
                    Text(GolemVoice.pleadButton)
                        .font(.subheadline)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(.red)
            .padding(16)
            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// One group: its name, how much of its limit is used, and a bar.
private struct GroupCard: View {
    let group: WatchGroup
    let usedSeconds: TimeInterval
    let isOverLimit: Bool

    private var limitSeconds: TimeInterval { TimeInterval(group.limitMinutes * 60) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(group.name)
                    .font(.headline)
                Spacer()
                Text(usage)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(isOverLimit ? .red : .secondary)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            ProgressView(value: min(usedSeconds / limitSeconds, 1))
                .tint(isOverLimit ? .red : Theme.ink)
        }
        .golemCard()
        .contentShape(Rectangle())
    }

    private var usage: String {
        guard usedSeconds >= 1 else { return GolemVoice.groupRested }
        let used = Duration.seconds(usedSeconds).formatted(.time(pattern: .minuteSecond))
        return GolemVoice.groupUsage(used: used, limitMinutes: group.limitMinutes)
    }
}

#Preview {
    HomeView()
        .environment(GolemModel())
}
