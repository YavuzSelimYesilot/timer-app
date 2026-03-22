import SwiftUI

// MARK: - Liquid Glass Helpers (macOS 26+)

extension View {

    /// Container-level glass: transparent on macOS 26, opaque dark on older.
    @ViewBuilder
    func glassContainer() -> some View {
        if #available(macOS 26, *) {
            self.background(.clear)
                .containerBackground(.clear, for: .window)
        } else {
            self.background(Color(red: 0.07, green: 0.07, blue: 0.07))
        }
    }

    /// Capsule glass — for pills, tags, preset selectors.
    @ViewBuilder
    func glassCapsule(isActive: Bool = true, fallback: Color = Color.primary.opacity(0.12)) -> some View {
        if #available(macOS 26, *) {
            if isActive {
                self.glassEffect(.regular, in: .capsule)
            } else {
                self
            }
        } else {
            if isActive {
                self.background(fallback).clipShape(Capsule())
            } else {
                self
            }
        }
    }

    /// Circle glass — for round buttons.
    @ViewBuilder
    func glassCircle(fallback: Color = Color.primary.opacity(0.07)) -> some View {
        if #available(macOS 26, *) {
            self.glassEffect(.regular, in: .circle)
        } else {
            self.background(fallback).clipShape(Circle())
        }
    }

    /// Rounded rect glass — for cards, input fields, segmented controls.
    @ViewBuilder
    func glassRoundedRect(cornerRadius: CGFloat = 8, fallback: Color = Color.primary.opacity(0.05)) -> some View {
        if #available(macOS 26, *) {
            self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            self.background(fallback).clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }

    /// Interactive glass circle — for buttons that need press feedback.
    @ViewBuilder
    func glassInteractiveCircle(fallback: Color = Color.primary.opacity(0.07)) -> some View {
        if #available(macOS 26, *) {
            self.glassEffect(.regular.interactive(), in: .circle)
        } else {
            self.background(fallback).clipShape(Circle())
        }
    }
}
