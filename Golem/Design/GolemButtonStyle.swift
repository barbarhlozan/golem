import SwiftUI

/// Golem's main, filled button: paper-coloured text on ink.
///
/// The system's `.borderedProminent` always draws white text, which vanishes
/// in dark mode where ink is nearly white. Pairing ink with paper keeps the
/// contrast in both modes.
struct GolemPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Label(configuration: configuration)
    }

    private struct Label: View {
        let configuration: Configuration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(Theme.paper)
                .background(Theme.ink, in: Capsule())
                .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)
        }
    }
}

extension ButtonStyle where Self == GolemPrimaryButtonStyle {
    /// `.buttonStyle(.golemPrimary)`
    static var golemPrimary: GolemPrimaryButtonStyle { GolemPrimaryButtonStyle() }
}
