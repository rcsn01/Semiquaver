import SwiftUI
import MoirasiaUI

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
                    .font(MoiraType.body(weight: .semibold))
                    .foregroundStyle(MoiraColor.textPrimary)
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(MoiraType.small(weight: .medium))
                    .foregroundStyle(MoiraColor.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            if let trailingSystemImage {
                Image(systemName: trailingSystemImage)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(MoiraColor.textPrimary)
                    .frame(width: 28, height: 28)
            } else if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(MoiraColor.textSubtle)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isHighlighted ? MoiraColor.controlSelected : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: MoiraRadius.card, style: .continuous))
    }

}
