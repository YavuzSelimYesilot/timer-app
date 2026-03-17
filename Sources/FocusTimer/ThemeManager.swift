import SwiftUI

// MARK: - Accent Color

enum AccentColor: String, CaseIterable, Identifiable {
    case white  = "White"
    case blue   = "Blue"
    case orange = "Orange"
    case green  = "Green"
    case pink   = "Pink"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .white:  return .white
        case .blue:   return Color(red: 0.45, green: 0.72, blue: 1.0)
        case .orange: return Color(red: 1.0,  green: 0.62, blue: 0.22)
        case .green:  return Color(red: 0.28, green: 0.92, blue: 0.52)
        case .pink:   return Color(red: 1.0,  green: 0.45, blue: 0.72)
        }
    }
}

// MARK: - ThemeManager

final class ThemeManager: ObservableObject {
    @Published var accent: AccentColor {
        didSet { UserDefaults.standard.set(accent.rawValue, forKey: "accentColor") }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "accentColor") ?? ""
        accent = AccentColor(rawValue: saved) ?? .white
    }

    var accentColor: Color { accent.color }
}
