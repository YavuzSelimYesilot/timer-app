import XCTest
@testable import TimerCore

@MainActor
final class StreakManagerTests: XCTestCase {
    var manager: StreakManager!
    var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "test_streak_\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        manager = StreakManager(defaults: defaults)
    }

    override func tearDown() {
        manager = nil
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    // MARK: - recordSession

    func testFirstSession_setsStreakToOne() {
        manager.recordSession(date: day(0))
        XCTAssertEqual(manager.currentStreak, 1)
    }

    func testConsecutiveDays_incrementsStreak() {
        manager.recordSession(date: day(0))
        manager.recordSession(date: day(1))
        XCTAssertEqual(manager.currentStreak, 2)
    }

    func testThreeConsecutiveDays_streakIsThree() {
        manager.recordSession(date: day(0))
        manager.recordSession(date: day(1))
        manager.recordSession(date: day(2))
        XCTAssertEqual(manager.currentStreak, 3)
    }

    func testMissedDay_resetsStreakToOne() {
        manager.recordSession(date: day(0))
        manager.recordSession(date: day(2)) // gap
        XCTAssertEqual(manager.currentStreak, 1)
    }

    func testSameDayTwice_doesNotIncrement() {
        let now = Date()
        manager.recordSession(date: now)
        manager.recordSession(date: now.addingTimeInterval(3600))
        XCTAssertEqual(manager.currentStreak, 1)
    }

    func testLongestStreak_preservedAfterReset() {
        manager.recordSession(date: day(0))
        manager.recordSession(date: day(1))
        manager.recordSession(date: day(2))
        manager.recordSession(date: day(4)) // gap — seri sıfırlanır
        XCTAssertEqual(manager.currentStreak, 1)
        XCTAssertEqual(manager.longestStreak, 3)
    }

    func testLongestStreak_updatesWhenCurrentExceeds() {
        for i in 0..<5 {
            manager.recordSession(date: day(i))
        }
        XCTAssertEqual(manager.longestStreak, 5)
    }

    // MARK: - validateStreak

    func testValidateStreak_twoDaysAgo_resetsToZero() {
        manager.recordSession(date: day(-2))
        manager.validateStreak(currentDate: Date())
        XCTAssertEqual(manager.currentStreak, 0)
    }

    func testValidateStreak_yesterday_unchanged() {
        manager.recordSession(date: day(-1))
        manager.validateStreak(currentDate: Date())
        XCTAssertEqual(manager.currentStreak, 1)
    }

    func testValidateStreak_today_unchanged() {
        manager.recordSession(date: Date())
        manager.validateStreak(currentDate: Date())
        XCTAssertEqual(manager.currentStreak, 1)
    }

    func testValidateStreak_noSessions_noChange() {
        manager.validateStreak(currentDate: Date())
        XCTAssertEqual(manager.currentStreak, 0)
    }

    func testValidateStreak_doesNotResetLongestStreak() {
        manager.recordSession(date: day(-10))
        manager.recordSession(date: day(-9))
        manager.recordSession(date: day(-8))
        // Seri dolaysıyla sıfırlanır (8 gün önce)
        manager.validateStreak(currentDate: Date())
        XCTAssertEqual(manager.currentStreak, 0)
        XCTAssertEqual(manager.longestStreak, 3)
    }

    // MARK: - Persistence

    func testPersistence_currentStreakLoadsFromDefaults() {
        manager.recordSession(date: day(0))
        manager.recordSession(date: day(1))
        let manager2 = StreakManager(defaults: defaults)
        XCTAssertEqual(manager2.currentStreak, 2)
    }

    func testPersistence_longestStreakLoadsFromDefaults() {
        manager.recordSession(date: day(0))
        manager.recordSession(date: day(1))
        manager.recordSession(date: day(2))
        let manager2 = StreakManager(defaults: defaults)
        XCTAssertEqual(manager2.longestStreak, 3)
    }

    func testPersistence_freshInstance_startsAtZero() {
        let manager2 = StreakManager(defaults: defaults)
        XCTAssertEqual(manager2.currentStreak, 0)
        XCTAssertEqual(manager2.longestStreak, 0)
    }

    // MARK: - Milestone

    func testMilestone_nilWhenStreakIsZero() {
        XCTAssertNil(manager.streakMilestone)
    }

    func testMilestone_nilForNonMilestoneValue() {
        manager.recordSession(date: day(0))
        manager.recordSession(date: day(1))
        XCTAssertNil(manager.streakMilestone) // 2 milestone değil
    }

    func testMilestone_returnsThree() {
        for i in 0..<3 { manager.recordSession(date: day(i)) }
        XCTAssertEqual(manager.streakMilestone, 3)
    }

    func testMilestone_returnsSeven() {
        for i in 0..<7 { manager.recordSession(date: day(i)) }
        XCTAssertEqual(manager.streakMilestone, 7)
    }

    // MARK: - Helper

    private func day(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: Date())!
    }
}
