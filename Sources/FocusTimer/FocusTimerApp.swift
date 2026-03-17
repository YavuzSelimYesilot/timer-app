import SwiftUI
import SwiftData
import AppKit
import UserNotifications
import TimerCore

@main
struct FocusTimerApp: App {

    @StateObject private var engine  = TimerEngine()
    @StateObject private var theme   = ThemeManager()
    @StateObject private var lang    = LanguageManager()
    @StateObject private var ambient = AmbientAudioEngine()
    @StateObject private var alarm   = AlarmSoundManager()
    @StateObject private var streak  = StreakManager()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(engine)
                .environmentObject(theme)
                .environmentObject(lang)
                .environmentObject(ambient)
                .environmentObject(alarm)
                .environmentObject(streak)
        } label: {
            MenuBarLabel(engine: engine, theme: theme)
        }
        .menuBarExtraStyle(.window)
        .modelContainer(for: FocusSession.self)
    }
}

// MARK: - Menu Bar Label (with progress ring)

struct MenuBarLabel: View {
    @ObservedObject var engine: TimerEngine
    @ObservedObject var theme: ThemeManager

    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.22), lineWidth: 1.5)
                    .frame(width: 14, height: 14)

                Circle()
                    .trim(from: 0, to: engine.progress)
                    .stroke(
                        theme.accentColor,
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                    )
                    .frame(width: 14, height: 14)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: engine.progress)
            }
            .opacity(engine.isRunning ? 1.0 : 0.5)

            Text(engine.timeString)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .monospacedDigit()
                .opacity(engine.isRunning ? 1.0 : 0.6)
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
