import SwiftUI

/// The golem on the home screen, in his current phase.
///
/// He stays still for now: moving the drawing in code (breathing, a
/// shudder) broke the hand-drawn look, so each phase will get its own short
/// hand-drawn animation instead. Until then every resting phase shows the
/// eyes-closed drawing, with torchlight behind him while he's orange or red.
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
    /// Torchlight behind him, in the Island's colour; nil while calm.
    let glow: Color?

    private static let height: CGFloat = 260

    var body: some View {
        GolemFigure(height: Self.height, isAsleep: phase != .keepingWatch)
            // A background, so the wide glow never widens the screen's layout.
            .background { glowView }
    }

    @ViewBuilder
    private var glowView: some View {
        if let glow {
            RadialGradient(
                colors: [glow.opacity(0.35), glow.opacity(0)],
                center: .center,
                startRadius: 0,
                endRadius: Self.height * 0.75
            )
            .frame(width: Self.height * 1.6, height: Self.height * 1.4)
            .transition(.opacity)
        }
    }
}

#Preview {
    LivingGolem(phase: .restless, glow: .red)
        .background(.black)
}
