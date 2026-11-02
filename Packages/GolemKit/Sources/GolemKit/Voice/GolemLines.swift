import Foundation

/// The three moments the golem speaks up in the Dynamic Island.
public enum GolemMoment: String, Codable, CaseIterable, Sendable {
    /// You opened an app: he wakes up and starts watching.
    case waking
    /// You're at 80% of your limit: he stirs (orange).
    case stirring
    /// You're past your limit: he's angry (red), and keeps asking.
    case angry
}

extension GolemMoment {
    /// When the golem starts stirring, as a share of the limit.
    public static let stirringShare = 0.8

    /// The moment for this much used time: what the Island would show if
    /// you went back to the group's apps now. The home screen takes its
    /// colour from it, so it calms down as the time flows back.
    public init(usedSeconds: TimeInterval, limitSeconds: TimeInterval) {
        if usedSeconds >= limitSeconds {
            self = .angry
        } else if usedSeconds >= limitSeconds * Self.stirringShare {
            self = .stirring
        } else {
            self = .waking
        }
    }
}

/// The golem's lines for each moment, written ahead so a pop-up never has
/// to wait for them.
///
/// Each moment has two batches: lines are taken from the *current* one,
/// while the *spare* waits. Once 80% of the current batch is used, the
/// spare takes over and a fresh spare is wanted (`momentsNeedingLines`).
/// If a moment has nothing written yet, the hand-written fallback lines
/// fill in, so he's never silent.
public struct LineBook: Codable, Equatable, Sendable {
    struct Batches: Codable, Equatable, Sendable {
        var current: [String] = []
        var used = 0
        var spare: [String] = []
    }

    /// How much of the current batch is used before the spare takes over.
    static let switchAt = 0.8

    private var batches: [GolemMoment: Batches] = [:]

    public init() {}

    /// The next line for a moment, or nil if none has been written yet.
    public mutating func take(_ moment: GolemMoment) -> String? {
        var book = batches[moment] ?? Batches()
        guard book.used < book.current.count else { return nil }

        let line = book.current[book.used]
        book.used += 1

        let isMostlyUsed = Double(book.used) >= Double(book.current.count) * Self.switchAt
        if isMostlyUsed, !book.spare.isEmpty {
            book.current = book.spare
            book.used = 0
            book.spare = []
        }
        batches[moment] = book
        return line
    }

    /// Moments whose spare batch is missing (or that have nothing at all).
    public var momentsNeedingLines: [GolemMoment] {
        GolemMoment.allCases.filter { (batches[$0] ?? Batches()).spare.isEmpty }
    }

    /// Adds freshly written lines: as the current batch if there's nothing
    /// left to take, otherwise as the spare.
    public mutating func add(_ lines: [String], for moment: GolemMoment) {
        guard !lines.isEmpty else { return }
        var book = batches[moment] ?? Batches()
        if book.used >= book.current.count {
            book.current = lines
            book.used = 0
        } else {
            book.spare = lines
        }
        batches[moment] = book
    }
}

/// Where the timer gets the golem's lines: the stored `LineBook`, or the
/// hand-written ones when nothing's written yet.
public enum GolemLines {
    public static func next(_ moment: GolemMoment, store: SharedStore = SharedStore()) -> String {
        var book = store.lineBook
        defer { store.lineBook = book }
        return book.take(moment) ?? GolemVoice.fallbackLines(moment).randomElement()!
    }
}
