import Combine
import GolemKit
import SwiftUI

/// Where you explain yourself to the golem to get more time. It's a black,
/// full-screen face-to-face with him rather than a form: he looms out of the
/// dark and asks why he must stay awake.
///
/// The rules live in `PleaRules`: his reading time only starts with your
/// first letter, so you can't sit it out. This screen only shows his
/// question, a text box, and his replies.
struct PleaView: View {
    /// The group whose time is up.
    let group: WatchGroup

    @Environment(GolemModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var reason = ""
    @State private var startedWritingAt: Date?
    @State private var now = Date.now
    @State private var isRevealed = false
    @State private var isTextShown = false

    private let ticker = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    private var rules: PleaRules { model.settings.pleaRules }

    private var secondsWriting: Int {
        guard let startedWritingAt else { return 0 }
        return Int(now.timeIntervalSince(startedWritingAt))
    }

    private var obstacles: [PleaRules.Obstacle] {
        rules.obstacles(secondsWriting: secondsWriting, reason: reason)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            PleaGolemIntro(isRevealed: isRevealed)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                giveUpButton
                Spacer()
                writingArea
            }
        }
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .onAppear(perform: reveal)
        .onReceive(ticker) { now = $0 }
        .onChange(of: reason) {
            if startedWritingAt == nil, !reason.isEmpty {
                startedWritingAt = .now
            }
        }
    }

    private var giveUpButton: some View {
        HStack {
            Button(GolemVoice.giveUpButton) { dismiss() }
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var writingArea: some View {
        VStack(spacing: 14) {
            Text(GolemVoice.pleaQuestion)
                .golemLine()
                .multilineTextAlignment(.center)
                .rising(isTextShown)

            VStack(spacing: 14) {
                TextField(
                    "",
                    text: $reason,
                    prompt: Text(GolemVoice.pleaPlaceholder).foregroundStyle(.white.opacity(0.4)),
                    axis: .vertical
                )
                .lineLimit(3...6)
                .padding(12)
                .background(Color(white: 0.1), in: .rect(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.2)))

                Text(GolemVoice.pleaHint(
                    obstacles: obstacles,
                    hasStartedWriting: startedWritingAt != nil,
                    grantedMinutes: rules.grantedMinutes
                ))
                .font(.subheadline.italic())
                .foregroundStyle(.white.opacity(0.6))
                .contentTransition(.numericText())

                grantButton
            }
            .rising(isTextShown, extraDelay: 0.15)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background {
            // Solid black under the text, fading softly into the golem above it.
            Color.black
                .ignoresSafeArea()
                .overlay(alignment: .top) {
                    GeometryReader { proxy in
                        let height = proxy.size.width * PleaGolemIntro.Tuning.fadeHeight
                        PleaFade()
                            .frame(height: height)
                            .offset(y: -height)
                    }
                }
        }
    }

    private var grantButton: some View {
        let isReady = obstacles.isEmpty
        return Button {
            model.grantMoreTime(for: group)
            dismiss()
        } label: {
            Text(GolemVoice.grantButton(minutes: rules.grantedMinutes))
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(isReady ? .black : .white.opacity(0.4))
                .background(isReady ? .white : .white.opacity(0.12), in: .capsule)
        }
        .disabled(!isReady)
    }

    /// Plays the golem's entrance, then brings in the question and the box.
    private func reveal() {
        guard !reduceMotion else {
            isRevealed = true
            isTextShown = true
            return
        }
        isRevealed = true
        Task {
            try? await Task.sleep(for: .seconds(PleaGolemIntro.Tuning.textDelaySeconds))
            isTextShown = true
        }
    }
}

private extension View {
    /// Fades and slides the view up into place once `isShown` turns true.
    func rising(_ isShown: Bool, extraDelay: Double = 0) -> some View {
        opacity(isShown ? 1 : 0)
            .offset(y: isShown ? 0 : 14)
            .animation(
                .easeOut(duration: PleaGolemIntro.Tuning.textRiseSeconds).delay(extraDelay),
                value: isShown
            )
    }
}
