import Foundation

@MainActor
public final class StreakManager: ObservableObject {
    @Published public private(set) var currentStreak: Int
    @Published public private(set) var longestStreak: Int

    private let defaults: UserDefaults
    private let calendar = Calendar.current

    private enum Keys {
        static let currentStreak = "streak_current"
        static let longestStreak = "streak_longest"
        static let lastActiveDay = "streak_lastActiveDay"
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.currentStreak = defaults.integer(forKey: Keys.currentStreak)
        self.longestStreak = defaults.integer(forKey: Keys.longestStreak)
    }

    public var lastActiveDate: Date? {
        let interval = defaults.double(forKey: Keys.lastActiveDay)
        guard interval > 0 else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    /// Focus oturumu tamamlandığında çağrılır. `date` test için inject edilebilir.
    public func recordSession(date: Date = Date()) {
        let today = calendar.startOfDay(for: date)

        if let lastDate = lastActiveDate {
            let lastDay = calendar.startOfDay(for: lastDate)

            if calendar.isDate(lastDay, inSameDayAs: today) {
                return // Bugün zaten kaydedildi
            }

            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            currentStreak = daysDiff == 1 ? currentStreak + 1 : 1
        } else {
            currentStreak = 1
        }

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        persist(lastActiveDate: date)
    }

    /// Uygulama açılışında seri geçerliliğini kontrol eder. `currentDate` test için inject edilebilir.
    public func validateStreak(currentDate: Date = Date()) {
        guard let lastDate = lastActiveDate else { return }

        let lastDay = calendar.startOfDay(for: lastDate)
        let today = calendar.startOfDay(for: currentDate)
        let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

        if daysDiff > 1 {
            currentStreak = 0
            persist(lastActiveDate: lastDate)
        }
    }

    /// Mevcut seri bir milestone'daysa o değeri döner, değilse nil.
    public var streakMilestone: Int? {
        let milestones = [3, 7, 14, 21, 30, 60, 100]
        return milestones.contains(currentStreak) ? currentStreak : nil
    }

    private func persist(lastActiveDate: Date) {
        defaults.set(currentStreak, forKey: Keys.currentStreak)
        defaults.set(longestStreak, forKey: Keys.longestStreak)
        defaults.set(lastActiveDate.timeIntervalSince1970, forKey: Keys.lastActiveDay)
    }
}
