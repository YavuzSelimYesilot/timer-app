import Foundation

// MARK: - Timer Mode

public enum TimerMode: String, CaseIterable, Hashable {
    case focus       = "Focus"
    case shortBreak  = "Short Break"
    case longBreak   = "Long Break"

    public var shortTitle: String {
        switch self {
        case .focus:      return "Focus"
        case .shortBreak: return "Short"
        case .longBreak:  return "Long"
        }
    }
}

// MARK: - Timer Preset

public struct TimerPreset: Equatable {
    public let name: String
    public let focus: Int       // minutes
    public let shortBreak: Int  // minutes
    public let longBreak: Int   // minutes

    public init(name: String, focus: Int, shortBreak: Int, longBreak: Int) {
        self.name = name
        self.focus = focus
        self.shortBreak = shortBreak
        self.longBreak = longBreak
    }

    public static let classic  = TimerPreset(name: "Classic",  focus: 25, shortBreak: 5,  longBreak: 15)
    public static let extended = TimerPreset(name: "Extended", focus: 50, shortBreak: 10, longBreak: 20)
    public static let sprint   = TimerPreset(name: "Sprint",   focus: 15, shortBreak: 3,  longBreak: 10)

    public static let all: [TimerPreset] = [.classic, .extended, .sprint]
}
