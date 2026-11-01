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
        session.appOpened(at: t(0), breakMinutes: 10)
        session.appClosed(at: t(60))
        session.appOpened(at: t(120), breakMinutes: 10)

        #expect(session.elapsed(at: t(150)) == 90)
    }

    @Test func switchingAppsInsideAGroupIsOneVisit() {
        var session = GroupSession()
        session.appOpened(at: t(0), breakMinutes: 10)
        // Instagram → TikTok: "opened" arrives just before "closed".
        session.appOpened(at: t(100), breakMinutes: 10)
        let didStop = session.appClosed(at: t(101))

        #expect(!didStop)
        #expect(session.isRunning)
        #expect(session.elapsed(at: t(200)) == 200)
    }

    @Test func aQuickOpenAndCloseStillStops() {
        var session = GroupSession()
        session.appOpened(at: t(0), breakMinutes: 10)

        let didStop = session.appClosed(at: t(1))

        #expect(didStop)
        #expect(!session.isRunning)
    }

    @Test func stopIgnoresTheSwitchGrace() {
        var session = GroupSession()
        session.appOpened(at: t(0), breakMinutes: 10)
        session.appOpened(at: t(100), breakMinutes: 10)

        // A "closed" now would count as part of a switch; a stop doesn't.
        let didStop = session.stop(at: t(101))
        let stoppedAgain = session.stop(at: t(102))

        #expect(didStop)
        #expect(!stoppedAgain)
        #expect(!session.isRunning)
        #expect(session.elapsed(at: t(500)) == 101)
    }

    @Test func aLongBreakStartsFromZero() {
        var session = GroupSession()
        session.appOpened(at: t(0), breakMinutes: 10)
        session.appClosed(at: t(300))
        session.appOpened(at: t(300 + 10 * 60), breakMinutes: 10)

        #expect(session.elapsed(at: t(300 + 10 * 60 + 5)) == 5)
    }

    @Test func aShortBreakKeepsCounting() {
        var session = GroupSession()
        session.appOpened(at: t(0), breakMinutes: 10)
        session.appClosed(at: t(300))
        session.appOpened(at: t(400), breakMinutes: 10)

        #expect(session.elapsed(at: t(400)) == 300)
    }

    @Test func limitDateAccountsForTimeAlreadyUsed() {
        var session = GroupSession()
        session.appOpened(at: t(0), breakMinutes: 10)
        session.appClosed(at: t(120))
        session.appOpened(at: t(200), breakMinutes: 10)

        // 5 min limit, 2 min used → runs out 3 min after reopening.
        #expect(session.limitDate(limitMinutes: 5, at: t(200)) == t(200 + 180))
        #expect(session.startDate(at: t(200)) == t(80))
    }

    @Test func pleadingGrantsMinutesFromNow() {
        var session = GroupSession()
        session.appOpened(at: t(0), breakMinutes: 10)
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

        #expect(tracker.session(for: social.id, at: t(500)).elapsed(at: t(500)) == 60)
        #expect(tracker.session(for: news.id, at: t(500)).isRunning)
    }

    @Test func stopAllStopsTheRunningGroup() {
        let tracker = SessionTracker(store: store)
        tracker.appOpened(groupID: social.id, at: t(0))
        #expect(tracker.runningGroup()?.id == social.id)

        #expect(tracker.stopAll(at: t(60)))
        #expect(tracker.runningGroup() == nil)
        #expect(tracker.session(for: social.id, at: t(500)).elapsed(at: t(500)) == 60)
        #expect(!tracker.stopAll(at: t(70)))
    }

    @Test func mostRecentGroupOverLimitComesFirst() {
        store.settings.breakMinutes = 60
        let tracker = SessionTracker(store: store)
        tracker.appOpened(groupID: social.id, at: t(0))
        tracker.appOpened(groupID: news.id, at: t(6 * 60))   // social: 6 of 5 min

        // news: 11 of 10 min
        let order = tracker.groupsOverLimit(at: t(17 * 60)).map(\.id)
        #expect(order == [news.id, social.id])
    }

    @Test func reportsGroupsOverTheirLimit() {
        let tracker = SessionTracker(store: store)
        tracker.appOpened(groupID: social.id, at: t(0))

        #expect(tracker.groupsOverLimit(at: t(4 * 60)).isEmpty)
        #expect(tracker.groupsOverLimit(at: t(5 * 60)).map(\.id) == [social.id])
    }
}
