import SwiftUI

struct MediaRow: View {
    let item: MediaItem
    var showsChevron = false

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: item.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 58, height: 58)
                .overlay {
                    Image(systemName: item.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.playerTextSecondary)
                    .lineLimit(1)
            }

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.playerAccent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
