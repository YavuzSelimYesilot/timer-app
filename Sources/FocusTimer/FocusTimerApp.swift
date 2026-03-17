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

    var body: some View {
        if engine.isRunning {
            Text(engine.timeString)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .monospacedDigit()
        } else {
            Image(systemName: "timer")
                .symbolRenderingMode(.hierarchical)
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
