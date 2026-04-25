import SwiftUI

struct PlayerBackground: View {
    var body: some View {
        ZStack {
            Color.playerBackground
                .ignoresSafeArea()

            // Uniform, non-ambient top glow — same on every screen
            GeometryReader { geo in
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.playerAmbient1.opacity(0.4),
                        Color.clear
                    ]),
                    center: .top,
                    startRadius: 0,
                    endRadius: geo.size.width * 0.6
                )
                .offset(y: geo.size.height * 0.08)
                .blur(radius: 60)
                .ignoresSafeArea()
            }
        }
    }
}
