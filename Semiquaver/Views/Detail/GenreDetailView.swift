import SwiftUI
import MoirasiaUI

struct GenreDetailView: View {
    let tracks: [AudioTrack]
    let genreName: String
    @ObservedObject var player: AudioPlayerController
    @Binding var showNowPlayingFullScreen: Bool

    var body: some View {
        ZStack {
            MoiraColor.canvas.ignoresSafeArea()

            List {
                Section {
                    genreHeader
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

    private var genreHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: MoiraRadius.panel, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: MediaArtworkPalette.colors(for: genreName),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)

                Image(systemName: "guitars.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(MoiraColor.textPrimary.opacity(0.9))
            }

            VStack(spacing: 4) {
                Text(genreName)
                    .font(MoiraType.title())
                    .foregroundStyle(MoiraColor.textPrimary)

                Text("\(tracks.count) songs")
                    .font(MoiraType.small(weight: .medium))
                    .foregroundStyle(MoiraColor.textSubtle)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }

    private var trackRows: some View {
        ForEach(tracks) { track in
            VStack(spacing: 0) {
                Button {
                    if player.play(track: track, in: tracks, context: .genre(genreName)) {
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
