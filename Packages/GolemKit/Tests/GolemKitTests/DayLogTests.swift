import Foundation
import Testing
@testable import GolemKit

struct DayLogTests {
    let calendar = Calendar(identifier: .gregorian)
    let group = UUID()

    /// Noon on a fixed day, plus seconds.
    private func noon(_ seconds: TimeInterval = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 12))!
            .addingTimeInterval(seconds)
    }

    @Test func countsVisitsAndTheLongest() {
        var log = DayLog()
        log.visitStarted(groupID: group, at: noon(), calendar: calendar)
        log.visitEnded(groupID: group, lasting: 120, at: noon(120), calendar: calendar)
        log.visitStarted(groupID: group, at: noon(600), calendar: calendar)
        log.visitEnded(groupID: group, lasting: 60, at: noon(660), calendar: calendar)

        #expect(log.entry(for: group, at: noon(700), calendar: calendar) == .init(visits: 2, longestSeconds: 120))
    }

    @Test func startsOverTheNextDay() {
        var log = DayLog()
        log.visitStarted(groupID: group, at: noon(), calendar: calendar)
        log.visitEnded(groupID: group, lasting: 60, at: noon(60), calendar: calendar)

        let tomorrow = noon(24 * 3600)
        #expect(log.entry(for: group, at: tomorrow, calendar: calendar) == .init())
        #expect(log.isEmpty(at: tomorrow, calendar: calendar))
    }

    @Test func aVisitAcrossMidnightIsTodaysFirst() {
        var log = DayLog()
        log.visitStarted(groupID: group, at: noon(11.9 * 3600), calendar: calendar)
        let afterMidnight = noon(12.1 * 3600)
        log.visitEnded(groupID: group, lasting: 720, at: afterMidnight, calendar: calendar)

        #expect(log.entry(for: group, at: afterMidnight, calendar: calendar) == .init(visits: 1, longestSeconds: 720))
    }

    @Test func trackerLogsOneVisitWhenSwitchingApps() {
        let store = SharedStore(suiteName: "GolemKitTests.\(UUID().uuidString)")
        let tracker = SessionTracker(store: store)
        let now = Date.now
        tracker.appOpened(groupID: group, at: now)
        // Instagram → TikTok: "opened" arrives just before "closed".
        tracker.appOpened(groupID: group, at: now.addingTimeInterval(100))
        tracker.appClosed(groupID: group, at: now.addingTimeInterval(101))
        tracker.appClosed(groupID: group, at: now.addingTimeInterval(200))

        let entry = store.dayLog.entry(for: group, at: now.addingTimeInterval(200))
        #expect(entry.visits == 1)
        #expect(entry.longestSeconds == 200)
    }
}

struct GolemMomentTests {
    @Test func followsTheIslandsStages() {
        #expect(GolemMoment(usedSeconds: 0, limitSeconds: 300) == .waking)
        #expect(GolemMoment(usedSeconds: 239, limitSeconds: 300) == .waking)
        #expect(GolemMoment(usedSeconds: 240, limitSeconds: 300) == .stirring)
        #expect(GolemMoment(usedSeconds: 300, limitSeconds: 300) == .angry)
    }
}
