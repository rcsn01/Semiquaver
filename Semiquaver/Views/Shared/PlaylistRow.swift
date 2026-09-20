import SwiftUI
import MoirasiaUI

struct PlaylistRow: View {
    let playlist: PlaylistItem

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: MoiraRadius.card, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: playlist.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)

                Image(systemName: "music.note")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.9))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(playlist.title)
                    .font(MoiraType.body(weight: .semibold))
                    .foregroundStyle(MoiraColor.textPrimary)
                    .lineLimit(1)
                
                Text(playlist.detail)
                    .font(MoiraType.small(weight: .medium))
                    .foregroundStyle(MoiraColor.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(MoiraColor.textSubtle)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .clipShape(RoundedRectangle(cornerRadius: MoiraRadius.card, style: .continuous))
    }
}
