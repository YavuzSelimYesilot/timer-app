import Foundation

// MARK: - Session Record

public struct SessionRecord {
    public let date: Date
    public let mode: TimerMode
    public let durationMinutes: Int

    public init(date: Date, mode: TimerMode, durationMinutes: Int) {
        self.date = date
        self.mode = mode
        self.durationMinutes = durationMinutes
    }
}

// MARK: - Break Suggestion

public enum BreakSuggestionKind: Equatable {
    case shortBreak  // 5–10 dk mola öner
    case longBreak   // 15–20 dk mola öner
    case stopForDay  // Bugün yeter
    case wellDone    // Streak milestone kutlaması
}

public struct BreakSuggestion: Equatable {
    public let kind: BreakSuggestionKind
    public let message: String
    public let urgency: Int  // 1 (bilgi) … 3 (acil)
}

// MARK: - Break Advisor

public enum BreakAdvisor {

    private static let milestones = [3, 7, 14, 21, 30, 60, 100]

    /// Bugünkü oturumları, mevcut seriyi ve saati değerlendirerek bir öneri üretir.
    /// `now` parametresi test için inject edilebilir.
    public static func evaluate(
        todaySessions: [SessionRecord],
        currentStreak: Int,
        currentMode: TimerMode,
        now: Date = Date()
    ) -> BreakSuggestion? {

        let focusSessions = todaySessions.filter { $0.mode == .focus }
        guard !focusSessions.isEmpty else { return nil }

        let focusCount = focusSessions.count
        let hour = Calendar.current.component(.hour, from: now)
        let consecutive = trailingFocusCount(from: todaySessions)

        // Kural 1: Günün sonu — 19:00+ ve 5+ focus oturumu
        if hour >= 19 && focusCount >= 5 {
            return BreakSuggestion(
                kind: .stopForDay,
                message: "Bugün \(focusCount) oturum tamamladın. Ekrandan uzaklaşma zamanı.",
                urgency: 3
            )
        }

        // Kural 2: Geç akşam uyarısı — 21:00+ ve 3+ focus
        if hour >= 21 && focusCount >= 3 {
            return BreakSuggestion(
                kind: .stopForDay,
                message: "Gece geç oldu. Yarın için biraz enerji bırak.",
                urgency: 3
            )
        }

        // Kural 3: Streak milestone kutlaması
        if milestones.contains(currentStreak) {
            return BreakSuggestion(
                kind: .wellDone,
                message: "\(currentStreak) günlük seri! Bugün uzun bir molayı hak ettin.",
                urgency: 1
            )
        }

        // Kural 4: 4+ art arda focus — uzun mola
        if consecutive >= 4 {
            return BreakSuggestion(
                kind: .longBreak,
                message: "\(consecutive) focus oturumu üst üste. Uzun bir mola seni bekliyor.",
                urgency: 2
            )
        }

        // Kural 5: 3 art arda focus — kısa mola
        if consecutive == 3 {
            return BreakSuggestion(
                kind: .shortBreak,
                message: "3 oturum tamamlandı. Kısa bir nefes almak ister misin?",
                urgency: 1
            )
        }

        return nil
    }

    // MARK: - Internal

    /// Oturum listesinin sonundan geriye doğru kesintisiz focus sayısını döner.
    /// Araya break girince sayım sıfırlanır.
    static func trailingFocusCount(from sessions: [SessionRecord]) -> Int {
        let sorted = sessions.sorted { $0.date < $1.date }
        var count = 0
        for session in sorted.reversed() {
            if session.mode == .focus {
                count += 1
            } else {
                break
            }
        }
        return count
    }
}
