import SwiftUI

/// The hand-drawn golem from the app icon, for empty states and the plea
/// screen. The drawing is in `Design/golem.png`; the asset catalog holds a
/// copy with a transparent background.
struct GolemFigure: View {
    var height: CGFloat = 120

    var body: some View {
        Image("Golem")
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .accessibilityHidden(true)
    }
}

#Preview {
    GolemFigure()
        .padding()
        .background(Theme.paper)
}
