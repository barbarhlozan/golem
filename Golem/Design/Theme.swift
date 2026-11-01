import SwiftUI
import UIKit

/// Golem's look in one place: ink on warm paper, characterful headings, the
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

    /// Navigation titles are drawn by UIKit, so SwiftUI fonts don't reach
    /// them. Called at launch and when the heading font changes (bars that
    /// are already on screen keep the old font until the app restarts).
    static func styleNavigationBars(with heading: HeadingFont = .current) {
        let appearance = UINavigationBar.appearance()
        if let large = UIFont(name: heading.fontName, size: 34) {
            appearance.largeTitleTextAttributes = [.font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: large)]
        }
        if let inline = UIFont(name: heading.fontName, size: 20) {
            appearance.titleTextAttributes = [.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: inline)]
        }
    }
}

/// The bundled heading fonts (in `Resources/Fonts`, each with its free OFL
/// license). Still being tried out, so the debug section has a switch.
/// Once one is picked, this can shrink back to a single font name.
enum HeadingFont: String, CaseIterable, Identifiable {
    /// UnifrakturMaguntia: blackletter, a nod to the golem's old-Prague roots.
    case blackletter
    /// Freckle Face: chunky and comic-like.
    case freckleFace

    static let storageKey = "headingFont"

    /// The saved choice, for code outside SwiftUI views.
    static var current: HeadingFont {
        UserDefaults.standard.string(forKey: storageKey).flatMap(HeadingFont.init) ?? .blackletter
    }

    var id: String { rawValue }

    var name: String {
        switch self {
        case .blackletter: "Blackletter"
        case .freckleFace: "Freckle Face"
        }
    }

    var fontName: String {
        switch self {
        case .blackletter: "UnifrakturMaguntia"
        case .freckleFace: "FreckleFace-Regular"
        }
    }
}

/// The golem's own lines ("Time's up", etc.) in the chosen heading font.
/// Scales with Dynamic Type, and switches off the app-wide rounded design,
/// which would otherwise replace the custom font with the system one.
private struct GolemLine: ViewModifier {
    @AppStorage(HeadingFont.storageKey) private var heading = HeadingFont.blackletter

    func body(content: Content) -> some View {
        content
            .font(.custom(heading.fontName, size: 30, relativeTo: .title2))
            .fontDesign(nil)
    }
}

extension View {
    /// Heading text in the golem's voice. See `GolemLine`.
    func golemLine() -> some View {
        modifier(GolemLine())
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
