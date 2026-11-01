import SwiftUI
import WidgetKit

/// The widget extension. For now it only holds the live timer.
@main
struct GolemWidgets: WidgetBundle {
    var body: some Widget {
        GolemLiveActivity()
    }
}
