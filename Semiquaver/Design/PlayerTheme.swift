import SwiftUI

enum SemiquaverLayoutMode: Sendable {
    case compact
    case expanded

    var artworkSize: CGFloat { self == .compact ? 52 : 44 }
    var rowHeight: CGFloat { self == .compact ? 68 : 54 }
    var contentPadding: CGFloat { self == .compact ? 16 : 20 }
    var playerHeight: CGFloat { self == .compact ? 68 : 72 }
}

enum SemiquaverMetrics {
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16
    static let spacingXL: CGFloat = 24
    static let rowCornerRadius: CGFloat = 12
    static let artworkCornerRadius: CGFloat = 10
    static let cardCornerRadius: CGFloat = 20
    static let quickAnimation = 0.18
    static let standardAnimation = 0.28
}

// Platform-neutral design tokens shared by the iOS and macOS targets.
extension Color {
    static let playerBackground = Color.primary.opacity(0.035)
    static let playerSurface = Color.primary.opacity(0.025)
    static let playerSurfaceElevated = Color.primary.opacity(0.055)
    static let playerAccent = Color(red: 0.98, green: 0.14, blue: 0.20)
    static let playerAccentMuted = playerAccent.opacity(0.3)
    static let playerTextPrimary = Color.primary
    static let playerTextSecondary = Color.secondary
    static let playerTextTertiary = Color.secondary.opacity(0.62)
    static let playerTextInverse = Color.white
    static let playerDivider = Color.primary.opacity(0.08)
    static let playerGlass = Color.primary.opacity(0.04)
    static let playerGlassBorder = Color.primary.opacity(0.10)
    static let playerAmbient1 = playerAccent.opacity(0.08)
    static let playerAmbient2 = Color.blue.opacity(0.05)
    static let playerAmbient3 = Color.purple.opacity(0.035)
    static let playerShadow = Color.black.opacity(0.20)
    static let playerArtworkIcon = Color.white.opacity(0.9)
    static let playerArtworkShadow = Color.black.opacity(0.25)
}

extension Font {
    static func display() -> Font { .system(size: 32, weight: .bold, design: .rounded) }
    static func heading() -> Font { .system(size: 20, weight: .bold, design: .rounded) }
    static func bodyMedium() -> Font { .system(size: 16, weight: .semibold, design: .rounded) }
    static func bodyRegular() -> Font { .system(size: 15, weight: .medium) }
    static func caption() -> Font { .system(size: 13, weight: .medium) }
    static func captionSmall() -> Font { .system(size: 11, weight: .semibold) }
}

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.playerGlass)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.playerGlassBorder, lineWidth: 0.5))
        )
    }
}

struct PressScaleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: SemiquaverMetrics.quickAnimation), value: configuration.isPressed)
    }
}

struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content.shadow(color: color.opacity(0.15), radius: radius)
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
