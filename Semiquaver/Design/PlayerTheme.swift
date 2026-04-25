import SwiftUI
import UIKit

// MARK: - Design Token System
///
/// Semantic color tokens that automatically adapt to the current interface style
/// (light / dark mode). Use `Color.player*` anywhere in SwiftUI views – no
/// environment reads or if/else required.
///
extension Color {

    // MARK: Background

    static var playerBackground: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1)
                : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
        })
    }

    static var playerSurface: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1)
                : UIColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1)
        })
    }

    static var playerSurfaceElevated: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.11, blue: 0.14, alpha: 1)
                : UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1)
        })
    }

    // MARK: Accent

    static let playerAccent = Color(red: 0.98, green: 0.14, blue: 0.20)

    static var playerAccentMuted: Color {
        playerAccent.opacity(0.3)
    }

    // MARK: Text

    static var playerTextPrimary: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: 1.0)
                : UIColor(white: 0.0, alpha: 1.0)
        })
    }

    static var playerTextSecondary: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: 0.50)
                : UIColor(white: 0.0, alpha: 0.50)
        })
    }

    static var playerTextTertiary: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: 0.30)
                : UIColor(white: 0.0, alpha: 0.30)
        })
    }

    static var playerTextInverse: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.0, alpha: 1.0)
                : UIColor(white: 1.0, alpha: 1.0)
        })
    }

    // MARK: Utility

    static var playerDivider: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: 0.06)
                : UIColor(white: 0.0, alpha: 0.06)
        })
    }

    static var playerGlass: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: 0.03)
                : UIColor(white: 0.0, alpha: 0.03)
        })
    }

    static var playerGlassBorder: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: 0.08)
                : UIColor(white: 0.0, alpha: 0.08)
        })
    }

    // MARK: Ambient (decorative background gradients)

    static var playerAmbient1: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.98, green: 0.14, blue: 0.20, alpha: 0.10)
                : UIColor(red: 0.98, green: 0.14, blue: 0.20, alpha: 0.06)
        })
    }

    static var playerAmbient2: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.20, green: 0.40, blue: 1.00, alpha: 0.06)
                : UIColor(red: 0.20, green: 0.40, blue: 1.00, alpha: 0.04)
        })
    }

    static var playerAmbient3: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.60, green: 0.30, blue: 0.90, alpha: 0.04)
                : UIColor(red: 0.60, green: 0.30, blue: 0.90, alpha: 0.03)
        })
    }

    // MARK: Shadow

    static var playerShadow: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.0, alpha: 0.40)
                : UIColor(white: 0.0, alpha: 0.15)
        })
    }

    // MARK: Icon / Artwork fallback

    static var playerArtworkIcon: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: 0.75)
                : UIColor(white: 1.0, alpha: 0.90)
        })
    }

    static var playerArtworkShadow: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.0, alpha: 0.30)
                : UIColor(white: 0.0, alpha: 0.20)
        })
    }
}

// MARK: - Typography

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

// MARK: - View Modifiers

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

// MARK: - App Theme

enum AppTheme: String, CaseIterable {
    case automatic = "Automatic"
    case dark = "Dark"
    case light = "Light"

    var displayName: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}
