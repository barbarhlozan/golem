import GolemKit
import SwiftUI

/// The golem on the home screen, in his current phase.
///
/// He's played from the owner's hand-drawn frames (`GolemReel` picks them),
/// a short loop per phase with the eyes opening or closing in between.
/// Nothing is moved or scaled in code: that broke the hand-drawn look.
/// Sparks rise around him (`GolemEmbers`) while he's orange or red. A
/// torchlight glow behind him was tried and dropped: the sparks say it.
struct LivingGolem: View {
    enum Phase {
        /// A Screen Time shield keeps him up (full build). Eyes open.
        case keepingWatch
        /// A group is still past its limit.
        case restless
        /// Time is flowing back.
        case settling
        /// Every group is fresh.
        case asleep
    }

    let phase: Phase
    /// Orange or red, as in the Island: the sparks fly.
    let isWarm: Bool
    /// When you last came straight from a watched app: he wakes, then
    /// settles back into his phase.
    let wokenAt: Date?

    @State private var reel: GolemReel
    /// The loop he's heading for. Kept in state, not read from `phase`
    /// inside the frame timer, which would only ever see the phase it
    /// started with.
    @State private var target: GolemReel.Loop
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let height: CGFloat = 182

    /// The pace of the drawings. One per loop, so any can be slowed alone;
    /// the eyes opening or closing go at the pace of the loop they lead to.
    private static func framesPerSecond(_ loop: GolemReel.Loop) -> Double {
        switch loop {
        case .asleep: 12
        case .settling: 12
        case .restless: 12
        }
    }

    init(phase: Phase, isWarm: Bool, wokenAt: Date? = nil) {
        self.phase = phase
        self.isWarm = isWarm
        self.wokenAt = wokenAt
        _reel = State(initialValue: GolemReel(phase.loop))
        _target = State(initialValue: phase.loop)
    }

    var body: some View {
        Image(Self.imageName(reduceMotion ? GolemReel(phase.loop).frame : reel.frame))
            .resizable()
            .scaledToFit()
            .frame(height: Self.height)
            .accessibilityHidden(true)
            // A background, so the sparks never widen the screen's layout,
            // and they pass behind him.
            .background {
                GolemEmbers(count: reduceMotion ? 0 : emberCount, golemHeight: Self.height)
            }
            .task(id: reduceMotion) {
                guard !reduceMotion else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1 / Self.framesPerSecond(reel.loop)))
                    reel.tick(toward: target)
                }
            }
            .onChange(of: phase) { target = phase.loop }
            .onChange(of: wokenAt) { reel.wake() }
    }

    /// Sparks while he's restless, fewer once he's orange, none when calm.
    private var emberCount: Int {
        switch phase {
        case .restless, .keepingWatch: 6
        case .settling: isWarm ? 3 : 0
        case .asleep: 0
        }
    }

    /// The asset made by `Design/make-frames.sh`, e.g. "GolemSettling2".
    private static func imageName(_ frame: GolemReel.Frame) -> String {
        switch frame {
        case .loop(.asleep, let index): "GolemAsleep\(index + 1)"
        case .loop(.settling, let index): "GolemSettling\(index + 1)"
        case .loop(.restless, let index): "GolemRestless\(index + 1)"
        case .wake(let number): "GolemWake\(number)"
        }
    }
}

private extension LivingGolem.Phase {
    /// Keeping watch has no loop of its own: eyes open, like restless.
    var loop: GolemReel.Loop {
        switch self {
        case .keepingWatch, .restless: .restless
        case .settling: .settling
        case .asleep: .asleep
        }
    }
}

#Preview {
    LivingGolem(phase: .restless, isWarm: true)
        .background(.black)
}
