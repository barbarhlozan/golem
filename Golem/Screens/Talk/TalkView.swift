import GolemKit
import SwiftUI

/// Talking to the golem while your time flows back. A black, full-screen
/// face-to-face: he looms out of the dark, says something, and answers
/// whatever you write (`Conversation`). Nothing has to be earned here;
/// "Sleep well" just lets him go back to sleep.
struct TalkView: View {
    /// The group you came from.
    let group: WatchGroup

    @Environment(GolemModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var conversation: Conversation
    @State private var draft = ""
    @State private var isRevealed = false
    @State private var isTextShown = false
    @FocusState private var isWriting: Bool

    init(group: WatchGroup, overBy: String?) {
        self.group = group
        _conversation = State(initialValue: Conversation(
            opening: GolemVoice.talkOpening(groupName: group.name, overBy: overBy),
            instructions: GolemVoice.talkInstructions(
                groupName: group.name,
                limitMinutes: group.limitMinutes,
                overBy: overBy
            )
        ))
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            GolemInTheDark(isRevealed: isRevealed)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 160)
                talkArea
            }
        }
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .onAppear(perform: reveal)
    }

    private var talkArea: some View {
        VStack(spacing: 12) {
            lines
                .rising(isTextShown)

            VStack(spacing: 12) {
                Text(status)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.5))
                    .contentTransition(.numericText())

                composer

                Button { dismiss() } label: {
                    Text(GolemVoice.talkSleepButton)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.black)
                        .background(.white, in: .capsule)
                }
            }
            .rising(isTextShown, extraDelay: 0.15)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background {
            // Solid black under the conversation, fading softly into the golem.
            Color.black
                .ignoresSafeArea()
                .overlay(alignment: .top) {
                    GeometryReader { proxy in
                        let height = proxy.size.width * GolemInTheDark.Tuning.fadeHeight
                        DarkFade()
                            .frame(height: height)
                            .offset(y: -height)
                    }
                }
        }
    }

    /// What's been said, newest at the bottom. His lines are in his
    /// blackletter voice; yours are plain.
    private var lines: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(conversation.lines) { line in
                        LineView(line: line)
                            .id(line.id)
                    }
                    if conversation.isThinking {
                        Text(GolemVoice.talkThinking)
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.6))
                            .id("thinking")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(.bottom)
            .frame(maxHeight: 280)
            .fixedSize(horizontal: false, vertical: true)
            .onChange(of: conversation.lines) {
                withAnimation { proxy.scrollTo(conversation.lines.last?.id, anchor: .bottom) }
            }
            .onChange(of: conversation.isThinking) {
                if conversation.isThinking {
                    withAnimation { proxy.scrollTo("thinking", anchor: .bottom) }
                }
            }
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(
                "",
                text: $draft,
                prompt: Text(GolemVoice.talkPlaceholder).foregroundStyle(.white.opacity(0.4)),
                axis: .vertical
            )
            .lineLimit(1...4)
            .focused($isWriting)
            .submitLabel(.send)
            .onSubmit(send)
            .padding(12)
            .background(Color(white: 0.1), in: .rect(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.2)))

            Button(GolemVoice.talkSendButton, systemImage: "arrow.up.circle.fill", action: send)
                .labelStyle(.iconOnly)
                .font(.title)
                .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || conversation.isThinking)
        }
    }

    /// How far over the limit you still are; it shrinks while you're here.
    private var status: String {
        let overBy = model.overBySeconds(of: group)
        guard overBy >= 1 else { return GolemVoice.talkBackUnderNow }
        return GolemVoice.talkBackUnder(in: Self.minutesSeconds(overBy))
    }

    private func send() {
        let text = draft
        draft = ""
        Task { await conversation.send(text) }
    }

    /// Plays the golem's entrance, then brings in the conversation.
    private func reveal() {
        guard !reduceMotion else {
            isRevealed = true
            isTextShown = true
            return
        }
        isRevealed = true
        Task {
            try? await Task.sleep(for: .seconds(GolemInTheDark.Tuning.textDelaySeconds))
            isTextShown = true
        }
    }

    static func minutesSeconds(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds.rounded()).formatted(.time(pattern: .minuteSecond))
    }
}

/// One line of the conversation.
private struct LineView: View {
    let line: Conversation.Line

    var body: some View {
        if line.isGolem {
            Text(line.text)
                .font(.custom(Theme.headingFontName, size: 22, relativeTo: .title3))
                .fontDesign(nil)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(line.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(white: 0.15), in: .rect(cornerRadius: 16))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

private extension View {
    /// Fades and slides the view up into place once `isShown` turns true.
    func rising(_ isShown: Bool, extraDelay: Double = 0) -> some View {
        opacity(isShown ? 1 : 0)
            .offset(y: isShown ? 0 : 14)
            .animation(
                .easeOut(duration: GolemInTheDark.Tuning.textRiseSeconds).delay(extraDelay),
                value: isShown
            )
    }
}
