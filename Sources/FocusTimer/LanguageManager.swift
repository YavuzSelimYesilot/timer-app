import Foundation
import SwiftUI

// MARK: - Supported Languages

struct AppLanguage: Identifiable, Equatable {
    let code: String
    let label: String
    var id: String { code }
}

// MARK: - LanguageManager

@MainActor
final class LanguageManager: ObservableObject {

    static let supported: [AppLanguage] = [
        AppLanguage(code: "en", label: "EN"),
        AppLanguage(code: "tr", label: "TR"),
        AppLanguage(code: "de", label: "DE"),
        AppLanguage(code: "ja", label: "JA"),
        AppLanguage(code: "es", label: "ES")
    ]

    @Published private(set) var currentLanguage: AppLanguage
    private(set) var bundle: Bundle = .main

    init() {
        let saved    = UserDefaults.standard.string(forKey: "app_language")
        let autoCode = Locale.current.language.languageCode?.identifier ?? "en"
        let codes    = LanguageManager.supported.map { $0.code }
        let initial  = [saved, autoCode].compactMap { $0 }.first { codes.contains($0) } ?? "en"
        let lang     = LanguageManager.supported.first { $0.code == initial } ?? LanguageManager.supported[0]
        currentLanguage = lang
        bundle = LanguageManager.makeBundle(for: lang.code)
    }

    func setLanguage(_ language: AppLanguage) {
        guard language != currentLanguage else { return }
        UserDefaults.standard.set(language.code, forKey: "app_language")
        bundle = LanguageManager.makeBundle(for: language.code)
        currentLanguage = language   // triggers @Published → view rebuild
    }

    /// Shorthand for non-Text contexts (notifications, formatted strings)
    func loc(_ key: String) -> String {
        NSLocalizedString(key, bundle: bundle, comment: "")
    }

    // MARK: - Private

    private static func makeBundle(for code: String) -> Bundle {
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let b = Bundle(path: path) {
            return b
        }
        return .main
    }
}

// MARK: - TimerMode localization keys (UI layer only — TimerCore stays pure)

extension TimerMode {
    var locKey: String {
        switch self {
        case .focus:      return "mode.focus"
        case .shortBreak: return "mode.shortBreak"
        case .longBreak:  return "mode.longBreak"
        }
    }
    var shortLocKey: String {
        switch self {
        case .focus:      return "mode.focus.short"
        case .shortBreak: return "mode.shortBreak.short"
        case .longBreak:  return "mode.longBreak.short"
        }
    }
}
