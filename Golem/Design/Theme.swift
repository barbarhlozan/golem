import SwiftUI
import UIKit

/// Golem's look in one place: ink on warm paper, Optima headings, the
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

    /// Optima ships with iOS: flared and a little calligraphic, close in
    /// spirit to Basilea, with nothing to bundle or license. Body text stays
    /// the system font, so the app still reads like iOS.
    private static let headingFontName = "Optima-Bold"

    /// The golem's own lines ("Time's up", etc.). Scales with Dynamic Type.
    static let golemLine = Font.custom(headingFontName, size: 24, relativeTo: .title2)

    /// Navigation titles are drawn by UIKit, so SwiftUI fonts don't reach
    /// them. Call once at launch.
    static func styleNavigationBars() {
        let appearance = UINavigationBar.appearance()
        if let large = UIFont(name: headingFontName, size: 34) {
            appearance.largeTitleTextAttributes = [.font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: large)]
        }
        if let inline = UIFont(name: headingFontName, size: 17) {
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

    /// App-wide defaults. Apply once at the root.
    func golemStyle() -> some View {
        tint(Theme.ink)
    }
}
