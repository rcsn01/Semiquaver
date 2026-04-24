import SwiftUI

struct PlayerBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            Color.playerBackground
                .ignoresSafeArea()
            
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.playerAccent.opacity(0.10),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: geo.size.width * 0.4
                            )
                        )
                        .frame(width: geo.size.width * 0.8)
                        .offset(
                            x: animateGradient ? geo.size.width * 0.2 : -geo.size.width * 0.2,
                            y: animateGradient ? -geo.size.height * 0.3 : -geo.size.height * 0.1
                        )
                        .blur(radius: 60)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.06),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: geo.size.width * 0.5
                            )
                        )
                        .frame(width: geo.size.width)
                        .offset(
                            x: animateGradient ? -geo.size.width * 0.3 : geo.size.width * 0.1,
                            y: animateGradient ? geo.size.height * 0.3 : geo.size.height * 0.1
                        )
                        .blur(radius: 70)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.purple.opacity(0.04),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: geo.size.width * 0.3
                            )
                        )
                        .frame(width: geo.size.width * 0.6)
                        .offset(
                            x: animateGradient ? geo.size.width * 0.1 : -geo.size.width * 0.3,
                            y: animateGradient ? geo.size.height * 0.1 : geo.size.height * 0.4
                        )
                        .blur(radius: 50)
                }
                .animation(
                    .easeInOut(duration: 12).repeatForever(autoreverses: true),
                    value: animateGradient
                )
                .onAppear {
                    animateGradient = true
                }
            }
        }
    }
}
