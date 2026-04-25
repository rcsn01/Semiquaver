import SwiftUI

struct MediaRow: View {
    let item: MediaItem
    var showsChevron = false
    var trailingSystemImage: String? = nil
    var isHighlighted = false

    var body: some View {
        HStack(spacing: 14) {
            artworkView

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.bodyMedium())
                    .foregroundStyle(Color.playerTextPrimary)
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(.caption())
                    .foregroundStyle(Color.playerTextSecondary)
                    .lineLimit(1)
            }

            Spacer()

            if let trailingSystemImage {
                Image(systemName: trailingSystemImage)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.playerAccent)
                    .frame(width: 28, height: 28)
            } else if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.playerTextTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isHighlighted ? Color.playerAccent.opacity(0.06) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var artworkView: some View {
        if let artworkData = item.artworkData,
           let artwork = UIImage(data: artworkData) {
            Image(uiImage: artwork)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .modifier(GlowModifier(color: Color.clear, radius: 0))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: item.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .modifier(GlowModifier(color: item.colors.first ?? .clear, radius: 12))

                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
    }
}
