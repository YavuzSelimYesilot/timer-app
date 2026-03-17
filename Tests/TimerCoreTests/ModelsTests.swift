import XCTest
@testable import TimerCore

final class ModelsTests: XCTestCase {

    // MARK: - TimerMode

    func testTimerMode_allCasesCount() {
        XCTAssertEqual(TimerMode.allCases.count, 3)
    }

    func testTimerMode_rawValues() {
        XCTAssertEqual(TimerMode.focus.rawValue,      "Focus")
        XCTAssertEqual(TimerMode.shortBreak.rawValue, "Short Break")
        XCTAssertEqual(TimerMode.longBreak.rawValue,  "Long Break")
    }

    func testTimerMode_shortTitles() {
        XCTAssertEqual(TimerMode.focus.shortTitle,      "Focus")
        XCTAssertEqual(TimerMode.shortBreak.shortTitle, "Short")
        XCTAssertEqual(TimerMode.longBreak.shortTitle,  "Long")
    }

    func testTimerMode_initFromRawValue() {
        XCTAssertEqual(TimerMode(rawValue: "Focus"),       .focus)
        XCTAssertEqual(TimerMode(rawValue: "Short Break"), .shortBreak)
        XCTAssertEqual(TimerMode(rawValue: "Long Break"),  .longBreak)
        XCTAssertNil(TimerMode(rawValue: "Unknown"))
    }

    func testTimerMode_hashable() {
        let set: Set<TimerMode> = [.focus, .focus, .shortBreak]
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - TimerPreset

    func testTimerPreset_classicValues() {
        let p = TimerPreset.classic
        XCTAssertEqual(p.name,        "Classic")
        XCTAssertEqual(p.focus,       25)
        XCTAssertEqual(p.shortBreak,  5)
        XCTAssertEqual(p.longBreak,   15)
    }

    func testTimerPreset_extendedValues() {
        let p = TimerPreset.extended
        XCTAssertEqual(p.name,        "Extended")
        XCTAssertEqual(p.focus,       50)
        XCTAssertEqual(p.shortBreak,  10)
        XCTAssertEqual(p.longBreak,   20)
    }

    func testTimerPreset_sprintValues() {
        let p = TimerPreset.sprint
        XCTAssertEqual(p.name,        "Sprint")
        XCTAssertEqual(p.focus,       15)
        XCTAssertEqual(p.shortBreak,  3)
        XCTAssertEqual(p.longBreak,   10)
    }

    func testTimerPreset_allContainsThreePresets() {
        XCTAssertEqual(TimerPreset.all.count, 3)
    }

    func testTimerPreset_allContainsExpectedPresets() {
        let names = TimerPreset.all.map(\.name)
        XCTAssertTrue(names.contains("Classic"))
        XCTAssertTrue(names.contains("Extended"))
        XCTAssertTrue(names.contains("Sprint"))
    }

    func testTimerPreset_equalityBySameInstance() {
        XCTAssertEqual(TimerPreset.classic, TimerPreset.classic)
    }

    func testTimerPreset_inequalityBetweenPresets() {
        XCTAssertNotEqual(TimerPreset.classic, TimerPreset.extended)
        XCTAssertNotEqual(TimerPreset.classic, TimerPreset.sprint)
        XCTAssertNotEqual(TimerPreset.extended, TimerPreset.sprint)
    }

    func testTimerPreset_customInitEquality() {
        let a = TimerPreset(name: "X", focus: 20, shortBreak: 4, longBreak: 12)
        let b = TimerPreset(name: "X", focus: 20, shortBreak: 4, longBreak: 12)
        XCTAssertEqual(a, b)
    }

    func testTimerPreset_customInitInequality() {
        let a = TimerPreset(name: "A", focus: 20, shortBreak: 4, longBreak: 12)
        let b = TimerPreset(name: "B", focus: 20, shortBreak: 4, longBreak: 12)
        XCTAssertNotEqual(a, b)
    }
}
