import GolemKit
import SwiftUI

/// The first run: who the golem is, your groups, notifications, and the
/// automations. Shown once; `GolemApp` swaps it for the home screen when
/// `hasOnboarded` turns true (the debug menu can turn it back off).
struct OnboardingView: View {
    @Environment(GolemModel.self) private var model
    @AppStorage(OnboardingView.doneKey) private var hasOnboarded = false

    static let doneKey = "hasOnboarded"

    private enum Page: Int, CaseIterable {
        case intro, groups, notifications, automations
    }

    @State private var page = Page.intro

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
        case .intro:
            header(GolemVoice.introTitle, GolemVoice.introBody, golemHeight: 220)
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
            case .intro, .groups:
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
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                Button(GolemVoice.finishButton) { hasOnboarded = true }
            }
        }
    }

    private func primary(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
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
