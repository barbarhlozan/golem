import Testing
@testable import GolemKit

/// Ticks the reel `count` times toward `target`, returning each frame shown.
private func play(_ reel: inout GolemReel, _ count: Int, toward target: GolemReel.Loop) -> [GolemReel.Frame] {
    (0..<count).map { _ in
        reel.tick(toward: target)
        return reel.frame
    }
}

struct GolemReelTests {
    @Test func loopsInPlace() {
        var reel = GolemReel(.asleep)

        let frames = play(&reel, 6, toward: .asleep)

        #expect(frames == [1, 2, 3, 4, 0, 1].map { .loop(.asleep, $0) })
    }

    @Test func fallsAsleepThroughTheSharedFrame() {
        // Settling starts at its hinge (frame 1): it plays a whole loop
        // back to it, then goes straight to asleep's hinge.
        var reel = GolemReel(.settling)

        let frames = play(&reel, 6, toward: .asleep)

        #expect(frames == [2, 3, 4, 0, 1].map { .loop(.settling, $0) } + [.loop(.asleep, 0)])
        #expect(reel.loop == .asleep)
    }

    @Test func quietsByClosingHisEyes() {
        var reel = GolemReel(.restless)

        let frames = play(&reel, 8, toward: .settling)

        #expect(frames == [1, 2, 3, 4, 0].map { .loop(.restless, $0) }
            + [.wake(4), .wake(3), .loop(.settling, 1)])
    }

    @Test func opensHisEyesWhenRestless() {
        var reel = GolemReel(.asleep)

        let frames = play(&reel, 9, toward: .restless)

        #expect(frames == [1, 2, 3, 4, 0].map { .loop(.asleep, $0) }
            + [.loop(.settling, 1), .wake(3), .wake(4), .loop(.restless, 0)])
    }

    @Test func wokenFromAnAppHeLiesBackDown() {
        var reel = GolemReel(.asleep)
        reel.wake()

        let frames = play(&reel, 9, toward: .asleep)

        #expect(frames == [1, 2, 3, 4, 0].map { .loop(.restless, $0) }
            + [.wake(4), .wake(3), .loop(.settling, 1), .loop(.asleep, 0)])
    }
}
