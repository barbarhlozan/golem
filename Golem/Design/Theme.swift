import GolemKit
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
    /// The home screen's background: black in both modes, as if the golem
    /// slept in a dungeon, so the white figure is the one thing that glows.
    static let night = Color("Night")

    /// The Island's colour for a moment (white, orange, red), so the home
    /// screen and the Island speak the same language. White is ink here.
    static func color(for moment: GolemMoment) -> Color {
        switch moment {
        case .waking: ink
        case .stirring: .orange
        case .angry: .red
        }
    }

    // MARK: Type

    /// Serif body text, in the spirit of Times New Roman: iOS's own serif
    /// (New York), so nothing to bundle and it scales with Dynamic Type.
    static let fontDesign: Font.Design = .serif

    /// UnifrakturMaguntia: blackletter, a nod to the golem's old-Prague roots.
    /// Bundled in `Resources/Fonts` (free OFL license, kept next to it) and
    /// only used for big headings, because blackletter is hard to read small.
    static let headingFontName = "UnifrakturMaguntia"

    /// The golem's own lines ("Time's up", etc.). Scales with Dynamic Type.
    /// Use it via `.golemLine()`, which also switches off the app-wide serif design.
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
    /// Blackletter heading for the golem's lines. The app-wide serif
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

    /// A rounded card on the paper, for content outside a `Form`.
    func golemCard() -> some View {
        padding(16)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    /// App-wide defaults. Apply once at the root.
    func golemStyle() -> some View {
        tint(Theme.ink)
            .fontDesign(Theme.fontDesign)
    }
}
