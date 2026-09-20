import SwiftUI
import MoirasiaUI

struct ArtistDetailView: View {
    let tracks: [AudioTrack]
    let artistName: String
    @ObservedObject var player: AudioPlayerController
    @Binding var showNowPlayingFullScreen: Bool

    var albums: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for track in tracks {
            let key = "\(track.artist) - \(track.album)"
            if !seen.contains(key) {
                seen.insert(key)
                if track.album != AudioMetadataFallbacks.album {
                    result.append(track.album)
                }
            }
        }
        return result
    }

    var body: some View {
        ZStack {
            MoiraColor.canvas.ignoresSafeArea()

            List {
                Section {
                    artistHeader
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

    private var artistHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: MoiraRadius.panel, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: MediaArtworkPalette.colors(for: artistName),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Color.white.opacity(0.9))
            }

            VStack(spacing: 4) {
                Text(artistName)
                    .font(MoiraType.title())
                    .foregroundStyle(MoiraColor.textPrimary)

                if !albums.isEmpty {
                    Text(albums.joined(separator: ", "))
                        .font(MoiraType.body())
                        .foregroundStyle(MoiraColor.textMuted)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.horizontal, 32)
                }

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
                    if player.play(track: track, in: tracks, context: .artist(artistName)) {
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
        }
    }

    private func trailingImage(for track: AudioTrack) -> String? {
        if player.isCurrentTrack(track) {
            return player.isPlaying ? "pause.fill" : "play.fill"
        }
        return nil
    }
}
