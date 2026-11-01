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

    /// Blackletter, a nod to the golem's old-Prague roots. It's bundled in
    /// `Resources/Fonts` (free OFL license, kept next to it) and only used
    /// for big headings, because blackletter is hard to read when small.
    private static let headingFontName = "UnifrakturMaguntia"

    /// Rounded system type for everything else: friendly, still clearly iOS.
    static let fontDesign: Font.Design = .rounded

    /// The golem's own lines ("Time's up", etc.). Scales with Dynamic Type.
    /// Use it via `.golemLine()`, which also switches off the rounded design.
    static let golemLine = Font.custom(headingFontName, size: 30, relativeTo: .title2)

    /// Navigation titles are drawn by UIKit, so SwiftUI fonts don't reach
    /// them. Call once at launch.
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
    /// Paper background behind a `Form` or `List`, with white rows on top.
    func golemBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Theme.paper)
    }

    /// Blackletter heading for the golem's lines. The app-wide rounded
    /// design would otherwise replace the custom font with the system one.
    func golemLine() -> some View {
        font(Theme.golemLine)
            .fontDesign(nil)
    }

    /// App-wide defaults. Apply once at the root.
    func golemStyle() -> some View {
        tint(Theme.ink)
            .fontDesign(Theme.fontDesign)
    }
}
