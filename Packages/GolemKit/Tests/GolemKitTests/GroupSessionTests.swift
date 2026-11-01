import Foundation
import Testing
@testable import GolemKit

/// Seconds after an arbitrary start, to keep the timelines readable.
private func t(_ seconds: TimeInterval) -> Date {
    Date(timeIntervalSinceReferenceDate: 1_000_000 + seconds)
}

struct GroupSessionTests {
    @Test func countsOnlyTimeInsideTheApps() {
        var session = GroupSession()
        session.appOpened(at: t(0))
        session.appClosed(at: t(60))
        // 30 s away gives 30 s back; then 30 s more in the app.
        session.appOpened(at: t(90))

        #expect(session.elapsed(at: t(120)) == 60)
    }

    @Test func switchingAppsInsideAGroupIsOneVisit() {
        var session = GroupSession()
        session.appOpened(at: t(0))
        // Instagram → TikTok: "opened" arrives just before "closed".
        session.appOpened(at: t(100))
        let didStop = session.appClosed(at: t(101))

        #expect(!didStop)
        #expect(session.isRunning)
        #expect(session.elapsed(at: t(200)) == 200)
    }

    @Test func aQuickOpenAndCloseStillStops() {
        var session = GroupSession()
        session.appOpened(at: t(0))

        let didStop = session.appClosed(at: t(1))

        #expect(didStop)
        #expect(!session.isRunning)
    }

    @Test func stopIgnoresTheSwitchGrace() {
        var session = GroupSession()
        session.appOpened(at: t(0))
        session.appOpened(at: t(100))

        // A "closed" now would count as part of a switch; a stop doesn't.
        let didStop = session.stop(at: t(101))
        let stoppedAgain = session.stop(at: t(102))

        #expect(didStop)
        #expect(!stoppedAgain)
        #expect(!session.isRunning)
        #expect(session.elapsed(at: t(500)) == 101)
    }

    @Test func stayingAwayAsLongAsYouWereInStartsFromZero() {
        var session = GroupSession()
        session.appOpened(at: t(0))
        session.appClosed(at: t(300))
        session.appOpened(at: t(600))

        #expect(session.elapsed(at: t(605)) == 5)
    }

    @Test func aShortBreakGivesSomeTimeBack() {
        var session = GroupSession()
        session.appOpened(at: t(0))
        session.appClosed(at: t(300))
        // 2 of the 5 minutes come back.
        session.appOpened(at: t(420))

        #expect(session.elapsed(at: t(420)) == 180)
    }

    @Test func everySecondAwayGivesASecondBack() {
        var session = GroupSession()
        session.appOpened(at: t(0))
        session.appClosed(at: t(600))

        #expect(session.rested(at: t(600)).elapsed(at: t(600)) == 600)
        #expect(session.rested(at: t(750)).elapsed(at: t(750)) == 450)
        #expect(session.rested(at: t(1200)).elapsed(at: t(1200)) == 0)
    }

    @Test func aStoredRestedSessionKeepsResting() {
        var session = GroupSession()
        session.appOpened(at: t(0))
        session.appClosed(at: t(600))

        // Stored halfway (as a plea does), then rested again later:
        // the same as resting in one go.
        let halfway = session.rested(at: t(900))
        let later = halfway.rested(at: t(1000))

        #expect(halfway.elapsed(at: t(900)) == 300)
        #expect(later.elapsed(at: t(1000)) == session.rested(at: t(1000)).elapsed(at: t(1000)))
    }

    @Test func restingCanBringYouBackUnderTheLimit() {
        var session = GroupSession()
        session.appOpened(at: t(0))
        session.appClosed(at: t(6 * 60))   // 6 min used, limit 5

        #expect(session.isOverLimit(limitMinutes: 5, at: t(6 * 60)))
        #expect(!session.rested(at: t(6 * 60 + 2 * 60)).isOverLimit(limitMinutes: 5, at: t(8 * 60)))
    }

    @Test func restsOnlyWhileAwayWithTimeToGiveBack() {
        var session = GroupSession()
        #expect(!session.isResting)                     // nothing used yet

        session.appOpened(at: t(0))
        #expect(!session.isResting)                     // in the app

        session.appClosed(at: t(120))
        #expect(session.rested(at: t(180)).isResting)   // 1 of 2 min back
        #expect(!session.rested(at: t(240)).isResting)  // fresh again
    }

    @Test func limitDateAccountsForTimeAlreadyUsed() {
        var session = GroupSession()
        session.appOpened(at: t(0))
        session.appClosed(at: t(120))
        // A minute away: 1 of the 2 minutes is left.
        session.appOpened(at: t(180))

        // 5 min limit, 1 min used → runs out 4 min after reopening.
        #expect(session.limitDate(limitMinutes: 5, at: t(180)) == t(180 + 240))
        #expect(session.startDate(at: t(180)) == t(120))
    }

    @Test func pleadingGrantsMinutesFromNow() {
        var session = GroupSession()
        session.appOpened(at: t(0))
        session.appClosed(at: t(9 * 60))   // 9 min used, limit 5 → 4 over

        session.grant(minutes: 5, limitMinutes: 5, at: t(9 * 60))

        #expect(!session.isOverLimit(limitMinutes: 5, at: t(9 * 60)))
        #expect(session.allowance(limitMinutes: 5) == 14 * 60)
    }
}

struct SessionTrackerTests {
    let store = SharedStore(suiteName: "GolemKitTests.\(UUID().uuidString)")
    var social: WatchGroup { store.settings.groups[0] }
    var news: WatchGroup { store.settings.groups[1] }

    @Test func openingAnotherGroupPausesTheFirst() {
        let tracker = SessionTracker(store: store)
        tracker.appOpened(groupID: social.id, at: t(0))
        tracker.appOpened(groupID: news.id, at: t(60))

        // Social rests while News runs: 30 s later, 30 s of its minute is left.
        #expect(tracker.session(for: social.id, at: t(90)).elapsed(at: t(90)) == 30)
        #expect(tracker.session(for: news.id, at: t(90)).isRunning)
    }

    @Test func stopAllStopsTheRunningGroup() {
        let tracker = SessionTracker(store: store)
        tracker.appOpened(groupID: social.id, at: t(0))
        #expect(tracker.runningGroup()?.id == social.id)

        #expect(tracker.stopAll(at: t(60)))
        #expect(tracker.runningGroup() == nil)
        #expect(tracker.session(for: social.id, at: t(60)).elapsed(at: t(60)) == 60)
        #expect(!tracker.stopAll(at: t(70)))
    }

    @Test func mostRecentGroupOverLimitComesFirst() {
        let tracker = SessionTracker(store: store)
        tracker.appOpened(groupID: social.id, at: t(0))
        tracker.appOpened(groupID: news.id, at: t(20 * 60))   // social: 20 of 5 min

        // news: 11 of 10 min; social has rested 11 min: still 9 of 5
        let order = tracker.groupsOverLimit(at: t(31 * 60)).map(\.id)
        #expect(order == [news.id, social.id])
    }

    @Test func reportsGroupsOverTheirLimit() {
        let tracker = SessionTracker(store: store)
        tracker.appOpened(groupID: social.id, at: t(0))

        #expect(tracker.groupsOverLimit(at: t(4 * 60)).isEmpty)
        #expect(tracker.groupsOverLimit(at: t(5 * 60)).map(\.id) == [social.id])
    }
}
