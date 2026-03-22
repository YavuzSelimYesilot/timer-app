import SwiftUI
import SwiftData
import TimerCore

// MARK: - Break Suggestion Banner

struct BreakSuggestionView: View {
    @EnvironmentObject var streak: StreakManager
    @Query private var allSessions: [FocusSession]
    @State private var dismissed = false

    private var suggestion: BreakSuggestion? {
        guard !dismissed else { return nil }

        let today = Calendar.current.startOfDay(for: Date())
        let todaySessions = allSessions
            .filter { $0.date >= today }
            .sorted { $0.date < $1.date }
            .map { SessionRecord(date: $0.date, mode: $0.mode, durationMinutes: $0.durationMinutes) }

        return BreakAdvisor.evaluate(
            todaySessions: todaySessions,
            currentStreak: streak.currentStreak
        )
    }

    var body: some View {
        Group {
            if let s = suggestion {
                BannerCard(suggestion: s) {
                    withAnimation(.easeInOut(duration: 0.2)) { dismissed = true }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .onChange(of: allSessions.count, initial: false) { _, _ in
            dismissed = false
        }
    }
}

// MARK: - Banner Card

private struct BannerCard: View {
    let suggestion: BreakSuggestion
    let onDismiss: () -> Void

    private var accentColor: Color {
        switch suggestion.kind {
        case .shortBreak:  return .gray
        case .longBreak:   return .orange
        case .stopForDay:  return .red
        case .wellDone:    return .green
        }
    }

    private var icon: String {
        switch suggestion.kind {
        case .shortBreak:  return "cup.and.saucer"
        case .longBreak:   return "figure.walk"
        case .stopForDay:  return "moon"
        case .wellDone:    return "flame.fill"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(accentColor)
                .frame(width: 18)
                .padding(.top, 1)

            Text(suggestion.message)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)

            Spacer(minLength: 4)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .glassRoundedRect(
            cornerRadius: 8,
            fallback: Color.primary.opacity(suggestion.urgency == 3 ? 0.06 : 0.04)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}
