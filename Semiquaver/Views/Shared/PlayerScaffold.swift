import SwiftUI
import MoirasiaUI

struct PlayerScaffold<Content: View>: View {
    let title: String
    var trailingSystemImage: String? = nil
    var trailingAction: (() -> Void)? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            MoiraColor.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                content()
            }
        }
    }

    private var header: some View {
        HStack(spacing: MoiraSpace.x3) {
            Text(title)
                .font(Font.system(.largeTitle, design: .default).weight(.bold))
                .foregroundStyle(MoiraColor.textPrimary)

            Spacer()

            if let trailingSystemImage {
                if let trailingAction {
                    Button(action: trailingAction) {
                        Image(systemName: trailingSystemImage)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(MoiraColor.textPrimary)
                            .frame(width: 40, height: 40)
                            .background(MoiraColor.control)
                            .overlay(
                                RoundedRectangle(cornerRadius: MoiraRadius.control, style: .continuous)
                                    .stroke(MoiraColor.border, lineWidth: 0.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: MoiraRadius.control, style: .continuous))
                    }
                    .buttonStyle(PressScaleButtonStyle())
                } else {
                    Image(systemName: trailingSystemImage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MoiraColor.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(MoiraColor.control)
                        .overlay(
                            RoundedRectangle(cornerRadius: MoiraRadius.control, style: .continuous)
                                .stroke(MoiraColor.border, lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: MoiraRadius.control, style: .continuous))
                }
            }
        }
        .padding(.horizontal, MoiraSpace.x5)
        .padding(.top, MoiraSpace.x3)
        .padding(.bottom, MoiraSpace.x4)
    }
}