#if DEBUG
import SwiftUI

/// Debug builds only: switch the heading font while the owner tries the
/// candidates on a real phone. Remove it (and shrink `HeadingFont`) once
/// one is picked.
struct HeadingFontSection: View {
    @AppStorage(HeadingFont.storageKey) private var heading = HeadingFont.blackletter

    var body: some View {
        Section {
            Picker("Heading font", selection: $heading) {
                ForEach(HeadingFont.allCases) { font in
                    Text(font.name).tag(font)
                }
            }
            .pickerStyle(.segmented)
            Text("The Golem is watching")
                .golemLine()
        } header: {
            Text("Heading font")
        } footer: {
            Text("Big screen titles switch after you restart the app.")
        }
        .onChange(of: heading) {
            Theme.styleNavigationBars(with: heading)
        }
    }
}
#endif
