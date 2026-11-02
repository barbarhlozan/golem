import Foundation
import Testing
@testable import GolemKit

struct SharedStoreTests {
    /// A fresh, empty store for every test.
    let store = SharedStore(suiteName: "GolemKitTests.\(UUID().uuidString)")

    @Test func returnsDefaultsWhenEmpty() {
        #expect(store.settings == .default)
        #expect(store.sessions.isEmpty)
    }

    @Test func roundTripsSettings() {
        var settings = GolemSettings.default
        settings.isWatching = true
        settings.groups[0].limitMinutes = 7

        store.settings = settings

        #expect(store.settings == settings)
    }
}
