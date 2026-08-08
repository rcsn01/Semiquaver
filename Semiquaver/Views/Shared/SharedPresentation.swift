import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct ArtworkView: View {
    let data: Data?
    let seed: String
    var systemImage = "music.note"
    let size: CGFloat

    var body: some View {
        Group {
            if let image {
                image.resizable().scaledToFill()
            } else {
                LinearGradient(
                    colors: MediaArtworkPalette.colors(for: seed),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    Image(systemName: systemImage)
                        .font(.system(size: size * 0.34, weight: .semibold))
                        .foregroundStyle(Color.playerArtworkIcon)
                        .shadow(color: Color.playerArtworkShadow, radius: 2, y: 1)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: max(6, size * 0.19), style: .continuous))
        .shadow(color: Color.playerShadow.opacity(0.55), radius: size * 0.12, y: size * 0.06)
        .accessibilityHidden(true)
    }

    private var image: Image? {
        guard let data else { return nil }
        #if os(iOS)
        guard let platformImage = UIImage(data: data) else { return nil }
        return Image(uiImage: platformImage)
        #elseif os(macOS)
        guard let platformImage = NSImage(data: data) else { return nil }
        return Image(nsImage: platformImage)
        #endif
    }
}

struct TrackRow: View {
    let track: AudioTrack
    var isCurrent = false
    var isPlaying = false
    var layoutMode: SemiquaverLayoutMode = .compact

    var body: some View {
        HStack(spacing: SemiquaverMetrics.spacingM) {
            ArtworkView(data: track.artworkData, seed: track.id, size: layoutMode.artworkSize)
            VStack(alignment: .leading, spacing: SemiquaverMetrics.spacingXS) {
                Text(track.title).font(.bodyMedium()).lineLimit(1)
                Text(track.detailText).font(.caption()).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: SemiquaverMetrics.spacingS)
            if isCurrent {
                Image(systemName: isPlaying ? "waveform" : "pause.fill")
                    .foregroundStyle(Color.playerAccent)
                    .accessibilityLabel(isPlaying ? "Playing" : "Paused")
            }
            Text(track.durationText).font(.caption()).foregroundStyle(.secondary).monospacedDigit()
        }
        .frame(minHeight: layoutMode.rowHeight)
        .padding(.horizontal, SemiquaverMetrics.spacingS)
        .background(isCurrent ? Color.playerAccent.opacity(0.08) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: SemiquaverMetrics.rowCornerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(track.title), \(track.artist), \(track.album), \(track.durationText)")
    }
}

struct MediaGroupRow: View {
    let group: AudioGroupSummary
    var layoutMode: SemiquaverLayoutMode = .compact

    var body: some View {
        HStack(spacing: SemiquaverMetrics.spacingM) {
            ArtworkView(
                data: group.artworkData,
                seed: group.id,
                systemImage: group.kind == .artist ? "music.mic" : "square.stack",
                size: layoutMode.artworkSize
            )
            VStack(alignment: .leading, spacing: SemiquaverMetrics.spacingXS) {
                Text(group.title).font(.bodyMedium()).lineLimit(1)
                Text(group.subtitle).font(.caption()).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
        }
        .frame(minHeight: layoutMode.rowHeight)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

struct CollectionHeader: View {
    let title: String
    var subtitle: String?
    var data: Data?
    let seed: String
    var systemImage = "music.note"
    var layoutMode: SemiquaverLayoutMode = .compact

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: SemiquaverMetrics.spacingXL) { artwork; labels }
            VStack(spacing: SemiquaverMetrics.spacingL) { artwork; labels }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(SemiquaverMetrics.spacingXL)
    }

    private var artwork: some View {
        ArtworkView(data: data, seed: seed, systemImage: systemImage, size: layoutMode == .compact ? 180 : 156)
    }

    private var labels: some View {
        VStack(alignment: layoutMode == .compact ? .center : .leading, spacing: SemiquaverMetrics.spacingS) {
            Text(title).font(.title.bold()).multilineTextAlignment(layoutMode == .compact ? .center : .leading)
            if let subtitle { Text(subtitle).font(.body).foregroundStyle(.secondary) }
        }
    }
}

struct MiniPlayerContent: View {
    @ObservedObject var player: AudioPlayerController

    var body: some View {
        HStack(spacing: SemiquaverMetrics.spacingM) {
            if let track = player.currentTrack {
                ArtworkView(data: track.artworkData, seed: track.id, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title).font(.bodyMedium()).lineLimit(1)
                    Text(track.artist).font(.caption()).foregroundStyle(.secondary).lineLimit(1)
                }
            } else {
                Image(systemName: "music.note").foregroundStyle(.secondary)
                Text("Nothing Playing").foregroundStyle(.secondary)
            }
            Spacer()
            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .frame(width: 36, height: 36)
            }
            .disabled(player.currentTrack == nil)
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
        }
        .contentShape(Rectangle())
    }
}

struct PlaybackProgress: View {
    @ObservedObject var player: AudioPlayerController

    var body: some View {
        VStack(spacing: SemiquaverMetrics.spacingXS) {
            Slider(
                value: Binding(
                    get: { player.currentTime },
                    set: { player.updateSliderTime($0) }
                ),
                in: 0...max(player.duration, 1)
            ) { editing in
                editing ? player.beginSliderInteraction() : player.endSliderInteraction(at: player.currentTime)
            }
            .tint(.playerAccent)
            .disabled(player.currentTrack == nil)
            HStack {
                Text(Self.time(player.currentTime)); Spacer(); Text(Self.time(player.duration))
            }
            .font(.captionSmall()).foregroundStyle(.secondary).monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Playback position \(Self.time(player.currentTime)) of \(Self.time(player.duration))")
    }

    static func time(_ value: TimeInterval) -> String {
        let seconds = max(Int(value.rounded()), 0)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

struct PlayerControls: View {
    @ObservedObject var player: AudioPlayerController
    var prominent = false

    var body: some View {
        HStack(spacing: prominent ? 34 : 18) {
            Button { player.shuffleQueue() } label: { Image(systemName: "shuffle") }
                .accessibilityLabel("Shuffle")
            Button { player.playPrevious() } label: { Image(systemName: "backward.fill") }
                .accessibilityLabel("Previous")
            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(prominent ? .system(size: 62) : .title)
                    .foregroundStyle(Color.playerAccent)
            }
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
            .disabled(player.currentTrack == nil)
            Button { player.playNext() } label: { Image(systemName: "forward.fill") }
                .accessibilityLabel("Next")
            Button { player.repeatMode = nextRepeatMode } label: {
                Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat")
                    .foregroundStyle(player.repeatMode == .off ? Color.secondary : Color.playerAccent)
            }
            .accessibilityLabel("Repeat \(player.repeatMode.rawValue)")
        }
        .buttonStyle(.plain)
        .disabled(player.currentTrack == nil)
    }

    private var nextRepeatMode: RepeatMode {
        switch player.repeatMode { case .off: .all; case .all: .one; case .one: .off }
    }
}

struct NowPlayingContent: View {
    @ObservedObject var player: AudioPlayerController
    @ObservedObject var playlists: PlaylistStorage
    var layoutMode: SemiquaverLayoutMode = .expanded
    var showQueue: () -> Void

    var body: some View {
        VStack(spacing: SemiquaverMetrics.spacingXL) {
            if let track = player.currentTrack {
                ArtworkView(data: track.artworkData, seed: track.id, size: layoutMode == .compact ? 280 : 240)
                VStack(spacing: SemiquaverMetrics.spacingS) {
                    Text(track.title).font(.title.bold()).lineLimit(2).multilineTextAlignment(.center)
                    Text(track.detailText).foregroundStyle(.secondary).lineLimit(1)
                    Text(player.playbackContext.shortName).font(.caption()).foregroundStyle(.tertiary)
                }
                PlaybackProgress(player: player)
                PlayerControls(player: player, prominent: true)
                HStack {
                    Menu("Playlist", systemImage: "text.badge.plus") {
                        ForEach(playlists.playlists) { playlist in
                            if playlist.trackIDs.contains(track.id) {
                                Button("Remove from \(playlist.title)") { playlists.removeTrack(track.id, from: playlist) }
                            } else {
                                Button("Add to \(playlist.title)") { playlists.addTrack(track.id, to: playlist) }
                            }
                        }
                    }
                    Spacer()
                    Button("Queue", systemImage: "list.bullet", action: showQueue)
                }
                .buttonStyle(.borderless)
            } else {
                SemiquaverUnavailableState(
                    title: "Nothing Playing",
                    message: "Choose a song to begin playback.",
                    systemImage: "music.note"
                )
            }
        }
        .padding(SemiquaverMetrics.spacingXL)
        .frame(maxWidth: 520)
    }
}

struct QueueContent: View {
    @ObservedObject var player: AudioPlayerController
    var layoutMode: SemiquaverLayoutMode = .compact

    var body: some View {
        List {
            Section("Now Playing") {
                if let track = player.currentTrack {
                    TrackRow(track: track, isCurrent: true, isPlaying: player.isPlaying, layoutMode: layoutMode)
                } else { Text("Nothing Playing").foregroundStyle(.secondary) }
            }
            Section("History") {
                if player.playbackHistory.isEmpty { Text("No History").foregroundStyle(.secondary) }
                ForEach(player.playbackHistory) { track in
                    TrackRow(track: track, layoutMode: layoutMode)
                        .contextMenu { Button("Add to Queue") { player.addToQueue(track) } }
                }
            }
            Section("Up Next") {
                if player.playbackQueue.isEmpty { Text("End of Queue").foregroundStyle(.secondary) }
                ForEach(Array(player.playbackQueue.enumerated()), id: \.offset) { index, track in
                    TrackRow(track: track, layoutMode: layoutMode)
                        .contextMenu { Button("Remove", role: .destructive) { player.removeFromQueue(at: index) } }
                }
                .onMove(perform: player.moveQueueItem)
                .onDelete { indexes in
                    for index in indexes.sorted(by: >) { player.removeFromQueue(at: index) }
                }
            }
        }
        .navigationTitle("Queue")
    }
}

struct SemiquaverUnavailableState: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text(message))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SemiquaverLoadingState: View {
    var body: some View {
        VStack(spacing: SemiquaverMetrics.spacingL) {
            ProgressView().tint(.playerAccent)
            Text("Scanning Library…").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
