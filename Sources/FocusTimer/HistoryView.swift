import SwiftUI
import SwiftData
import TimerCore

// MARK: - SwiftData Model

@Model
final class FocusSession {
    var date: Date
    var modeRaw: String
    var durationMinutes: Int

    init(date: Date, mode: TimerMode, durationMinutes: Int) {
        self.date = date
        self.modeRaw = mode.rawValue
        self.durationMinutes = durationMinutes
    }

    var mode: TimerMode {
        TimerMode(rawValue: modeRaw) ?? .focus
    }
}

// MARK: - History View

struct HistoryView: View {
    @EnvironmentObject var lang: LanguageManager
    @Query(sort: \FocusSession.date, order: .reverse) private var sessions: [FocusSession]

    private var focusSessions: [FocusSession] {
        sessions.filter { $0.mode == .focus }
    }

    private var todaySessions: [FocusSession] {
        let start = Calendar.current.startOfDay(for: Date())
        return focusSessions.filter { $0.date >= start }
    }

    private var weekSessions: [FocusSession] {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return focusSessions.filter { $0.date >= start }
    }

    private var todayMinutes: Int { todaySessions.reduce(0) { $0 + $1.durationMinutes } }
    private var weekMinutes: Int  { weekSessions.reduce(0) { $0 + $1.durationMinutes } }

    var body: some View {
        VStack(spacing: 0) {
            // Stats row
            HStack(spacing: 0) {
                StatCard(
                    value: "\(todaySessions.count)",
                    label: lang.loc("history.today"),
                    sub: "\(todayMinutes)m"
                )
                Divider()
                    .background(Color.white.opacity(0.06))
                    .frame(height: 44)
                StatCard(
                    value: "\(weekSessions.count)",
                    label: lang.loc("history.thisWeek"),
                    sub: "\(weekMinutes)m"
                )
                Divider()
                    .background(Color.white.opacity(0.06))
                    .frame(height: 44)
                StatCard(
                    value: "\(focusSessions.count)",
                    label: lang.loc("history.allTime"),
                    sub: totalHoursLabel
                )
            }
            .padding(.bottom, 12)

            Divider()
                .background(Color.white.opacity(0.06))

            // Weekly bar chart
            if !weekSessions.isEmpty {
                WeeklyBarChart(sessions: weekSessions)
                    .frame(height: 60)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)

                Divider()
                    .background(Color.white.opacity(0.06))
                    .padding(.top, 12)
            }

            // Recent sessions list
            if sessions.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(sessions.prefix(30)) { session in
                            SessionRowView(session: session)
                            Divider()
                                .background(Color.white.opacity(0.04))
                                .padding(.leading, 20)
                        }
                    }
                }
                .frame(maxHeight: 180)
            }

            Divider()
                .background(Color.white.opacity(0.06))

            QuitButtonView()
                .padding(.vertical, 10)
        }
    }

    private var totalHoursLabel: String {
        let mins = focusSessions.reduce(0) { $0 + $1.durationMinutes }
        return mins >= 60 ? "\(mins / 60)h \(mins % 60)m" : "\(mins)m"
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text("history.empty.title", bundle: lang.bundle)
                .font(.system(size: 13, weight: .light))
                .foregroundColor(.white.opacity(0.3))
            Text("history.empty.subtitle", bundle: lang.bundle)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.18))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let value: String
    let label: String
    let sub: String

    var body: some View {
        VStack(spacing: 3) {
            Text(verbatim: value)
                .font(.system(size: 22, weight: .thin, design: .monospaced))
                .foregroundColor(.white)
            Text(verbatim: label)
                .font(.system(size: 7, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
                .tracking(1.5)
            Text(verbatim: sub)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.2))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}

// MARK: - Weekly Bar Chart

struct WeeklyBarChart: View {
    let sessions: [FocusSession]

    private let days: [Date] = {
        (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: -6 + $0, to: Calendar.current.startOfDay(for: Date()))
        }
    }()

    private func minutesFor(_ day: Date) -> Int {
        let end = Calendar.current.date(byAdding: .day, value: 1, to: day) ?? day
        return sessions
            .filter { $0.date >= day && $0.date < end }
            .reduce(0) { $0 + $1.durationMinutes }
    }

    var body: some View {
        let values = days.map { minutesFor($0) }
        let maxVal = max(values.max() ?? 1, 1)

        HStack(alignment: .bottom, spacing: 5) {
            ForEach(Array(zip(days, values)), id: \.0) { day, mins in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isToday(day) ? Color.white : Color.white.opacity(0.2))
                        .frame(height: max(3, CGFloat(mins) / CGFloat(maxVal) * 40))

                    Text(verbatim: dayLabel(day))
                        .font(.system(size: 8))
                        .foregroundColor(isToday(day) ? .white.opacity(0.5) : .white.opacity(0.2))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func dayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return String(f.string(from: date).prefix(1))
    }
}

// MARK: - Session Row

struct SessionRowView: View {
    @EnvironmentObject var lang: LanguageManager
    let session: FocusSession

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(modeColor)
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(session.mode.locKey), bundle: lang.bundle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
                Text(verbatim: formattedDate)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.25))
            }

            Spacer()

            Text("\(session.durationMinutes)m")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 9)
    }

    private var modeColor: Color {
        switch session.mode {
        case .focus:      return .white
        case .shortBreak: return .white.opacity(0.5)
        case .longBreak:  return .white.opacity(0.3)
        }
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: lang.currentLanguage.code)
        if Calendar.current.isDateInToday(session.date) {
            f.dateFormat = "HH:mm"
            return String(format: lang.loc("history.date.today"), f.string(from: session.date))
        } else if Calendar.current.isDateInYesterday(session.date) {
            f.dateFormat = "HH:mm"
            return String(format: lang.loc("history.date.yesterday"), f.string(from: session.date))
        } else {
            f.dateFormat = "MMM d, HH:mm"
            return f.string(from: session.date)
        }
    }
}
