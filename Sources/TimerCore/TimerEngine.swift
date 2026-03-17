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

    // MARK: - Completion Publisher (macOS layer observes this for sound/notification)

    public let completionPublisher = PassthroughSubject<TimerMode, Never>()

    // MARK: - Private

    private var cancellable: AnyCancellable?

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

    /// How many sessions completed in the current 4-session cycle (0–3)
    public var sessionsInCycle: Int {
        completedSessions % 4
    }

    private var totalSeconds: Int {
        switch mode {
        case .focus:      return preset.focus * 60
        case .shortBreak: return preset.shortBreak * 60
        case .longBreak:  return preset.longBreak * 60
        }
    }

    // MARK: - Actions

    public func toggle() {
        isRunning ? pause() : start()
    }

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
        timeRemaining = totalSeconds
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
        pause()

        if completedMode == .focus {
            completedSessions += 1
        }

        completionPublisher.send(completedMode)
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
