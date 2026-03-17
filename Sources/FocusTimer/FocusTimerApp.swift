import SwiftUI
import SwiftData
import AppKit
import UserNotifications
import TimerCore

@main
struct FocusTimerApp: App {

    @StateObject private var engine = TimerEngine()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(engine)
        } label: {
            MenuBarLabel(engine: engine)
        }
        .menuBarExtraStyle(.window)
        .modelContainer(for: FocusSession.self)
    }
}

// MARK: - Menu Bar Label

struct MenuBarLabel: View {
    @ObservedObject var engine: TimerEngine

    private var modeSystemImage: String {
        switch engine.mode {
        case .focus:      return "flame.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak:  return "moon.zzz.fill"
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: modeSystemImage)
                .symbolRenderingMode(.hierarchical)
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
