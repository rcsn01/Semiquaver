import SwiftUI

extension Color {
    static let playerBackground = Color(red: 0.05, green: 0.05, blue: 0.06)
    static let playerSurface = Color(red: 0.08, green: 0.08, blue: 0.10)
    static let playerSurfaceElevated = Color(red: 0.11, green: 0.11, blue: 0.14)
    static let playerAccent = Color(red: 1.0, green: 0.70, blue: 0.20)
    static let playerAccentMuted = Color(red: 1.0, green: 0.70, blue: 0.20).opacity(0.3)
    static let playerTextPrimary = Color.white
    static let playerTextSecondary = Color.white.opacity(0.50)
    static let playerTextTertiary = Color.white.opacity(0.30)
    static let playerDivider = Color.white.opacity(0.06)
    static let playerGlass = Color.white.opacity(0.03)
    static let playerGlassBorder = Color.white.opacity(0.08)
}

extension Font {
    static func display() -> Font {
        .system(size: 32, weight: .bold, design: .rounded)
    }
    
    static func heading() -> Font {
        .system(size: 20, weight: .bold, design: .rounded)
    }
    
    static func bodyMedium() -> Font {
        .system(size: 16, weight: .semibold, design: .rounded)
    }
    
    static func bodyRegular() -> Font {
        .system(size: 15, weight: .medium, design: .default)
    }
    
    static func caption() -> Font {
        .system(size: 13, weight: .medium, design: .default)
    }
    
    static func captionSmall() -> Font {
        .system(size: 11, weight: .semibold, design: .default)
    }
}

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.playerGlass)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.playerGlassBorder, lineWidth: 0.5)
                    )
            )
    }
}

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.15), radius: radius, x: 0, y: 0)
    }
}
