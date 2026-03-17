import Foundation
import Combine

@MainActor
public final class TimerEngine: ObservableObject {

    // MARK: - Published State

    @Published public var mode: TimerMode = .focus
    @Published public var timeRemaining: Int = TimerPreset.classic.focus * 60
    @Published public var isRunning: Bool = false
    @Published public var completedSessions: Int = 0
    @Published public var preset: TimerPreset = .classic

    // MARK: - Completion Publisher

    public let completionPublisher = PassthroughSubject<(mode: TimerMode, minutes: Int), Never>()

    // MARK: - Private

    private var cancellable: AnyCancellable?
    /// Per-mode overrides set by the circular slider (nil = use preset)
    private var customDurations: [TimerMode: Int] = [:]

    public init() {}

    // MARK: - Computed

    public var progress: Double {
        let total = totalSeconds
        guard total > 0 else { return 0 }
        return Double(total - timeRemaining) / Double(total)
    }

    public var timeString: String {
        String(format: "%02d:%02d", timeRemaining / 60, timeRemaining % 60)
    }

    public var sessionsInCycle: Int { completedSessions % 4 }

    /// Current duration in minutes for the active mode (custom override or preset)
    public var currentDurationMinutes: Int {
        customDurations[mode] ?? presetMinutes
    }

    /// True if the current mode has a custom (slider-set) duration
    public var hasCustomDuration: Bool {
        customDurations[mode] != nil
    }

    private var totalSeconds: Int { currentDurationMinutes * 60 }

    private var presetMinutes: Int {
        switch mode {
        case .focus:      return preset.focus
        case .shortBreak: return preset.shortBreak
        case .longBreak:  return preset.longBreak
        }
    }

    // MARK: - Actions

    public func toggle() { isRunning ? pause() : start() }

    public func start() {
        guard !isRunning else { return }
        isRunning = true
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    public func pause() {
        isRunning = false
        cancellable?.cancel()
        cancellable = nil
    }

    public func reset() {
        pause()
        timeRemaining = totalSeconds
    }

    public func switchMode(_ newMode: TimerMode) {
        pause()
        mode = newMode
        timeRemaining = totalSeconds
    }

    public func applyPreset(_ newPreset: TimerPreset) {
        pause()
        preset = newPreset
        customDurations.removeAll()
        timeRemaining = totalSeconds
    }

    /// Called by the circular slider — sets a custom duration for the current mode
    public func setDuration(minutes: Int) {
        guard !isRunning else { return }
        let clamped = max(1, min(90, minutes))
        customDurations[mode] = clamped
        timeRemaining = clamped * 60
    }

    // MARK: - Private

    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            complete()
        }
    }

    private func complete() {
        let completedMode = mode
        let minutes = currentDurationMinutes
        pause()
        if completedMode == .focus { completedSessions += 1 }
        completionPublisher.send((mode: completedMode, minutes: minutes))
        advance(from: completedMode)
    }

    private func advance(from completedMode: TimerMode) {
        switch completedMode {
        case .focus:
            switchMode(completedSessions % 4 == 0 ? .longBreak : .shortBreak)
        case .shortBreak, .longBreak:
            switchMode(.focus)
        }
    }
}
