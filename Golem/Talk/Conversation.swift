import Foundation
import GolemKit
import Observation

/// One conversation with the golem: what's been said, and whether he's
/// still thinking. Lives only as long as the talk screen is open.
@MainActor
@Observable
final class Conversation {
    struct Line: Identifiable, Equatable {
        let id = UUID()
        let isGolem: Bool
        let text: String
    }

    private(set) var lines: [Line]
    private(set) var isThinking = false

    private let brain: any GolemBrain

    /// `opening`: his first words. `instructions`: who he is, for the model.
    init(opening: String, instructions: String) {
        lines = [Line(isGolem: true, text: opening)]
        brain = GolemBrains.best(instructions: instructions)
    }

    func send(_ text: String) async {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking else { return }

        lines.append(Line(isGolem: false, text: text))
        isThinking = true
        let reply = await brain.reply(to: text)
        isThinking = false
        lines.append(Line(isGolem: true, text: reply))
    }
}
