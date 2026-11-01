import SwiftUI

/// Golem's look in one place: ink on warm paper, rounded type, the hand-drawn
/// golem. Screens use these names instead of raw colors and fonts, so the
/// style can change here without touching every screen.
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

    /// Rounded system type: friendlier than the default, still clearly iOS.
    static let fontDesign: Font.Design = .rounded

    /// Big, heavy text for the golem's own lines ("Time's up", etc.).
    static let golemLine = Font.system(.title2, design: fontDesign, weight: .heavy)
}

extension View {
    /// Paper background behind a `Form` or `List`, with white rows on top.
    func golemBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Theme.paper)
    }

    /// App-wide defaults: ink tint and rounded type. Apply once at the root.
    func golemStyle() -> some View {
        tint(Theme.ink)
            .fontDesign(Theme.fontDesign)
    }
}
