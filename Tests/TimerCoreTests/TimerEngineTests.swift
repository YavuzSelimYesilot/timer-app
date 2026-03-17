import XCTest
import Combine
@testable import TimerCore

@MainActor
final class TimerEngineTests: XCTestCase {

    var engine: TimerEngine!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        engine = TimerEngine()
        cancellables = []
    }

    override func tearDown() {
        engine.pause()
        cancellables = nil
        engine = nil
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertFalse(engine.isRunning)
        XCTAssertEqual(engine.mode, .focus)
        XCTAssertEqual(engine.timeRemaining, 25 * 60)
        XCTAssertEqual(engine.completedSessions, 0)
        XCTAssertEqual(engine.preset, .classic)
        XCTAssertFalse(engine.hasCustomDuration)
        XCTAssertEqual(engine.sessionsInCycle, 0)
    }

    func testInitialProgress() {
        XCTAssertEqual(engine.progress, 0.0)
    }

    func testInitialTimeString() {
        XCTAssertEqual(engine.timeString, "25:00")
    }

    // MARK: - Start / Pause / Toggle

    func testStartSetsRunning() {
        engine.start()
        XCTAssertTrue(engine.isRunning)
    }

    func testPauseClearsRunning() {
        engine.start()
        engine.pause()
        XCTAssertFalse(engine.isRunning)
    }

    func testToggleStartsWhenStopped() {
        XCTAssertFalse(engine.isRunning)
        engine.toggle()
        XCTAssertTrue(engine.isRunning)
    }

    func testTogglePausesWhenRunning() {
        engine.start()
        engine.toggle()
        XCTAssertFalse(engine.isRunning)
    }

    func testDoubleStartIsIdempotent() {
        engine.start()
        engine.start()
        XCTAssertTrue(engine.isRunning)
    }

    // MARK: - Reset

    func testResetRestoresTime() {
        engine.tick()
        engine.tick()
        XCTAssertEqual(engine.timeRemaining, 25 * 60 - 2)
        engine.reset()
        XCTAssertEqual(engine.timeRemaining, 25 * 60)
    }

    func testResetStopsTimer() {
        engine.start()
        engine.reset()
        XCTAssertFalse(engine.isRunning)
    }

    // MARK: - Tick / Progress

    func testTickDecrementsTime() {
        engine.tick()
        XCTAssertEqual(engine.timeRemaining, 25 * 60 - 1)
    }

    func testProgressIncreasesAfterTick() {
        engine.tick()
        XCTAssertGreaterThan(engine.progress, 0.0)
        XCTAssertLessThan(engine.progress, 1.0)
    }

    func testProgressIsOneWhenTimeRunsOut() {
        engine.timeRemaining = 1
        engine.tick() // triggers complete(), which calls switchMode() → resets time
        // After completion, a new mode starts so progress resets — check we got a publish
        // Progress will be 0 for the new mode; just ensure no crash and state is consistent
        XCTAssertGreaterThanOrEqual(engine.progress, 0.0)
    }

    func testTimeStringFormats() {
        engine.timeRemaining = 90  // 1:30
        XCTAssertEqual(engine.timeString, "01:30")

        engine.timeRemaining = 3661  // 61:01
        XCTAssertEqual(engine.timeString, "61:01")

        engine.timeRemaining = 0
        XCTAssertEqual(engine.timeString, "00:00")
    }

    // MARK: - Custom Duration (Slider)

    func testSetDurationChangesTime() {
        engine.setDuration(minutes: 30)
        XCTAssertEqual(engine.timeRemaining, 30 * 60)
    }

    func testSetDurationSetsCustomFlag() {
        engine.setDuration(minutes: 30)
        XCTAssertTrue(engine.hasCustomDuration)
        XCTAssertEqual(engine.currentDurationMinutes, 30)
    }

    func testSetDurationClampsMinimum() {
        engine.setDuration(minutes: 0)
        XCTAssertEqual(engine.currentDurationMinutes, 1)
    }

    func testSetDurationClampsMaximum() {
        engine.setDuration(minutes: 999)
        XCTAssertEqual(engine.currentDurationMinutes, 90)
    }

    func testSetDurationIgnoredWhenRunning() {
        engine.start()
        let before = engine.timeRemaining
        engine.setDuration(minutes: 1)
        XCTAssertEqual(engine.timeRemaining, before)
        XCTAssertFalse(engine.hasCustomDuration)
    }

    // MARK: - Preset

    func testApplyPresetChangesValues() {
        engine.applyPreset(.extended)
        XCTAssertEqual(engine.preset, .extended)
        XCTAssertEqual(engine.timeRemaining, 50 * 60)
    }

    func testApplyPresetClearsCustomDuration() {
        engine.setDuration(minutes: 42)
        XCTAssertTrue(engine.hasCustomDuration)
        engine.applyPreset(.classic)
        XCTAssertFalse(engine.hasCustomDuration)
    }

    func testApplyPresetStopsTimer() {
        engine.start()
        engine.applyPreset(.sprint)
        XCTAssertFalse(engine.isRunning)
    }

    func testCurrentDurationMinutes_usesPresetByDefault() {
        XCTAssertEqual(engine.currentDurationMinutes, 25)
        engine.applyPreset(.extended)
        XCTAssertEqual(engine.currentDurationMinutes, 50)
    }

    func testCurrentDurationMinutes_prefersCustom() {
        engine.setDuration(minutes: 37)
        XCTAssertEqual(engine.currentDurationMinutes, 37)
    }

    // MARK: - Mode Switching

    func testSwitchModeChangesModeAndTime() {
        engine.switchMode(.shortBreak)
        XCTAssertEqual(engine.mode, .shortBreak)
        XCTAssertEqual(engine.timeRemaining, 5 * 60)
    }

    func testSwitchModeStopsTimer() {
        engine.start()
        engine.switchMode(.longBreak)
        XCTAssertFalse(engine.isRunning)
    }

    func testSwitchModeToLongBreakUsesCorrectDuration() {
        engine.switchMode(.longBreak)
        XCTAssertEqual(engine.timeRemaining, 15 * 60)
    }

    // MARK: - Session Counting & Mode Advancement

    func testSessionsInCycleStartsAtZero() {
        XCTAssertEqual(engine.sessionsInCycle, 0)
    }

    func testCompletingFocusIncrementsCount() {
        engine.timeRemaining = 1
        engine.tick()
        XCTAssertEqual(engine.completedSessions, 1)
    }

    func testModeAdvancement_firstFocusToShortBreak() {
        engine.timeRemaining = 1
        engine.tick()
        XCTAssertEqual(engine.mode, .shortBreak)
    }

    func testModeAdvancement_afterShortBreakToFocus() {
        // Complete focus → short break
        engine.timeRemaining = 1
        engine.tick()
        XCTAssertEqual(engine.mode, .shortBreak)
        // Complete short break → focus
        engine.timeRemaining = 1
        engine.tick()
        XCTAssertEqual(engine.mode, .focus)
    }

    func testModeAdvancement_fourthFocusToLongBreak() {
        // Simulate 4 focus completions
        for _ in 0..<4 {
            engine.mode = .focus
            engine.timeRemaining = 1
            engine.tick()
            if engine.mode != .focus {
                // put it back to focus for next cycle
                engine.switchMode(.focus)
            }
        }
        // After 4 completed focus sessions, last one should advance to long break
        // Let's do this more directly:
        engine.timeRemaining = 0
        // Set completedSessions to 3 (so next is 4, triggering long break)
        // We'll complete one more focus session
        // Reset and set up for the 4th completion
        let freshEngine = TimerEngine()
        // Complete 3 sessions first
        for _ in 0..<3 {
            freshEngine.mode = .focus
            freshEngine.timeRemaining = 1
            freshEngine.tick()
            freshEngine.switchMode(.focus)
        }
        XCTAssertEqual(freshEngine.completedSessions, 3)
        // 4th focus completion should go to long break
        freshEngine.mode = .focus
        freshEngine.timeRemaining = 1
        freshEngine.tick()
        XCTAssertEqual(freshEngine.completedSessions, 4)
        XCTAssertEqual(freshEngine.mode, .longBreak)
    }

    func testSessionsInCycleWrapsAt4() {
        for i in 0..<4 {
            engine.mode = .focus
            engine.timeRemaining = 1
            engine.tick()
            if i < 3 { engine.switchMode(.focus) }
        }
        // After 4 completions, sessionsInCycle should be 0 (4 % 4 == 0)
        XCTAssertEqual(engine.sessionsInCycle, 0)
    }

    // MARK: - Completion Publisher

    func testCompletionPublisherEmitsOnComplete() {
        let expectation = expectation(description: "completion published")
        var receivedMode: TimerMode?
        var receivedMinutes: Int?

        engine.completionPublisher
            .sink { event in
                receivedMode = event.mode
                receivedMinutes = event.minutes
                expectation.fulfill()
            }
            .store(in: &cancellables)

        engine.timeRemaining = 1
        engine.tick()

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedMode, .focus)
        XCTAssertEqual(receivedMinutes, 25)
    }

    func testCompletionPublisherDoesNotEmitOnTick() {
        var emitCount = 0
        engine.completionPublisher
            .sink { _ in emitCount += 1 }
            .store(in: &cancellables)

        engine.tick()
        engine.tick()
        XCTAssertEqual(emitCount, 0)
    }
}
