import Foundation
import Testing
@testable import GolemKit

struct PleaRulesTests {
    let rules = PleaRules(waitSeconds: 30, minimumReasonLength: 10, grantedMinutes: 5)

    @Test func freshPleaHasBothObstacles() {
        #expect(rules.obstacles(secondsWaited: 0, reason: "") == [
            .mustWait(secondsLeft: 30),
            .reasonTooShort(charactersLeft: 10),
        ])
    }

    @Test func waitingAloneIsNotEnough() {
        #expect(rules.obstacles(secondsWaited: 30, reason: "meh") == [
            .reasonTooShort(charactersLeft: 7),
        ])
    }

    @Test func whitespaceDoesNotCountAsReason() {
        #expect(!rules.isGranted(secondsWaited: 30, reason: "          "))
    }

    @Test func waitingAndReasonGrantsThePlea() {
        #expect(rules.isGranted(secondsWaited: 31, reason: "Replying to a friend"))
    }
}

struct SharedStoreTests {
    /// A fresh, empty store for every test.
    let store = SharedStore(suiteName: "GolemKitTests.\(UUID().uuidString)")

    @Test func returnsDefaultsWhenEmpty() {
        #expect(store.settings == .default)
        #expect(store.isShieldUp == false)
    }

    @Test func roundTripsSettings() {
        var settings = GolemSettings.default
        settings.limitMinutes = 7
        settings.pleaRules.waitSeconds = 60

        store.settings = settings

        #expect(store.settings == settings)
    }
}
