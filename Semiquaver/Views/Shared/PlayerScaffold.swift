import SwiftUI

struct PlayerScaffold<Content: View>: View {
    let title: String
    var trailingSystemImage: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            PlayerBackground()

            VStack(spacing: 0) {
                header
                Divider()
                    .overlay(Color.playerDivider)
                content()
            }
        }
    }

    private var header: some View {
        ZStack {
            Text(title)
                .font(.system(size: 43, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)

            HStack {
                Spacer()
                if let trailingSystemImage {
                    Button {
                    } label: {
                        Image(systemName: trailingSystemImage)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(Color.playerAccent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.trailing, 18)
        }
        .padding(.top, 10)
        .padding(.bottom, 14)
    }
}
