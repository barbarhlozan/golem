import Foundation
import Testing
@testable import GolemKit

struct PleaRulesTests {
    let rules = PleaRules(waitSeconds: 30, minimumReasonLength: 10, grantedMinutes: 5)

    @Test func freshPleaHasBothObstacles() {
        #expect(rules.obstacles(secondsWriting: 0, reason: "") == [
            .mustWait(secondsLeft: 30),
            .reasonTooShort(charactersLeft: 10),
        ])
    }

    @Test func waitingAloneIsNotEnough() {
        #expect(rules.obstacles(secondsWriting: 30, reason: "meh") == [
            .reasonTooShort(charactersLeft: 7),
        ])
    }

    @Test func whitespaceDoesNotCountAsReason() {
        #expect(!rules.isGranted(secondsWriting: 30, reason: "          "))
    }

    @Test func waitingAndReasonGrantsThePlea() {
        #expect(rules.isGranted(secondsWriting: 31, reason: "Replying to a friend"))
    }
}

struct PleaHintTests {
    let rules = PleaRules(waitSeconds: 10, minimumReasonLength: 20, grantedMinutes: 5)

    private func hint(secondsWriting: Int, reason: String) -> String {
        GolemVoice.pleaHint(
            obstacles: rules.obstacles(secondsWriting: secondsWriting, reason: reason),
            hasStartedWriting: !reason.isEmpty,
            grantedMinutes: rules.grantedMinutes
        )
    }

    @Test func invitesYouToWriteBeforeTheFirstLetter() {
        #expect(hint(secondsWriting: 0, reason: "") == "Start writing. I'm listening.")
    }

    @Test func countsDownAndAsksForMoreWhileWriting() {
        #expect(hint(secondsWriting: 3, reason: "My sister is sendin") == "I read slowly. 7s · 1 more letter")
    }

    @Test func asksForMoreOnceTheWaitIsOver() {
        #expect(hint(secondsWriting: 10, reason: "Just one") == "Not convinced. 12 more letters")
    }

    @Test func givesInWhenEverythingIsMet() {
        #expect(hint(secondsWriting: 10, reason: "My sister is sending the flat photos") == "Fine. 5 minutes, no more.")
    }
}

struct SharedStoreTests {
    /// A fresh, empty store for every test.
    let store = SharedStore(suiteName: "GolemKitTests.\(UUID().uuidString)")

    @Test func returnsDefaultsWhenEmpty() {
        #expect(store.settings == .default)
        #expect(store.sessions.isEmpty)
    }

    @Test func roundTripsSettings() {
        var settings = GolemSettings.default
        settings.breakMinutes = 7
        settings.pleaRules.waitSeconds = 60

        store.settings = settings

        #expect(store.settings == settings)
    }
}
