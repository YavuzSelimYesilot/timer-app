import SwiftUI
import AppKit
import Combine
import UserNotifications
import TimerCore

// MARK: - Root View

struct ContentView: View {
    @EnvironmentObject var engine: TimerEngine
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        VStack(spacing: 0) {
            ModeSelectorView()
                .padding(.top, 20)
                .padding(.horizontal, 20)

            TimerRingView()
                .frame(width: 164, height: 164)
                .padding(.top, 28)

            SessionDotsView()
                .padding(.top, 18)

            ControlButtonsView()
                .padding(.top, 24)

            PresetSelectorView()
                .padding(.top, 18)
                .padding(.bottom, 22)
                .padding(.horizontal, 20)

            Divider()
                .background(Color.white.opacity(0.06))

            QuitButtonView()
                .padding(.vertical, 10)
        }
        .frame(width: 280)
        .background(Color(red: 0.07, green: 0.07, blue: 0.07))
        .onAppear { observeCompletion() }
    }

    private func observeCompletion() {
        engine.completionPublisher
            .receive(on: DispatchQueue.main)
            .sink { completedMode in
                playCompletionSound()
                sendNotification(for: completedMode, nextSessions: engine.completedSessions)
            }
            .store(in: &cancellables)
    }

    private func playCompletionSound() {
        NSSound(named: "Glass")?.play()
    }

    private func sendNotification(for mode: TimerMode, nextSessions: Int) {
        let content = UNMutableNotificationContent()
        switch mode {
        case .focus:
            content.title = "Session complete"
            content.body  = nextSessions % 4 == 0 ? "Take a long break, you earned it." : "Short break time."
        case .shortBreak:
            content.title = "Break over"
            content.body  = "Back to work."
        case .longBreak:
            content.title = "Long break over"
            content.body  = "Ready to focus?"
        }
        content.sound = .default
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }
}

// MARK: - Mode Selector

struct ModeSelectorView: View {
    @EnvironmentObject var engine: TimerEngine

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimerMode.allCases, id: \.self) { mode in
                Button { engine.switchMode(mode) } label: {
                    Text(mode.shortTitle)
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

// MARK: - Timer Ring

struct TimerRingView: View {
    @EnvironmentObject var engine: TimerEngine

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 5)

            // Progress
            Circle()
                .trim(from: 0, to: engine.progress)
                .stroke(
                    Color.white,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: engine.progress)

            // Time + label
            VStack(spacing: 5) {
                Text(engine.timeString)
                    .font(.system(size: 40, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text(engine.mode.rawValue.uppercased())
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(2)
            }
        }
    }
}

// MARK: - Session Dots

struct SessionDotsView: View {
    @EnvironmentObject var engine: TimerEngine

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<4) { i in
                Circle()
                    .fill(i < engine.sessionsInCycle ? Color.white : Color.white.opacity(0.15))
                    .frame(width: 6, height: 6)
                    .animation(.easeInOut(duration: 0.3), value: engine.sessionsInCycle)
            }
        }
    }
}

// MARK: - Control Buttons

struct ControlButtonsView: View {
    @EnvironmentObject var engine: TimerEngine

    var body: some View {
        HStack(spacing: 14) {
            // Reset
            CircleButton(
                icon: "arrow.counterclockwise",
                size: 44,
                iconSize: 14,
                foreground: .white.opacity(0.55),
                background: .white.opacity(0.07)
            ) {
                engine.reset()
            }

            // Play / Pause
            CircleButton(
                icon: engine.isRunning ? "pause.fill" : "play.fill",
                size: 58,
                iconSize: 20,
                foreground: .black,
                background: .white
            ) {
                engine.toggle()
            }

            // Skip
            CircleButton(
                icon: "forward.end.fill",
                size: 44,
                iconSize: 14,
                foreground: .white.opacity(0.55),
                background: .white.opacity(0.07)
            ) {
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

    var body: some View {
        HStack(spacing: 6) {
            ForEach(TimerPreset.all, id: \.name) { preset in
                Button { engine.applyPreset(preset) } label: {
                    Text(preset.name)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(engine.preset == preset ? .white : .white.opacity(0.35))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(engine.preset == preset ? Color.white.opacity(0.12) : Color.clear)
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(engine.preset == preset ? 0 : 0.1), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Total time indicator
            Text("\(engine.preset.focus)m")
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.white.opacity(0.2))
        }
    }
}

// MARK: - Quit Button

struct QuitButtonView: View {
    var body: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Text("Quit FocusTimer")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.25))
        }
        .buttonStyle(.plain)
    }
}
