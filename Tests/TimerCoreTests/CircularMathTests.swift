import XCTest
@testable import TimerCore

final class CircularMathTests: XCTestCase {

    // MARK: - roundedToNearest

    func testRoundedToNearest_exactMultiple() {
        XCTAssertEqual(15.roundedToNearest(5), 15)
        XCTAssertEqual(25.roundedToNearest(5), 25)
    }

    func testRoundedToNearest_roundsDown() {
        XCTAssertEqual(11.roundedToNearest(5), 10)
        XCTAssertEqual(22.roundedToNearest(5), 20)
    }

    func testRoundedToNearest_roundsUp() {
        XCTAssertEqual(13.roundedToNearest(5), 15)
        XCTAssertEqual(23.roundedToNearest(5), 25)
    }

    func testRoundedToNearest_midpointRoundsDown() {
        // 12 is exactly mid between 10 and 15: 12 % 5 = 2, step/2 = 2 → rounds down
        XCTAssertEqual(12.roundedToNearest(5), 10)
    }

    func testRoundedToNearest_stepOfOne() {
        XCTAssertEqual(7.roundedToNearest(1), 7)
    }

    // MARK: - minutesFromAngle — cardinal directions

    // 12 o'clock (top): dx=0, dy<0 → angle ≈ 0 → ~0 min → clamped to 1
    func testAngle_12OClock_clampsToMinimum() {
        let result = minutesFromAngle(dx: 0, dy: -50, maxMinutes: 60)
        XCTAssertEqual(result, 1)
    }

    // 3 o'clock (right): dx>0, dy=0 → angle = π/2 → 25% of 60 = 15m
    func testAngle_3OClock_isQuarter() {
        let result = minutesFromAngle(dx: 50, dy: 0, maxMinutes: 60)
        // fraction ≈ 0.25, raw = 15, rounded to nearest 5 = 15
        XCTAssertEqual(result, 15)
    }

    // 6 o'clock (bottom): dx=0, dy>0 → angle = π → 50% of 60 = 30m
    func testAngle_6OClock_isHalf() {
        let result = minutesFromAngle(dx: 0, dy: 50, maxMinutes: 60)
        // fraction ≈ 0.5, raw = 30, rounded = 30
        XCTAssertEqual(result, 30)
    }

    // 9 o'clock (left): dx<0, dy=0 → angle = 3π/2 → 75% of 60 = 45m
    func testAngle_9OClock_isThreeQuarters() {
        let result = minutesFromAngle(dx: -50, dy: 0, maxMinutes: 60)
        // fraction ≈ 0.75, raw = 45, rounded = 45
        XCTAssertEqual(result, 45)
    }

    // MARK: - minutesFromAngle — clamping

    func testMinutesFromAngle_neverBelowOne() {
        // Any angle near 12 o'clock gives ~0 raw, clamped to 1
        let result = minutesFromAngle(dx: 0.0001, dy: -50, maxMinutes: 60)
        XCTAssertGreaterThanOrEqual(result, 1)
    }

    func testMinutesFromAngle_neverAboveMax() {
        // Just before 12 o'clock (anticlockwise) gives ~maxMinutes
        let result = minutesFromAngle(dx: -0.0001, dy: -50, maxMinutes: 60)
        XCTAssertLessThanOrEqual(result, 60)
    }

    func testMinutesFromAngle_respectsMaxMinutes() {
        let result30 = minutesFromAngle(dx: -50, dy: 0, maxMinutes: 30)
        let result90 = minutesFromAngle(dx: -50, dy: 0, maxMinutes: 90)
        // 9 o'clock = 75% of max
        XCTAssertLessThanOrEqual(result30, 30)
        XCTAssertLessThanOrEqual(result90, 90)
        // result90 should be larger than result30 for same angle
        XCTAssertGreaterThan(result90, result30)
    }

    // MARK: - minutesFromAngle — snapping

    func testMinutesFromAngle_snapsToFiveMinutes() {
        // All results should be multiples of 5 (or 1 if clamped)
        let testAngles: [(Double, Double)] = [
            (10, -40), (40, -10), (40, 10), (10, 40),
            (-10, 40), (-40, 10), (-40, -10), (-10, -40)
        ]
        for (dx, dy) in testAngles {
            let result = minutesFromAngle(dx: dx, dy: dy, maxMinutes: 60)
            XCTAssertTrue(result == 1 || result % 5 == 0,
                "Expected multiple of 5 or 1, got \(result) for dx=\(dx), dy=\(dy)")
        }
    }
}
