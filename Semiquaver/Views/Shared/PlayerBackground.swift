import SwiftUI

struct PlayerBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.playerSurfaceTop, Color.playerSurfaceBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.playerAccent.opacity(0.13))
                .frame(width: 230)
                .blur(radius: 80)
                .offset(x: 170, y: -360)

            Circle()
                .fill(Color.blue.opacity(0.07))
                .frame(width: 300)
                .blur(radius: 90)
                .offset(x: -210, y: 260)
        }
    }
}
