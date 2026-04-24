import SwiftUI

struct PlayerScaffold<Content: View>: View {
    let title: String
    var trailingSystemImage: String? = nil
    var trailingAction: (() -> Void)? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            PlayerBackground()

            VStack(spacing: 0) {
                header
                
                content()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.display())
                .foregroundStyle(Color.playerTextPrimary)
            
            Spacer()
            
            if let trailingSystemImage {
                if let trailingAction {
                    Button(action: trailingAction) {
                        Image(systemName: trailingSystemImage)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.playerAccent)
                            .frame(width: 40, height: 40)
                            .background(Color.playerGlass)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.playerGlassBorder, lineWidth: 0.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(PressScaleButtonStyle())
                } else {
                    Image(systemName: trailingSystemImage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.playerAccent)
                        .frame(width: 40, height: 40)
                        .background(Color.playerGlass)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.playerGlassBorder, lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }
}
