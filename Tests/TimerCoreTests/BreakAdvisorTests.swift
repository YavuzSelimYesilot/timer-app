import XCTest
@testable import TimerCore

final class BreakAdvisorTests: XCTestCase {

    // MARK: - No suggestion cases

    func testEvaluate_noSessions_returnsNil() {
        let result = BreakAdvisor.evaluate(
            todaySessions: [],
            currentStreak: 0,
        )
        XCTAssertNil(result)
    }

    func testEvaluate_oneFocusSession_returnsNil() {
        let result = BreakAdvisor.evaluate(
            todaySessions: [session(.focus)],
            currentStreak: 0,
        )
        XCTAssertNil(result)
    }

    func testEvaluate_twoConsecutiveFocus_returnsNil() {
        let sessions = [session(.focus), session(.focus)]
        let result = BreakAdvisor.evaluate(
            todaySessions: sessions,
            currentStreak: 0,
        )
        XCTAssertNil(result)
    }

    // MARK: - Short break

    func testEvaluate_threeConsecutiveFocus_suggestsShortBreak() {
        let sessions = (0..<3).map { _ in session(.focus) }
        let result = BreakAdvisor.evaluate(
            todaySessions: sessions,
            currentStreak: 0,
        )
        XCTAssertEqual(result?.kind, .shortBreak)
        XCTAssertEqual(result?.urgency, 1)
    }

    // MARK: - Long break

    func testEvaluate_fourConsecutiveFocus_suggestsLongBreak() {
        let sessions = (0..<4).map { _ in session(.focus) }
        let result = BreakAdvisor.evaluate(
            todaySessions: sessions,
            currentStreak: 0,
        )
        XCTAssertEqual(result?.kind, .longBreak)
        XCTAssertEqual(result?.urgency, 2)
    }

    func testEvaluate_fiveConsecutiveFocus_suggestsLongBreak() {
        let sessions = (0..<5).map { _ in session(.focus) }
        let result = BreakAdvisor.evaluate(
            todaySessions: sessions,
            currentStreak: 0,
        )
        XCTAssertEqual(result?.kind, .longBreak)
    }

    // MARK: - Break resets consecutive count

    func testEvaluate_breakAfterThreeFocus_resetsCount() {
        // focus × 3, sonra break — trailing = 0
        let sessions = [session(.focus), session(.focus), session(.focus), session(.shortBreak)]
        let result = BreakAdvisor.evaluate(
            todaySessions: sessions,
            currentStreak: 0,
        )
        XCTAssertNil(result)
    }

    func testEvaluate_twoFocusAfterBreak_returnsNil() {
        // focus × 3, break, focus × 2 — trailing = 2
        let sessions = [
            session(.focus), session(.focus), session(.focus),
            session(.shortBreak),
            session(.focus), session(.focus),
        ]
        let result = BreakAdvisor.evaluate(
            todaySessions: sessions,
            currentStreak: 0,
        )
        XCTAssertNil(result)
    }

    // MARK: - Stop for day

    func testEvaluate_eveningWithFiveSessions_suggestsStopForDay() {
        let sessions = (0..<5).map { _ in session(.focus) }
        let evening = hour(19)
        let result = BreakAdvisor.evaluate(
            todaySessions: sessions,
            currentStreak: 0,
            now: evening
        )
        XCTAssertEqual(result?.kind, .stopForDay)
        XCTAssertEqual(result?.urgency, 3)
    }

    func testEvaluate_eveningButOnlyTwoSessions_returnsNil() {
        let sessions = [session(.focus), session(.focus)]
        let evening = hour(19)
        let result = BreakAdvisor.evaluate(
            todaySessions: sessions,
            currentStreak: 0,
            now: evening
        )
        XCTAssertNil(result)
    }

    func testEvaluate_lateNightThreeSessions_suggestsStopForDay() {
        let sessions = (0..<3).map { _ in session(.focus) }
        let lateNight = hour(21)
        let result = BreakAdvisor.evaluate(
            todaySessions: sessions,
            currentStreak: 0,
            now: lateNight
        )
        XCTAssertEqual(result?.kind, .stopForDay)
    }

    // MARK: - Milestone

    func testEvaluate_milestoneStreak_returnsWellDone() {
        let result = BreakAdvisor.evaluate(
            todaySessions: [session(.focus)],
            currentStreak: 7,
        )
        XCTAssertEqual(result?.kind, .wellDone)
        XCTAssertEqual(result?.urgency, 1)
    }

    func testEvaluate_nonMilestoneStreak_notWellDone() {
        let result = BreakAdvisor.evaluate(
            todaySessions: [session(.focus)],
            currentStreak: 5,
        )
        XCTAssertNil(result)
    }

    // MARK: - Priority: stop-for-day > milestone

    func testEvaluate_eveningAndMilestone_prioritizesStopForDay() {
        let sessions = (0..<5).map { _ in session(.focus) }
        let result = BreakAdvisor.evaluate(
            todaySessions: sessions,
            currentStreak: 7,
            now: hour(19)
        )
        XCTAssertEqual(result?.kind, .stopForDay)
    }

    // MARK: - trailingFocusCount

    func testTrailingFocusCount_allFocus() {
        let sessions = (0..<4).map { _ in session(.focus) }
        XCTAssertEqual(BreakAdvisor.trailingFocusCount(from: sessions), 4)
    }

    func testTrailingFocusCount_endsWithBreak() {
        let sessions = [session(.focus), session(.focus), session(.longBreak)]
        XCTAssertEqual(BreakAdvisor.trailingFocusCount(from: sessions), 0)
    }

    func testTrailingFocusCount_breakInMiddle() {
        let sessions = [
            session(.focus), session(.focus),
            session(.shortBreak),
            session(.focus), session(.focus), session(.focus),
        ]
        XCTAssertEqual(BreakAdvisor.trailingFocusCount(from: sessions), 3)
    }

    func testTrailingFocusCount_empty() {
        XCTAssertEqual(BreakAdvisor.trailingFocusCount(from: []), 0)
    }

    // MARK: - Helpers

    private func session(_ mode: TimerMode, at offset: TimeInterval = 0) -> SessionRecord {
        SessionRecord(
            date: Date().addingTimeInterval(offset),
            mode: mode,
            durationMinutes: mode == .focus ? 25 : 5
        )
    }

    private func hour(_ h: Int) -> Date {
        Calendar.current.date(bySettingHour: h, minute: 0, second: 0, of: Date())!
    }
}
