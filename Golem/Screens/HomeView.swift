import GolemKit
import SwiftUI

/// The main screen: the golem and how he feels, your groups, and, while a
/// group is over its limit, the way to talk to him. Everything else
/// (automations, blocking) is behind the gear in `SettingsView`.
struct HomeView: View {
    @Environment(GolemModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    @State private var talkingGroup: WatchGroup?
    @State private var isShowingSettings = false
    @State private var isShowingDebug = false
    /// The debug menu asks for a talk; shown once that sheet is gone.
    @State private var talkAfterDebug: WatchGroup?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    GolemMood(isAngry: model.isGolemAwake)
                        .padding(.bottom, 8)

                    ForEach(model.groupsOverLimit) { group in
                        TalkCard(group: group, overBy: overByText(group)) { talkingGroup = group }
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
            .fullScreenCover(item: $talkingGroup) { group in
                TalkView(group: group, overBy: overByText(group))
            }
            #if DEBUG
            .sheet(isPresented: $isShowingDebug, onDismiss: {
                talkingGroup = talkAfterDebug
                talkAfterDebug = nil
            }) {
                DebugMenu { group in
                    talkAfterDebug = group
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
        // While the golem rests, used time flows back by the second: re-read
        // it so the cards, the talk cards and his mood keep up.
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                model.refresh()
            }
        }
        .onChange(of: scenePhase, initial: true) {
            guard scenePhase == .active else { return }
            Task {
                await model.appBecameActive()
                offerTalk()
            }
        }
        // A tapped timer, notification or shield names its group.
        .onChange(of: model.talkRequest) { offerTalk() }
    }

    /// After a tap on the timer, a notification or the shield: open the
    /// conversation for that group. Nothing opens by itself otherwise.
    private func offerTalk() {
        if let group = model.takeGroupToTalk() {
            talkingGroup = group
        }
    }

    /// "1:24" while the group is over its limit, nil within it.
    private func overByText(_ group: WatchGroup) -> String? {
        let overBy = model.overBySeconds(of: group)
        return overBy >= 1 ? TalkView.minutesSeconds(overBy) : nil
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
                        isResting: model.isResting(group),
                        isOverLimit: model.isOverLimit(group)
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

/// The golem and one line on how he feels: asleep, unless a Screen Time
/// shield keeps him up (`GolemModel.isGolemAwake`).
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

/// A group past its limit: the way to talk to the golem while its time
/// flows back. Calm, not red, because he's asleep while you're here.
private struct TalkCard: View {
    let group: WatchGroup
    let overBy: String?
    let talk: () -> Void

    var body: some View {
        Button(action: talk) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(GolemVoice.talkCardTitle)
                        .font(.headline)
                    if let overBy {
                        Text(GolemVoice.talkCardSubtitle(groupName: group.name, overBy: overBy))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(Theme.ink)
            .golemCard()
        }
        .buttonStyle(.plain)
    }
}

/// One group: its name, how much of its limit is used, and a bar.
/// While the golem rests, both shrink, a second per second.
private struct GroupCard: View {
    let group: WatchGroup
    let usedSeconds: TimeInterval
    let isResting: Bool
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
            if isResting, usedSeconds >= 1 {
                Text(GolemVoice.groupResting)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .golemCard()
        .contentShape(Rectangle())
    }

    private var usage: String {
        guard usedSeconds >= 1 else { return GolemVoice.groupRested }
        return GolemVoice.groupUsage(used: Self.minutesSeconds(usedSeconds), limitMinutes: group.limitMinutes)
    }

    private static func minutesSeconds(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds.rounded()).formatted(.time(pattern: .minuteSecond))
    }
}

#Preview {
    HomeView()
        .environment(GolemModel())
}
