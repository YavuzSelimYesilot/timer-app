import SwiftUI
import SwiftData
import AppKit
import Combine
import UserNotifications
import TimerCore

// MARK: - Root View

struct ContentView: View {
    @EnvironmentObject var engine: TimerEngine
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var alarm: AlarmSoundManager
    @EnvironmentObject var streak: StreakManager
    @Environment(\.modelContext) private var modelContext
    @State private var showHistory = false
    @State private var showFloating = false
    @State private var showDevAssistant = false
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("FocusTimer")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.25))
                Spacer()
                Button {
                    FloatingTimerController.shared.toggle(engine: engine, theme: theme, lang: lang)
                    showFloating = FloatingTimerController.shared.isVisible
                } label: {
                    Image(systemName: showFloating ? "pip.fill" : "pip")
                        .font(.system(size: 12))
                        .foregroundColor(showFloating ? .white : .white.opacity(0.3))
                }
                .buttonStyle(.plain)

                Button {
                    showHistory.toggle()
                    if showHistory { showDevAssistant = false }
                } label: {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12))
                        .foregroundColor(showHistory ? .white : .white.opacity(0.3))
                }
                .buttonStyle(.plain)

                Button {
                    showDevAssistant.toggle()
                    if showDevAssistant { showHistory = false }
                } label: {
                    Image(systemName: showDevAssistant ? "wrench.and.screwdriver.fill" : "wrench.and.screwdriver")
                        .font(.system(size: 12))
                        .foregroundColor(showDevAssistant ? .white : .white.opacity(0.3))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)

            if showDevAssistant {
                DevAssistantView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            } else if showHistory {
                HistoryView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            } else {
                timerBody
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .frame(width: 280)
        .background(Color(red: 0.07, green: 0.07, blue: 0.07))
        .animation(.easeInOut(duration: 0.22), value: showHistory)
        .animation(.easeInOut(duration: 0.22), value: showDevAssistant)
        .onAppear {
            observeCompletion()
            streak.validateStreak()
        }
    }

    @ViewBuilder
    private var timerBody: some View {
        ModeSelectorView()
            .padding(.horizontal, 20)

        TimerRingView()
            .frame(width: 164, height: 164)
            .padding(.top, 24)

        SessionDotsView()
            .padding(.top, 16)

        StreakRowView()
            .padding(.top, 12)
            .padding(.horizontal, 20)

        ControlButtonsView()
            .padding(.top, 22)

        BreakSuggestionView()
            .padding(.top, 10)
            .padding(.horizontal, 20)
            .animation(.easeInOut(duration: 0.25), value: engine.completedSessions)

        PresetSelectorView()
            .padding(.top, 16)
            .padding(.horizontal, 20)

        ThemeSelectorView()
            .padding(.top, 10)
            .padding(.horizontal, 20)

        AmbientSelectorView()
            .padding(.top, 10)
            .padding(.horizontal, 20)

        AlarmSelectorView()
            .padding(.top, 10)
            .padding(.horizontal, 20)

        LanguageSelectorView()
            .padding(.top, 10)
            .padding(.horizontal, 20)

        Divider()
            .background(Color.white.opacity(0.06))
            .padding(.top, 12)

        QuitButtonView()
            .padding(.vertical, 10)
    }

    // MARK: - Completion handling

    private func observeCompletion() {
        engine.completionPublisher
            .receive(on: DispatchQueue.main)
            .sink { event in
                playCompletionSound()
                sendNotification(for: event.mode, completedSessions: engine.completedSessions)
                saveSession(mode: event.mode, minutes: event.minutes)
            }
            .store(in: &cancellables)
    }

    private func playCompletionSound() {
        alarm.play()
    }

    private func sendNotification(for mode: TimerMode, completedSessions: Int) {
        let content = UNMutableNotificationContent()
        switch mode {
        case .focus:
            content.title = lang.loc("notification.focus.title")
            content.body  = completedSessions % 4 == 0
                ? lang.loc("notification.focus.body.longBreak")
                : lang.loc("notification.focus.body.shortBreak")
        case .shortBreak:
            content.title = lang.loc("notification.shortBreak.title")
            content.body  = lang.loc("notification.shortBreak.body")
        case .longBreak:
            content.title = lang.loc("notification.longBreak.title")
            content.body  = lang.loc("notification.longBreak.body")
        }
        content.sound = .default
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }

    private func saveSession(mode: TimerMode, minutes: Int) {
        let session = FocusSession(date: Date(), mode: mode, durationMinutes: minutes)
        modelContext.insert(session)
        if mode == .focus {
            streak.recordSession()
        }
    }
}

// MARK: - Mode Selector

struct ModeSelectorView: View {
    @EnvironmentObject var engine: TimerEngine
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimerMode.allCases, id: \.self) { mode in
                Button { engine.switchMode(mode) } label: {
                    Text(LocalizedStringKey(mode.shortLocKey), bundle: lang.bundle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(engine.mode == mode ? .white : .white.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(engine.mode == mode ? Color.white.opacity(0.1) : Color.clear)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Timer Ring (with circular slider)

struct TimerRingView: View {
    @EnvironmentObject var engine: TimerEngine
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var lang: LanguageManager
    @State private var isDragging = false
    @State private var dragMinutes: Int = 0

    private var maxMinutes: Int {
        switch engine.mode {
        case .focus:      return 90
        case .shortBreak: return 30
        case .longBreak:  return 45
        }
    }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(isDragging ? 0.06 : 0.0), lineWidth: 18)
                    .animation(.easeInOut(duration: 0.15), value: isDragging)

                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 5)

                Circle()
                    .trim(from: 0, to: engine.progress)
                    .stroke(
                        theme.accentColor,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(isDragging ? .none : .linear(duration: 1), value: engine.progress)

                if !engine.isRunning {
                    let angle = engine.progress * 2 * .pi - .pi / 2
                    let r = (geo.size.width / 2) - 2.5
                    Circle()
                        .fill(theme.accentColor)
                        .frame(width: isDragging ? 11 : 8, height: isDragging ? 11 : 8)
                        .shadow(color: .white.opacity(0.4), radius: isDragging ? 4 : 0)
                        .offset(x: r * cos(angle), y: r * sin(angle))
                        .animation(.easeInOut(duration: 0.15), value: isDragging)
                }

                VStack(spacing: 5) {
                    if isDragging {
                        Text("\(dragMinutes)")
                            .font(.system(size: 40, weight: .thin, design: .monospaced))
                            .foregroundColor(.white)
                            .transition(.opacity)
                        Text("timer.minutes.label", bundle: lang.bundle)
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(2)
                    } else {
                        Text(engine.timeString)
                            .font(.system(size: 40, weight: .thin, design: .monospaced))
                            .foregroundColor(.white)
                            .monospacedDigit()
                            .transition(.opacity)
                        Text(LocalizedStringKey(engine.mode.locKey), bundle: lang.bundle)
                            .textCase(.uppercase)
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.white.opacity(engine.hasCustomDuration ? 0.6 : 0.35))
                            .tracking(2)
                    }
                }
                .animation(.easeInOut(duration: 0.12), value: isDragging)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard !engine.isRunning else { return }
                        let minutes = minutesFrom(location: value.location, center: center)
                        dragMinutes = minutes
                        engine.setDuration(minutes: minutes)
                        if !isDragging { isDragging = true }
                    }
                    .onEnded { _ in isDragging = false }
            )
        }
    }

    private func minutesFrom(location: CGPoint, center: CGPoint) -> Int {
        minutesFromAngle(
            dx: location.x - center.x,
            dy: location.y - center.y,
            maxMinutes: maxMinutes
        )
    }
}

// MARK: - Session Dots

struct SessionDotsView: View {
    @EnvironmentObject var engine: TimerEngine
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<4) { i in
                Circle()
                    .fill(i < engine.sessionsInCycle ? theme.accentColor : Color.white.opacity(0.15))
                    .frame(width: 6, height: 6)
                    .animation(.easeInOut(duration: 0.3), value: engine.sessionsInCycle)
            }
        }
    }
}

// MARK: - Streak Row

struct StreakRowView: View {
    @EnvironmentObject var streak: StreakManager
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 9))
                    .foregroundColor(streak.currentStreak > 0 ? theme.accentColor : .white.opacity(0.15))
                Text("\(streak.currentStreak)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(streak.currentStreak > 0 ? .white.opacity(0.7) : .white.opacity(0.2))
            }
            .scaleEffect(streak.streakMilestone != nil ? 1.15 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: streak.currentStreak)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.15))
                Text("\(streak.longestStreak)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.2))
            }
        }
    }
}

// MARK: - Control Buttons

struct ControlButtonsView: View {
    @EnvironmentObject var engine: TimerEngine
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        HStack(spacing: 14) {
            CircleButton(icon: "arrow.counterclockwise", size: 44, iconSize: 14,
                         foreground: .white.opacity(0.55), background: .white.opacity(0.07)) {
                engine.reset()
            }

            CircleButton(icon: engine.isRunning ? "pause.fill" : "play.fill",
                         size: 58, iconSize: 20, foreground: .black, background: theme.accentColor) {
                engine.toggle()
            }

            CircleButton(icon: "forward.end.fill", size: 44, iconSize: 14,
                         foreground: .white.opacity(0.55), background: .white.opacity(0.07)) {
                skipToNext()
            }
        }
    }

    private func skipToNext() {
        switch engine.mode {
        case .focus:
            engine.switchMode(engine.sessionsInCycle + 1 >= 4 ? .longBreak : .shortBreak)
        case .shortBreak, .longBreak:
            engine.switchMode(.focus)
        }
    }
}

struct CircleButton: View {
    let icon: String
    let size: CGFloat
    let iconSize: CGFloat
    let foreground: Color
    let background: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(foreground)
                .frame(width: size, height: size)
                .background(background)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preset Selector

struct PresetSelectorView: View {
    @EnvironmentObject var engine: TimerEngine
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        HStack(spacing: 6) {
            ForEach(TimerPreset.all, id: \.name) { preset in
                Button { engine.applyPreset(preset) } label: {
                    Text(verbatim: preset.name)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(isActive(preset) ? .white : .white.opacity(0.35))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isActive(preset) ? Color.white.opacity(0.12) : Color.clear)
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(isActive(preset) ? 0 : 0.1), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if engine.hasCustomDuration {
                Text("preset.custom", bundle: lang.bundle)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            } else {
                Text("\(engine.currentDurationMinutes)m")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.2))
            }
        }
    }

    private func isActive(_ preset: TimerPreset) -> Bool {
        engine.preset == preset && !engine.hasCustomDuration
    }
}

// MARK: - Theme Selector

struct ThemeSelectorView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        HStack(spacing: 8) {
            Text("theme.accent.label", bundle: lang.bundle)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white.opacity(0.2))
                .tracking(1.5)
            Spacer()
            HStack(spacing: 6) {
                ForEach(AccentColor.allCases) { accent in
                    Button {
                        theme.accent = accent
                    } label: {
                        Circle()
                            .fill(accent.color)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: theme.accent == accent ? 1.5 : 0)
                                    .padding(-2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Ambient Sound Selector

struct AmbientSelectorView: View {
    @EnvironmentObject var ambient: AmbientAudioEngine
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("ambient.label", bundle: lang.bundle)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.2))
                    .tracking(1.5)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(AmbientSound.all) { sound in
                        Button { ambient.select(sound) } label: {
                            Image(systemName: sound.icon)
                                .font(.system(size: 10))
                                .foregroundColor(
                                    ambient.current == sound
                                        ? theme.accentColor
                                        : .white.opacity(0.28)
                                )
                                .frame(width: 24, height: 24)
                                .background(
                                    ambient.current == sound
                                        ? Color.white.opacity(0.1)
                                        : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if ambient.current != nil {
                HStack(spacing: 6) {
                    Image(systemName: "speaker.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.2))
                    Slider(
                        value: Binding(
                            get: { Double(ambient.volume) },
                            set: { ambient.volume = Float($0) }
                        ),
                        in: 0...1
                    )
                    .tint(theme.accentColor)
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.2))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: ambient.current?.rawValue)
    }
}

// MARK: - Alarm Sound Selector

struct AlarmSelectorView: View {
    @EnvironmentObject var alarm: AlarmSoundManager
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        HStack(spacing: 8) {
            Text("alarm.label", bundle: lang.bundle)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white.opacity(0.2))
                .tracking(1.5)
            Spacer()
            HStack(spacing: 4) {
                ForEach(AlarmSound.allCases) { sound in
                    Button {
                        alarm.current = sound
                        sound.play()          // önizleme
                    } label: {
                        Text(verbatim: sound.rawValue)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(
                                alarm.current == sound ? .white : .white.opacity(0.28)
                            )
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                alarm.current == sound
                                    ? Color.white.opacity(0.12)
                                    : Color.clear
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Language Selector

struct LanguageSelectorView: View {
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        HStack(spacing: 8) {
            Text("settings.language.label", bundle: lang.bundle)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white.opacity(0.2))
                .tracking(1.5)
            Spacer()
            HStack(spacing: 4) {
                ForEach(LanguageManager.supported) { language in
                    Button {
                        lang.setLanguage(language)
                    } label: {
                        Text(verbatim: language.label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(lang.currentLanguage == language ? .white : .white.opacity(0.28))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(lang.currentLanguage == language
                                ? Color.white.opacity(0.12)
                                : Color.clear)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Quit Button

struct QuitButtonView: View {
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        Button { NSApplication.shared.terminate(nil) } label: {
            Text("app.quit", bundle: lang.bundle)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.25))
        }
        .buttonStyle(.plain)
    }
}
