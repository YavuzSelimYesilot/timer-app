import SwiftUI
import AppKit
import Combine
import UserNotifications
import TimerCore

@main
struct FocusTimerApp: App {

    @StateObject private var engine = TimerEngine()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private var cancellables = Set<AnyCancellable>()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(engine)
        } label: {
            MenuBarLabel(engine: engine)
        }
        .menuBarExtraStyle(.window)
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

    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon — this is a menu bar-only app
        NSApp.setActivationPolicy(.accessory)

        // Request notification permission
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
