import SwiftUI

/// The golem looming out of the dark when the plea opens: white lines on
/// black, appearing and growing slowly into a close-up of his upper body.
///
/// The numbers were tuned by the owner in a mockup 248 points wide, so
/// distances are stored as fractions of the screen width and scale with it.
/// To retune, change `Tuning` only.
struct PleaGolemIntro: View {
    enum Tuning {
        static let startScale = 0.70
        static let endScale = 0.80
        /// Distance from the top of the screen, as a fraction of its width.
        static let startOffset = 90.0 / 248
        static let endOffset = 100.0 / 248
        static let growSeconds = 2.8
        static let fadeInSeconds = 0.7
        /// "Smooth out": quick at first, settling gently.
        static let growCurve = Animation.timingCurve(0.3, 0.1, 0.2, 1, duration: growSeconds)

        /// When the question and the text box start rising in, after opening.
        static let textDelaySeconds = growSeconds - 2.0
        static let textRiseSeconds = 1.3

        /// How tall the soft fade above the text is, as a fraction of the width.
        static let fadeHeight = 90.0 / 248
        /// How dark the fade already is halfway down.
        static let fadeMidOpacity = 0.65
    }

    /// Whether the intro has played. Before that, the golem is small and hidden.
    let isRevealed: Bool

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            Image("Golem")
                .resizable()
                .scaledToFit()
                .colorInvert()
                .frame(width: width)
                .scaleEffect(
                    isRevealed ? Tuning.endScale : Tuning.startScale,
                    anchor: UnitPoint(x: 0.5, y: 0.1)
                )
                .offset(y: width * (isRevealed ? Tuning.endOffset : Tuning.startOffset))
                .animation(Tuning.growCurve, value: isRevealed)
                .opacity(isRevealed ? 1 : 0)
                .animation(.easeOut(duration: Tuning.fadeInSeconds), value: isRevealed)
        }
        .accessibilityHidden(true)
    }
}

/// Black that fades in from transparent, so the text sits over the golem's
/// lower half without a hard edge.
struct PleaFade: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0), location: 0),
                .init(color: .black.opacity(PleaGolemIntro.Tuning.fadeMidOpacity), location: 0.5),
                .init(color: .black, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview {
    PleaGolemIntro(isRevealed: true)
        .background(.black)
}
