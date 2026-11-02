import FoundationModels
import GolemKit
import OSLog

/// Who answers when you talk to the golem.
///
/// With Apple's on-device model (iOS 26+, Apple Intelligence on) he really
/// replies; nothing leaves the phone. Without it he answers with his
/// hand-written lines from `GolemVoice.talkFallbackReplies`.
@MainActor
protocol GolemBrain {
    func reply(to text: String) async -> String
}

enum GolemBrains {
    /// The best brain this phone has, told who the golem is (`instructions`).
    @MainActor
    static func best(instructions: String) -> any GolemBrain {
        if #available(iOS 26.0, *) {
            let availability = SystemLanguageModel.default.availability
            guard availability == .available else {
                logger.notice("Golem talks with his own lines: on-device model \(String(describing: availability))")
                return ScriptedGolem()
            }
            logger.notice("Golem talks with the on-device model")
            return OnDeviceGolem(instructions: instructions)
        }
        logger.notice("Golem talks with his own lines: iOS older than 26")
        return ScriptedGolem()
    }

    private static let logger = Logger(subsystem: "cz.hlozanek.golem", category: "Talk")
}

/// His hand-written replies, in turn.
@MainActor
final class ScriptedGolem: GolemBrain {
    private var next = 0

    func reply(to text: String) async -> String {
        let replies = GolemVoice.talkFallbackReplies
        defer { next = (next + 1) % replies.count }
        return replies[next]
    }
}

/// Apple's on-device model, playing the golem. If it fails mid-conversation
/// (e.g. the model is busy), he falls back to his hand-written lines.
@available(iOS 26.0, *)
@MainActor
final class OnDeviceGolem: GolemBrain {
    private let session: LanguageModelSession
    private let fallback = ScriptedGolem()

    init(instructions: String) {
        session = LanguageModelSession(instructions: instructions)
    }

    func reply(to text: String) async -> String {
        do {
            let response = try await session.respond(to: text)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            Logger(subsystem: "cz.hlozanek.golem", category: "Talk")
                .error("On-device model failed, using his own lines: \(error.localizedDescription)")
            return await fallback.reply(to: text)
        }
    }
}
