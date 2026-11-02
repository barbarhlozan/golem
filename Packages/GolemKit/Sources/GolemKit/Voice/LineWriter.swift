#if os(iOS) && canImport(FoundationModels)
import Foundation
import FoundationModels
import OSLog

/// Writes the golem's lines ahead with Apple's on-device model (iOS 26+,
/// Apple Intelligence on), into the `LineBook`.
///
/// It runs whenever Golem's code gets a chance: when Golem is open, and
/// after each app open or close from the automations. iOS may not let the
/// model run in the background; then it just tries again next time, and
/// the hand-written lines fill in meanwhile.
public enum LineWriter {
    /// How many lines one batch holds.
    static let batchSize = 20

    @MainActor private static var isWriting = false

    /// Writes a batch for every moment that needs one. Does nothing if
    /// there's no model, or if it's already writing.
    @MainActor
    public static func writeMissing(store: SharedStore = SharedStore()) async {
        guard #available(iOS 26.0, *) else { return }
        guard !isWriting else { return }
        let missing = store.lineBook.momentsNeedingLines
        guard !missing.isEmpty else { return }

        let availability = SystemLanguageModel.default.availability
        guard availability == .available else {
            logger.notice("No on-device model for lines: \(String(describing: availability))")
            return
        }

        isWriting = true
        defer { isWriting = false }

        for moment in missing {
            do {
                let lines = try await write(moment)
                var book = store.lineBook
                book.add(lines, for: moment)
                store.lineBook = book
                logger.info("Wrote \(lines.count) \(moment.rawValue) lines")
            } catch {
                logger.error("Couldn't write \(moment.rawValue) lines: \(error.localizedDescription)")
                return
            }
        }
    }

    @available(iOS 26.0, *)
    @MainActor
    private static func write(_ moment: GolemMoment) async throws -> [String] {
        let session = LanguageModelSession(instructions: GolemVoice.writerInstructions)
        let response = try await session.respond(
            to: GolemVoice.writerPrompt(moment, count: batchSize),
            generating: WrittenLines.self
        )
        return response.content.lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines.union(["\""])) }
            .filter { !$0.isEmpty && $0.count <= 60 }
    }

    private static let logger = Logger(subsystem: "cz.hlozanek.golem", category: "Lines")
}

/// The shape the model answers in, so the lines come back as a list.
@available(iOS 26.0, *)
@Generable
struct WrittenLines {
    @Guide(description: "Different short lines, each at most 8 words", .count(20))
    var lines: [String]
}
#endif
