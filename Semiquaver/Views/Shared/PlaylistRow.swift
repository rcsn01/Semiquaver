import SwiftUI

struct PlaylistRow: View {
    let playlist: PlaylistItem

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: playlist.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 58, height: 58)
                .overlay {
                    Image(systemName: "music.note")
                        .foregroundStyle(Color.white.opacity(0.84))
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(playlist.title)
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                Text(playlist.detail)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.playerTextSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.playerAccent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
