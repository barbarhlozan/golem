import SwiftUI

/// The hand-drawn golem from the app icon, for the home screen and
/// the first run. The drawing is in `Design/golem.png`; the asset catalog holds a
/// copy with a transparent background.
///
/// `isAsleep` shows the "GolemAsleep" drawing (eyes closed) once it's in the
/// asset catalog, and the normal golem until then.
struct GolemFigure: View {
    var height: CGFloat = 120
    var isAsleep = false

    private var imageName: String {
        isAsleep && UIImage(named: "GolemAsleep") != nil ? "GolemAsleep" : "Golem"
    }

    var body: some View {
        Image(imageName)
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
