import SwiftUI
import MoirasiaUI

enum SemiquaverLayoutMode: Sendable {
    case compact
    case expanded

    var artworkSize: CGFloat { self == .compact ? 52 : 44 }
    var rowHeight: CGFloat { self == .compact ? 68 : 54 }
    var contentPadding: CGFloat { self == .compact ? 16 : 20 }
    var playerHeight: CGFloat { self == .compact ? 68 : 72 }
}

// View-layer presentation built on the shared Moira tokens. All colors,
// type, spacing, radii, and motion resolve through MoirasiaUI.
struct SurfaceCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: MoiraRadius.panel, style: .continuous)
                .fill(MoiraColor.surface)
                .overlay(RoundedRectangle(cornerRadius: MoiraRadius.panel, style: .continuous)
                    .stroke(MoiraColor.border, lineWidth: 0.5))
        )
    }
}

struct PressScaleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: MoiraMotion.normal), value: configuration.isPressed)
    }
}

enum AppTheme: String, CaseIterable {
    case automatic = "Automatic"
    case dark = "Dark"
    case light = "Light"

    var displayName: String { rawValue }
    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: nil
        case .dark: .dark
        case .light: .light
        }
    }
}