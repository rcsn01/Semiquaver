import SwiftUI

struct PlaylistRow: View {
    let playlist: PlaylistItem

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: playlist.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .modifier(GlowModifier(color: playlist.colors.first ?? .clear, radius: 12))

                Image(systemName: "music.note")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.playerArtworkIcon)
                    .shadow(color: Color.playerArtworkShadow, radius: 2, x: 0, y: 1)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(playlist.title)
                    .font(.bodyMedium())
                    .foregroundStyle(Color.playerTextPrimary)
                    .lineLimit(1)
                
                Text(playlist.detail)
                    .font(.caption())
                    .foregroundStyle(Color.playerTextSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.playerTextTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
