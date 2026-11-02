import SwiftUI

/// Sparks rising around the golem, as if a fire smouldered under him: now
/// and then while he sleeps, more and more often as he gets angrier.
/// `LivingGolem` sets how many fly and how long they rest.
///
/// Each spark is one of the owner's hand-drawn embers (three variations):
/// five frames of a streak flying up through its own tile. The code never moves a drawing; it only
/// picks where a copy stands and when it plays, then lets it rest and
/// reappear somewhere else. Everything is worked out from the frame count,
/// so there's no state to keep.
struct GolemEmbers: View {
    /// How many sparks fly at once.
    let count: Int
    /// Frames a spark waits between flights, at most. Long rests make
    /// sparks rare; short ones make them crackle.
    let maxRest: Int
    /// The golem's drawn height, to place and size the sparks to match.
    let golemHeight: CGFloat

    private static let framesPerSecond = 12.0
    private static let frameCount = 5
    private static let variations = 3

    /// The ember tile is 180 px on the 900 px canvas of the golem's frames,
    /// whose cropped drawing is 603 px tall.
    private var tileSize: CGFloat { golemHeight * 180 / 603 }

    var body: some View {
        TimelineView(.periodic(from: .distantPast, by: 1 / Self.framesPerSecond)) { context in
            let tick = Int(context.date.timeIntervalSinceReferenceDate * Self.framesPerSecond)
            ZStack {
                ForEach(0..<count, id: \.self) { spark in
                    if let flight = flight(of: spark, at: tick) {
                        Image("GolemEmber\(flight.variation)-\(flight.frame + 1)")
                            .resizable()
                            .frame(width: tileSize, height: tileSize)
                            .offset(x: flight.x * golemHeight, y: flight.y * golemHeight)
                    }
                }
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private struct Flight {
        /// Which drawing, from 1.
        let variation: Int
        let frame: Int
        /// Where the tile's centre stands, from the golem's centre, in
        /// golem heights.
        let x: CGFloat
        let y: CGFloat
    }

    /// The spark's frame now, or nil while it rests between flights. Each
    /// flight gets its own spot and rest from a hash of (spark, flight).
    private func flight(of spark: Int, at tick: Int) -> Flight? {
        let cycle = Self.frameCount + maxRest
        // Spread the sparks out so they don't all fly together.
        let shifted = tick + spark * 5
        let number = shifted / cycle
        let step = shifted % cycle
        var random = Seed(spark &* 7919 &+ number)
        let rest = random.next(upTo: maxRest + 1)
        guard step >= rest, step - rest < Self.frameCount else { return nil }

        // Beside him, left or right of the body, from the knees up to the
        // shoulders; a white spark over the white golem wouldn't show.
        let side: CGFloat = random.next(upTo: 2) == 0 ? -1 : 1
        let x = side * (0.48 + CGFloat(random.next(upTo: 100)) / 100 * 0.18)
        let y = 0.25 - CGFloat(random.next(upTo: 100)) / 100 * 0.55
        let variation = random.next(upTo: Self.variations) + 1
        return Flight(variation: variation, frame: step - rest, x: x, y: y)
    }
}

/// A tiny repeatable random sequence (SplitMix64), so a flight's spot is
/// the same on every redraw.
private struct Seed {
    private var state: UInt64

    init(_ value: Int) { state = UInt64(bitPattern: Int64(value)) }

    mutating func next(upTo bound: Int) -> Int {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Int(z % UInt64(bound))
    }
}

#Preview {
    GolemEmbers(count: 10, maxRest: 6, golemHeight: 182)
        .frame(width: 400, height: 400)
        .background(.black)
}
