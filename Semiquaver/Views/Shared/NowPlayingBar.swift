import SwiftUI

struct NowPlayingBar: View {
    let track: AudioTrack
    @ObservedObject var player: AudioPlayerController

    var body: some View {
        HStack(spacing: 12) {
            artworkView

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.bodyMedium())
                    .foregroundStyle(Color.playerTextPrimary)
                    .lineLimit(1)

                Text(track.detailText)
                    .font(.caption())
                    .foregroundStyle(Color.playerTextSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                player.togglePlayPause()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .bold))
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
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.playerSurface.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.playerGlassBorder, lineWidth: 0.5)
                )
        )
    }

    @ViewBuilder
    private var artworkView: some View {
        if let artworkData = track.artworkData,
           let artwork = UIImage(data: artworkData) {
            Image(uiImage: artwork)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: MediaArtworkPalette.colors(for: track.id),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: player.isPlaying ? "waveform" : "pause.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.playerArtworkIcon)
                }
                .modifier(GlowModifier(color: MediaArtworkPalette.colors(for: track.id).first ?? .clear, radius: 8))
        }
    }
}
