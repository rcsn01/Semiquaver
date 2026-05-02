import SwiftUI

struct PlaylistDetailView: View {
    let playlist: PlaylistItem
    let allTracks: [AudioTrack]
    @ObservedObject var player: AudioPlayerController
    @Binding var showNowPlayingFullScreen: Bool

    var tracks: [AudioTrack] {
        let trackMap = Dictionary(uniqueKeysWithValues: allTracks.map { ($0.id, $0) })
        return playlist.trackIDs.compactMap { trackMap[$0] }
    }

    var body: some View {
        ZStack {
            PlayerBackground()

            List {
                Section {
                    playlistHeader
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

    private var playlistHeader: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: playlist.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .modifier(GlowModifier(color: playlist.colors.first ?? .clear, radius: 16))

                Image(systemName: "music.note")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(Color.playerArtworkIcon)
            }

            VStack(spacing: 6) {
                Text(playlist.title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.playerTextPrimary)

                Text(playlist.detail)
                    .font(.bodyMedium())
                    .foregroundStyle(Color.playerTextSecondary)

                Text("\(tracks.count) songs")
                    .font(.caption())
                    .foregroundStyle(Color.playerTextTertiary)
            }
            .padding(.horizontal, 28)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }

    private var trackRows: some View {
        ForEach(tracks) { track in
            VStack(spacing: 0) {
                Button {
                    if player.play(track: track, in: tracks, context: .playlist(playlist)) {
                        showNowPlayingFullScreen = true
                    }
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
