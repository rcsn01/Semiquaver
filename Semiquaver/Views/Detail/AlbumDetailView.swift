import SwiftUI
import MoirasiaUI

struct AlbumDetailView: View {
    let tracks: [AudioTrack]
    let albumTitle: String
    let artistName: String
    let artworkData: Data?
    @ObservedObject var player: AudioPlayerController
    @Binding var showNowPlayingFullScreen: Bool

    var body: some View {
        ZStack {
            MoiraColor.canvas.ignoresSafeArea()

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
            ArtworkView(
                data: artworkData,
                seed: "\(artistName)::\(albumTitle)",
                systemImage: "square.stack.fill",
                size: 200
            )

            VStack(spacing: 6) {
                Text(albumTitle)
                    .font(MoiraType.title())
                    .foregroundStyle(MoiraColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text(artistName)
                    .font(MoiraType.body(weight: .semibold))
                    .foregroundStyle(MoiraColor.textMuted)
                    .multilineTextAlignment(.center)

                Text("\(tracks.count) songs")
                    .font(MoiraType.small(weight: .medium))
                    .foregroundStyle(MoiraColor.textSubtle)
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
                    if player.play(track: track, in: tracks, context: .album(artist: artistName, title: albumTitle)) {
                        showNowPlayingFullScreen = true
                    }
                } label: {
                    TrackRow(
                        track: track,
                        isCurrent: player.isCurrentTrack(track),
                        isPlaying: player.isPlaying
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
            .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
            .swipeActions(edge: .leading) {
                Button {
                    player.addToQueue(track)
                } label: {
                    Label("Queue", systemImage: "text.line.first.and.arrowtriangle.forward")
                }
            }
        }
    }

}
