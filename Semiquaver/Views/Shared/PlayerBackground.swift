import SwiftUI
import Combine

private final class SharedAnimationState: ObservableObject {
    static let shared = SharedAnimationState()
    @Published private(set) var animateGradient = false
    private var subscriptions: Set<AnyCancellable> = []

    init() {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                self.animateGradient = true
            }
        }
    }
}

struct PlayerBackground: View {
    @StateObject private var state = SharedAnimationState.shared

    var body: some View {
        ZStack {
            Color.playerBackground
                .ignoresSafeArea()

            GeometryReader { geo in
                let animate = state.animateGradient
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
                            x: animate ? geo.size.width * 0.2 : -geo.size.width * 0.2,
                            y: animate ? -geo.size.height * 0.3 : -geo.size.height * 0.1
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
                            x: animate ? -geo.size.width * 0.3 : geo.size.width * 0.1,
                            y: animate ? geo.size.height * 0.3 : geo.size.height * 0.1
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
                            x: animate ? geo.size.width * 0.1 : -geo.size.width * 0.3,
                            y: animate ? geo.size.height * 0.1 : geo.size.height * 0.4
                        )
                        .blur(radius: 50)
                }
            }
        }
    }
}
