import AppKit
import SwiftUI
import TimerCore

// MARK: - Controller

@MainActor
final class FloatingTimerController {
    static let shared = FloatingTimerController()
    private var panel: NSPanel?

    var isVisible: Bool { panel?.isVisible ?? false }

    func toggle(engine: TimerEngine, theme: ThemeManager, lang: LanguageManager) {
        if let panel, panel.isVisible {
            panel.orderOut(nil)
        } else {
            show(engine: engine, theme: theme, lang: lang)
        }
    }

    private func show(engine: TimerEngine, theme: ThemeManager, lang: LanguageManager) {
        if panel == nil { createPanel(engine: engine, theme: theme, lang: lang) }
        panel?.orderFront(nil)
    }

    private func createPanel(engine: TimerEngine, theme: ThemeManager, lang: LanguageManager) {
        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 72),
            styleMask: [.nonactivatingPanel, .hudWindow, .titled, .closable],
            backing: .buffered,
            defer: true
        )
        p.title = "FocusTimer"
        p.level = .floating
        p.isMovableByWindowBackground = true
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        p.hidesOnDeactivate = false

        p.contentView = NSHostingView(
            rootView: FloatingTimerView()
                .environmentObject(engine)
                .environmentObject(theme)
                .environmentObject(lang)
        )

        if let screen = NSScreen.main {
            p.setFrameOrigin(NSPoint(
                x: screen.visibleFrame.maxX - 220,
                y: screen.visibleFrame.maxY - 100
            ))
        }

        panel = p
    }
}

// MARK: - Floating View

struct FloatingTimerView: View {
    @EnvironmentObject var engine: TimerEngine
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        HStack(spacing: 12) {
            // Mini progress ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 2.5)
                Circle()
                    .trim(from: 0, to: engine.progress)
                    .stroke(
                        theme.accentColor,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: engine.progress)
            }
            .frame(width: 36, height: 36)
            .opacity(engine.isRunning ? 1.0 : 0.55)

            VStack(alignment: .leading, spacing: 2) {
                Text(engine.timeString)
                    .font(.system(size: 22, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)
                    .monospacedDigit()
                Text(LocalizedStringKey(engine.mode.locKey), bundle: lang.bundle)
                    .textCase(.uppercase)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)
            }

            Spacer()

            Button { engine.toggle() } label: {
                Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.accentColor)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(red: 0.07, green: 0.07, blue: 0.07))
    }
}
