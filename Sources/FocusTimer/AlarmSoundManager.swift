import AppKit

// MARK: - Alarm Sound

enum AlarmSound: String, CaseIterable, Identifiable {
    case glass  = "Glass"
    case ping   = "Ping"
    case tink   = "Tink"
    case hero   = "Hero"
    case funk   = "Funk"

    var id: String { rawValue }

    func play() {
        guard let sound = NSSound(named: rawValue) else {
            #if DEBUG
            print("[AlarmSound] Ses yüklenemedi: '\(rawValue)'")
            #endif
            return
        }
        sound.play()
    }
}

// MARK: - Manager

@MainActor
final class AlarmSoundManager: ObservableObject {

    @Published var current: AlarmSound {
        didSet { UserDefaults.standard.set(current.rawValue, forKey: "alarmSound") }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "alarmSound") ?? ""
        current = AlarmSound(rawValue: saved) ?? .glass
    }

    func play() {
        current.play()
    }
}
