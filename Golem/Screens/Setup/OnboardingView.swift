import GolemKit
import SwiftUI

/// The first run: six story pages on how the golem works, then your groups,
/// notifications, and the automations. Shown once; `GolemApp` swaps it for the home screen when
/// `hasOnboarded` turns true (the debug menu can turn it back off).
struct OnboardingView: View {
    @Environment(GolemModel.self) private var model
    @AppStorage(OnboardingView.doneKey) private var hasOnboarded = false

    static let doneKey = "hasOnboarded"

    private enum Page: Int, CaseIterable {
        // The story, one idea per page (texts in `GolemVoice.storyPages`).
        case meet, oneSession, backToSleep, breakReset, angry, stages
        // Setting things up.
        case groups, notifications, automations
    }

    @State private var page = Page.meet

    var body: some View {
        VStack(spacing: 0) {
            Text("\(page.rawValue + 1) of \(Page.allCases.count)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top)

            ScrollView {
                content
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)

            buttons
                .padding(24)
        }
        .background(Theme.paper)
        .animation(.easeInOut, value: page)
    }

    // MARK: Pages

    @ViewBuilder
    private var content: some View {
        switch page {
        case .meet, .oneSession, .backToSleep, .breakReset, .angry, .stages:
            storyPage(page.rawValue)
        case .groups:
            VStack(spacing: 24) {
                header(GolemVoice.groupsTitle, GolemVoice.groupsBody, golemHeight: 120)
                GroupLimitsCard()
            }
        case .notifications:
            header(GolemVoice.notificationsTitle, GolemVoice.notificationsBody, golemHeight: 180)
        case .automations:
            VStack(spacing: 24) {
                header(GolemVoice.automationsTitle, GolemVoice.automationsBody, golemHeight: 120)
                VStack(alignment: .leading, spacing: 14) {
                    AutomationSteps()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .golemCard()
            }
        }
    }

    /// One story page: its own drawing, a title and a line of text.
    private func storyPage(_ index: Int) -> some View {
        let story = GolemVoice.storyPages()[index]
        return VStack(spacing: 16) {
            StoryDrawing(number: index + 1)
            Text(story.title)
                .golemLine()
                .multilineTextAlignment(.center)
            Text(story.body)
                .multilineTextAlignment(.center)
        }
    }

    private func header(_ title: String, _ body: String, golemHeight: CGFloat) -> some View {
        VStack(spacing: 16) {
            GolemFigure(height: golemHeight)
            Text(title)
                .golemLine()
            Text(body)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: Buttons

    @ViewBuilder
    private var buttons: some View {
        VStack(spacing: 12) {
            switch page {
            case .meet, .oneSession, .backToSleep, .breakReset, .angry, .stages, .groups:
                primary(GolemVoice.continueButton) { advance(from: page) }
            case .notifications:
                primary(GolemVoice.allowNotificationsButton) {
                    Task {
                        await model.requestPermissions()
                        advance(from: .notifications)
                    }
                }
            case .automations:
                OpenShortcutsButton()
                    .buttonStyle(.golemPrimary)
                Button(GolemVoice.finishButton) { hasOnboarded = true }
            }
        }
    }

    private func primary(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.golemPrimary)
    }

    /// Only moves on if we're still on `current`, so a double tap (or two
    /// permission requests finishing) can't skip a page.
    private func advance(from current: Page) {
        guard page == current else { return }
        if let following = Page(rawValue: page.rawValue + 1) {
            page = following
        } else {
            hasOnboarded = true
        }
    }
}

/// The drawing for story page `number` ("Onboarding1"…"Onboarding6" in the
/// asset catalog). Until the owner's drawing is there, the golem stands in.
private struct StoryDrawing: View {
    let number: Int

    private var name: String { "Onboarding\(number)" }

    var body: some View {
        if UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(height: 220)
                .accessibilityHidden(true)
        } else {
            GolemFigure(height: 220)
        }
    }
}

/// Name and limit of each group, editable in place.
private struct GroupLimitsCard: View {
    @Environment(GolemModel.self) private var model

    var body: some View {
        @Bindable var model = model

        VStack(spacing: 0) {
            ForEach($model.settings.groups) { $group in
                HStack {
                    TextField("Name", text: $group.name)
                        .font(.headline)
                    Stepper(
                        "\(group.limitMinutes) min",
                        value: $group.limitMinutes,
                        in: WatchGroup.allowedLimitMinutes
                    )
                    .fixedSize()
                }
                .padding(.vertical, 10)
                if group.id != model.settings.groups.last?.id {
                    Divider()
                }
            }
        }
        .golemCard()
    }
}

#Preview {
    OnboardingView()
        .environment(GolemModel())
        .golemStyle()
}
