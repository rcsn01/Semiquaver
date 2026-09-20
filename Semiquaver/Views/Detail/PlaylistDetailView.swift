import SwiftUI
import MoirasiaUI

struct PlaylistDetailView: View {
    let playlist: PlaylistItem
    let allTracks: [AudioTrack]
    @ObservedObject var playlistStorage: PlaylistStorage
    @ObservedObject var player: AudioPlayerController
    @Binding var showNowPlayingFullScreen: Bool

    private var currentPlaylist: PlaylistItem {
        playlistStorage.playlists.first(where: { $0.id == playlist.id }) ?? playlist
    }

    var tracks: [AudioTrack] {
        let trackMap = Dictionary(uniqueKeysWithValues: allTracks.map { ($0.id, $0) })
        return currentPlaylist.trackIDs.compactMap { trackMap[$0] }
    }

    var body: some View {
        ZStack {
            MoiraColor.canvas.ignoresSafeArea()

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
                RoundedRectangle(cornerRadius: MoiraRadius.panel, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: playlist.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)

                Image(systemName: "music.note")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(Color.white.opacity(0.9))
            }

            VStack(spacing: 6) {
                Text(currentPlaylist.title)
                    .font(MoiraType.title())
                    .foregroundStyle(MoiraColor.textPrimary)

                Text(currentPlaylist.detail)
                    .font(MoiraType.body(weight: .semibold))
                    .foregroundStyle(MoiraColor.textMuted)

                Text("\(tracks.count) songs")
                    .font(MoiraType.small(weight: .medium))
                    .foregroundStyle(MoiraColor.textSubtle)
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
                    if player.play(track: track, in: tracks, context: .playlist(currentPlaylist)) {
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
                        .overlay(MoiraColor.border)
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
            }
            .swipeActions(edge: .trailing) {
                Button("Remove", role: .destructive) {
                    playlistStorage.removeTrack(track.id, from: currentPlaylist)
                }
            }
            .contextMenu {
                Button("Play") { player.play(track: track, in: tracks, context: .playlist(currentPlaylist)) }
                Button("Add to Queue") { player.addToQueue(track) }
                Button("Remove from Playlist", role: .destructive) { playlistStorage.removeTrack(track.id, from: currentPlaylist) }
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
