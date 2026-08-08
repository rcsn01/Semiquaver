import SwiftUI

struct MediaRow: View {
    let item: MediaItem
    var showsChevron = false
    var trailingSystemImage: String? = nil
    var isHighlighted = false

    var body: some View {
        HStack(spacing: 14) {
            ArtworkView(
                data: item.artworkData,
                seed: item.id,
                systemImage: item.icon,
                size: 52
            )

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

}
