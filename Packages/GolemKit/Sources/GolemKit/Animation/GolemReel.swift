/// Which of the owner's hand-drawn frames the home screen's golem shows,
/// one tick at a time.
///
/// Each resting state has a short loop (eyes closed, half-open, wide open).
/// Moving between them goes along a "ladder" of eye drawings, the wake-up
/// frames, so his eyes open and close instead of cutting. A loop only lets
/// go at its hinge frame, the one it shares with the ladder, so nothing
/// jumps. Kept free of SwiftUI so the sequencing can be tested.
public struct GolemReel: Sendable, Equatable {
    public enum Loop: Sendable, CaseIterable {
        case asleep, settling, restless

        /// Every loop is five drawings.
        static let frameCount = 5

        /// The frame this loop shares with the ladder.
        var hinge: Int {
            switch self {
            case .asleep: 0     // asleep-1 is wake-1
            case .settling: 1   // settling-2 is wake-2
            case .restless: 0   // stands in for wake-5
            }
        }

        /// Its step on the ladder, from eyes closed (0) to wide open (4).
        var rung: Int {
            switch self {
            case .asleep: 0
            case .settling: 1
            case .restless: 4
            }
        }
    }

    public enum Frame: Hashable, Sendable {
        /// Index from 0 in the loop's drawings.
        case loop(Loop, Int)
        /// A wake-up drawing that belongs to no loop, numbered as drawn (3, 4).
        case wake(Int)
    }

    /// The loop he's in, or heading for while `between` isn't empty.
    public private(set) var loop: Loop
    public private(set) var frame: Frame
    private var index: Int
    /// The ladder frames still to play, ending with the next loop's hinge.
    private var between: [Frame] = []

    /// Starts at the loop's hinge, with no transition.
    public init(_ loop: Loop) {
        self.loop = loop
        index = loop.hinge
        frame = .loop(loop, index)
    }

    /// Shows the next frame, heading for `target`: the current loop runs on
    /// until its hinge, then the ladder carries him over.
    public mutating func tick(toward target: Loop) {
        if !between.isEmpty {
            frame = between.removeFirst()
            if between.isEmpty { index = loop.hinge }
            return
        }
        index = (index + 1) % Loop.frameCount
        frame = .loop(loop, index)
        if index == loop.hinge, target != loop {
            between = Self.ladder(from: loop.rung, to: target.rung) + [.loop(target, target.hinge)]
            loop = target
        }
    }

    /// He's just been woken (you came straight from a watched app): show
    /// him wide awake, for one loop before he settles back down.
    public mutating func wake() {
        loop = .restless
        index = Loop.restless.hinge
        between = []
        frame = .loop(.restless, index)
    }

    /// The drawings strictly between two rungs, in order.
    private static func ladder(from start: Int, to end: Int) -> [Frame] {
        let steps = start < end ? Array(start + 1 ..< end) : Array((end + 1 ..< start).reversed())
        return steps.map(rungFrame)
    }

    private static func rungFrame(_ rung: Int) -> Frame {
        switch rung {
        case 0: .loop(.asleep, Loop.asleep.hinge)
        case 1: .loop(.settling, Loop.settling.hinge)
        case 4: .loop(.restless, Loop.restless.hinge)
        default: .wake(rung + 1)
        }
    }
}
