import SwiftUI
import UIKit

/// Golem's look in one place: ink on warm paper, blackletter headings, the
/// hand-drawn golem. Screens use these names instead of raw colors and fonts,
/// so the style can change here without touching every screen.
///
/// The colors live in the asset catalog (`Ink`, `Paper`, `Card`), so each one
/// has a light and a dark value. See "Visual style" in `docs/decisions.md`.
enum Theme {
    // MARK: Colors

    /// Text, buttons and lines. Near-black on paper, off-white in dark mode.
    static let ink = Color("Ink")
    /// Screen background: warm off-white, like a sketchbook page.
    static let paper = Color("Paper")
    /// Rows and cards sitting on the paper.
    static let card = Color("Card")

    // MARK: Type

    /// Rounded system type for body text: friendly, still clearly iOS.
    static let fontDesign: Font.Design = .rounded

    /// UnifrakturMaguntia: blackletter, a nod to the golem's old-Prague roots.
    /// Bundled in `Resources/Fonts` (free OFL license, kept next to it) and
    /// only used for big headings, because blackletter is hard to read small.
    static let headingFontName = "UnifrakturMaguntia"

    /// The golem's own lines ("Time's up", etc.). Scales with Dynamic Type.
    /// Use it via `.golemLine()`, which also switches off the rounded design.
    static let golemLine = Font.custom(headingFontName, size: 30, relativeTo: .title2)

    /// Navigation titles are drawn by UIKit, so SwiftUI fonts don't reach
    /// them. Call once at launch.
    @MainActor
    static func styleNavigationBars() {
        let appearance = UINavigationBar.appearance()
        if let large = UIFont(name: headingFontName, size: 34) {
            appearance.largeTitleTextAttributes = [.font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: large)]
        }
        if let inline = UIFont(name: headingFontName, size: 20) {
            appearance.titleTextAttributes = [.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: inline)]
        }
    }
}

extension View {
    /// Blackletter heading for the golem's lines. The app-wide rounded
    /// design would otherwise replace the custom font with the system one.
    func golemLine() -> some View {
        font(Theme.golemLine)
            .fontDesign(nil)
    }

    /// Paper background behind a `Form` or `List`, with white rows on top.
    func golemBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Theme.paper)
    }

    /// App-wide defaults. Apply once at the root.
    func golemStyle() -> some View {
        tint(Theme.ink)
            .fontDesign(Theme.fontDesign)
    }
}
