import SwiftUI

struct AlbumDetailView: View {
    let tracks: [AudioTrack]
    let albumTitle: String
    let artistName: String
    let artworkData: Data?
    @ObservedObject var player: AudioPlayerController
    @Binding var showNowPlayingFullScreen: Bool

    private var artworkImage: UIImage? {
        if let artworkData {
            return UIImage(data: artworkData)
        }
        return nil
    }

    var body: some View {
        ZStack {
            PlayerBackground()

            List {
                Section {
                    albumHeader
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))

                Section {
                    trackRows
                }
            }
            .listStyle(.plain)
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .environment(\.defaultMinListRowHeight, 10)
        }
    }

    private var albumHeader: some View {
        VStack(spacing: 20) {
            if let artworkImage {
                Image(uiImage: artworkImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: Color.playerShadow, radius: 24, x: 0, y: 12)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: MediaArtworkPalette.colors(for: "\(artistName)::\(albumTitle)"),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 200)
                        .shadow(color: Color.playerShadow, radius: 24, x: 0, y: 12)

                    Image(systemName: "square.stack.fill")
                        .font(.system(size: 72, weight: .light))
                        .foregroundStyle(Color.playerArtworkIcon)
                }
            }

            VStack(spacing: 6) {
                Text(albumTitle)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.playerTextPrimary)
                    .multilineTextAlignment(.center)

                Text(artistName)
                    .font(.bodyMedium())
                    .foregroundStyle(Color.playerTextSecondary)
                    .multilineTextAlignment(.center)

                Text("\(tracks.count) songs")
                    .font(.caption())
                    .foregroundStyle(Color.playerTextTertiary)
            }
            .padding(.horizontal, 28)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private var trackRows: some View {
        ForEach(tracks) { track in
            VStack(spacing: 0) {
                Button {
                    player.play(track: track, in: tracks, context: .album(artist: artistName, title: albumTitle))
                    showNowPlayingFullScreen = true
                } label: {
                    MediaRow(
                        item: track.mediaItem(
                            isCurrent: player.isCurrentTrack(track),
                            isPlaying: player.isPlaying
                        ),
                        trailingSystemImage: trailingImage(for: track),
                        isHighlighted: player.isCurrentTrack(track)
                    )
                    .padding(.horizontal, 4)
                }
                .buttonStyle(PressScaleButtonStyle())

                if track.id != tracks.last?.id {
                    Divider()
                        .overlay(Color.playerDivider)
                        .padding(.leading, 76)
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
            .swipeActions(edge: .leading) {
                Button {
                    player.addToQueue(track)
                } label: {
                    Label("Queue", systemImage: "text.line.first.and.arrowtriangle.forward")
                }
                .tint(Color.playerAccent)
            }
        }
    }

    private func trailingImage(for track: AudioTrack) -> String? {
        if player.isCurrentTrack(track) {
            return player.isPlaying ? "pause.fill" : "play.fill"
        }
        return nil
    }
}
