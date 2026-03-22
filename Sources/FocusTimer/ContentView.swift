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
    @State private var showSettings = false
    @State private var showTasks = false
    @State private var showDevAssistant = false
    @ObservedObject private var floatingController = FloatingTimerController.shared
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        VStack(spacing: 0) {
            // Header toolbar
            HStack(spacing: 6) {
                Text("FocusTimer")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
                Spacer()

                toolbarButton(icon: floatingController.isVisible ? "pip.fill" : "pip",
                              isActive: floatingController.isVisible) {
                    floatingController.toggle(engine: engine, theme: theme, lang: lang)
                }
                toolbarButton(icon: "chart.bar.fill", isActive: showHistory) {
                    showHistory.toggle()
                    if showHistory { showSettings = false; showTasks = false; showDevAssistant = false }
                }
                toolbarButton(icon: showTasks ? "checklist.checked" : "checklist", isActive: showTasks) {
                    showTasks.toggle()
                    if showTasks { showHistory = false; showSettings = false; showDevAssistant = false }
                }
                toolbarButton(icon: showSettings ? "gearshape.fill" : "gearshape", isActive: showSettings) {
                    showSettings.toggle()
                    if showSettings { showHistory = false; showTasks = false; showDevAssistant = false }
                }
                toolbarButton(icon: showDevAssistant ? "wrench.and.screwdriver.fill" : "wrench.and.screwdriver",
                              isActive: showDevAssistant) {
                    showDevAssistant.toggle()
                    if showDevAssistant { showHistory = false; showSettings = false; showTasks = false }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

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
            } else if showSettings {
                SettingsView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            } else if showTasks {
                DailyTaskView()
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
        .glassContainer()
        .animation(.easeInOut(duration: 0.22), value: showHistory)
        .animation(.easeInOut(duration: 0.22), value: showSettings)
        .animation(.easeInOut(duration: 0.22), value: showTasks)
        .animation(.easeInOut(duration: 0.22), value: showDevAssistant)
        .onAppear {
            observeCompletion()
            streak.validateStreak()
        }
    }

    private func toolbarButton(icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(isActive ? .primary : .tertiary)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var timerBody: some View {
        ModeSelectorView()
            .padding(.horizontal, 16)

        TimerRingView()
            .frame(width: 164, height: 164)
            .padding(.top, 24)

        SessionDotsView()
            .padding(.top, 16)

        StreakRowView()
            .padding(.top, 12)
            .padding(.horizontal, 16)

        ControlButtonsView()
            .padding(.top, 22)
            .padding(.bottom, 16)

        BreakSuggestionView()
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .animation(.easeInOut(duration: 0.25), value: engine.completedSessions)
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
        guard Bundle.main.bundleURL.pathExtension == "app" else { return }

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

// MARK: - Mode Selector (native Picker)

struct ModeSelectorView: View {
    @EnvironmentObject var engine: TimerEngine
    @EnvironmentObject var lang: LanguageManager

    @State private var selectedMode: TimerMode = .focus

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimerMode.allCases, id: \.self) { mode in
                Button {
                    selectedMode = mode
                } label: {
                    Text(LocalizedStringKey(mode.shortLocKey), bundle: lang.bundle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(selectedMode == mode ? .primary : .tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .glassCapsule(isActive: selectedMode == mode, fallback: Color.primary.opacity(0.1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .glassRoundedRect(cornerRadius: 8)
        .onAppear { selectedMode = engine.mode }
        .onChange(of: engine.mode) { _, newValue in selectedMode = newValue }
        .onChange(of: selectedMode) { _, newValue in
            guard newValue != engine.mode else { return }
            engine.switchMode(newValue)
        }
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
                    .stroke(Color.primary.opacity(isDragging ? 0.06 : 0.0), lineWidth: 18)
                    .animation(.easeInOut(duration: 0.15), value: isDragging)

                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 5)

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
                        .shadow(color: theme.accentColor.opacity(0.4), radius: isDragging ? 4 : 0)
                        .offset(x: r * cos(angle), y: r * sin(angle))
                        .animation(.easeInOut(duration: 0.15), value: isDragging)
                }

                VStack(spacing: 5) {
                    if isDragging {
                        Text("\(dragMinutes)")
                            .font(.system(size: 40, weight: .thin, design: .monospaced))
                            .foregroundStyle(.primary)
                            .transition(.opacity)
                        Text("timer.minutes.label", bundle: lang.bundle)
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .tracking(2)
                    } else {
                        Text(engine.timeString)
                            .font(.system(size: 40, weight: .thin, design: .monospaced))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                            .transition(.opacity)
                        Text(LocalizedStringKey(engine.mode.locKey), bundle: lang.bundle)
                            .textCase(.uppercase)
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(engine.hasCustomDuration ? .secondary : .tertiary)
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
                    .fill(i < engine.sessionsInCycle ? theme.accentColor : Color.primary.opacity(0.15))
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
                    .foregroundColor(streak.currentStreak > 0 ? theme.accentColor : .gray.opacity(0.4))
                Text("\(streak.currentStreak)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(streak.currentStreak > 0 ? .secondary : .quaternary)
            }
            .scaleEffect(streak.streakMilestone != nil ? 1.15 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: streak.currentStreak)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.quaternary)
                Text("\(streak.longestStreak)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.quaternary)
            }
        }
    }
}

// MARK: - Control Buttons

struct ControlButtonsView: View {
    @EnvironmentObject var engine: TimerEngine
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        controlButtons
    }

    private var controlButtons: some View {
        HStack(spacing: 14) {
            Button { engine.reset() } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .glassInteractiveCircle()
            }
            .buttonStyle(.plain)

            Button { engine.toggle() } label: {
                Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 58, height: 58)
                    .glassInteractiveCircle()
            }
            .buttonStyle(.plain)
            .tint(theme.accentColor)

            Button { skipToNext() } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .glassInteractiveCircle()
            }
            .buttonStyle(.plain)
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
                }
                .buttonStyle(.plain)
                .foregroundStyle(isActive(preset) ? .primary : .tertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .glassCapsule(isActive: isActive(preset), fallback: Color.primary.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(isActive(preset) ? 0 : 0.1), lineWidth: 1)
                )
            }

            Spacer()

            if engine.hasCustomDuration {
                Text("preset.custom", bundle: lang.bundle)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .glassCapsule(fallback: Color.primary.opacity(0.08))
            } else {
                Text("\(engine.currentDurationMinutes)m")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.quaternary)
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
                .foregroundStyle(.quaternary)
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
                                    .stroke(Color.primary, lineWidth: theme.accent == accent ? 1.5 : 0)
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
                    .foregroundStyle(.quaternary)
                    .tracking(1.5)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(AmbientSound.all) { sound in
                        Button { ambient.select(sound) } label: {
                            Image(systemName: sound.icon)
                                .font(.system(size: 10))
                                .foregroundStyle(ambient.current == sound ? AnyShapeStyle(theme.accentColor) : AnyShapeStyle(.tertiary))
                                .frame(width: 24, height: 24)
                                .glassRoundedRect(
                                    cornerRadius: 5,
                                    fallback: ambient.current == sound
                                        ? Color.primary.opacity(0.1)
                                        : Color.clear
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if ambient.current != nil {
                HStack(spacing: 6) {
                    Image(systemName: "speaker.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.quaternary)
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
                        .foregroundStyle(.quaternary)
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
                .foregroundStyle(.quaternary)
                .tracking(1.5)
            Spacer()
            HStack(spacing: 4) {
                ForEach(AlarmSound.allCases) { sound in
                    Button {
                        alarm.current = sound
                        sound.play()
                    } label: {
                        Text(verbatim: sound.rawValue)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(alarm.current == sound ? .primary : .tertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .glassCapsule(
                                isActive: alarm.current == sound,
                                fallback: Color.primary.opacity(0.12)
                            )
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
                .foregroundStyle(.quaternary)
                .tracking(1.5)
            Spacer()
            HStack(spacing: 4) {
                ForEach(LanguageManager.supported) { language in
                    Button {
                        lang.setLanguage(language)
                    } label: {
                        Text(verbatim: language.label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(lang.currentLanguage == language ? .primary : .tertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .glassCapsule(
                                isActive: lang.currentLanguage == language,
                                fallback: Color.primary.opacity(0.12)
                            )
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
                .foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
    }
}
