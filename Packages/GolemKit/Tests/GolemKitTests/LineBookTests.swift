import Foundation
import Testing
@testable import GolemKit

struct LineBookTests {
    private func lines(_ prefix: String, _ count: Int) -> [String] {
        (1...count).map { "\(prefix)\($0)" }
    }

    @Test func nothingWrittenMeansNoLine() {
        var book = LineBook()
        #expect(book.take(.angry) == nil)
        #expect(book.momentsNeedingLines == GolemMoment.allCases)
    }

    @Test func takesLinesInOrder() {
        var book = LineBook()
        book.add(lines("a", 5), for: .angry)

        #expect(book.take(.angry) == "a1")
        #expect(book.take(.angry) == "a2")
        #expect(book.take(.waking) == nil)
    }

    @Test func aSecondBatchWaitsAsTheSpare() {
        var book = LineBook()
        book.add(lines("a", 5), for: .angry)
        book.add(lines("b", 5), for: .angry)

        #expect(!book.momentsNeedingLines.contains(.angry))
        #expect(book.take(.angry) == "a1")
    }

    @Test func switchesToTheSpareAt80Percent() {
        var book = LineBook()
        book.add(lines("a", 5), for: .angry)
        book.add(lines("b", 5), for: .angry)

        for expected in ["a1", "a2", "a3", "a4"] {
            #expect(book.take(.angry) == expected)
        }
        // 4 of 5 used: the spare took over and a new spare is wanted.
        #expect(book.momentsNeedingLines.contains(.angry))
        #expect(book.take(.angry) == "b1")
    }

    @Test func withoutASpareItFinishesTheBatchThenRunsDry() {
        var book = LineBook()
        book.add(lines("a", 2), for: .waking)

        #expect(book.take(.waking) == "a1")
        #expect(book.take(.waking) == "a2")
        #expect(book.take(.waking) == nil)

        // Fresh lines go straight into use once the batch is empty.
        book.add(lines("b", 2), for: .waking)
        #expect(book.take(.waking) == "b1")
    }

    @Test func fallsBackToHandWrittenLines() {
        let store = SharedStore(suiteName: "GolemKitTests.\(UUID().uuidString)")
        let line = GolemLines.next(.stirring, store: store)
        #expect(GolemVoice.fallbackLines(.stirring).contains(line))
    }

    @Test func storedLinesAreUsedAndUsedUp() {
        let store = SharedStore(suiteName: "GolemKitTests.\(UUID().uuidString)")
        var book = LineBook()
        book.add(["Only line"], for: .waking)
        store.lineBook = book

        #expect(GolemLines.next(.waking, store: store) == "Only line")
        #expect(GolemVoice.fallbackLines(.waking).contains(GolemLines.next(.waking, store: store)))
    }
}

struct LineBookVoiceTests {
    @Test func linesInAnOlderVoiceAreThrownAway() throws {
        let suite = "GolemKitTests.\(UUID().uuidString)"
        let store = SharedStore(suiteName: suite)
        var book = LineBook()
        book.add(["I'm up."], for: .waking)
        // Pretend it was saved in voice 1, before the voice changed.
        var json = String(decoding: try JSONEncoder().encode(book), as: UTF8.self)
        json = json.replacingOccurrences(of: "\"voice\":\(LineBook.currentVoice)", with: "\"voice\":1")
        UserDefaults(suiteName: suite)!.set(Data(json.utf8), forKey: "lineBook")

        #expect(store.lineBook == LineBook())
        #expect(GolemVoice.fallbackLines(.waking).contains(GolemLines.next(.waking, store: store)))
    }

    @Test func linesInTheCurrentVoiceAreKept() {
        let store = SharedStore(suiteName: "GolemKitTests.\(UUID().uuidString)")
        var book = LineBook()
        book.add(["The golem woke up."], for: .waking)
        store.lineBook = book

        #expect(GolemLines.next(.waking, store: store) == "The golem woke up.")
    }
}
