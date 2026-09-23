import SwiftUI
import MoirasiaUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

private struct SemiquaverTabHeaderModifier: ViewModifier {
    let title: String
    let actionSystemImage: String?
    let actionLabel: String?
    let action: (() -> Void)?

    @ViewBuilder
    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .navigationTitle(title)
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbarBackground(MoiraColor.canvas, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if let actionSystemImage, let action {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: action) {
                            Image(systemName: actionSystemImage)
                        }
                        .accessibilityLabel(actionLabel ?? title)
                    }
                }
            }
        #else
        content
            .navigationTitle(title)
            .toolbar {
                if let actionSystemImage, let action {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: action) {
                            Image(systemName: actionSystemImage)
                        }
                        .accessibilityLabel(actionLabel ?? title)
                    }
                }
            }
        #endif
    }
}

extension View {
    func semiquaverTabHeader(
        _ title: String,
        actionSystemImage: String? = nil,
        actionLabel: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        modifier(
            SemiquaverTabHeaderModifier(
                title: title,
                actionSystemImage: actionSystemImage,
                actionLabel: actionLabel,
                action: action
            )
        )
    }
}

struct SemiquaverGlassSelectionBar<Item: Hashable, Label: View>: View {
    let items: [Item]
    @Binding var selection: Item
    let label: (Item, Bool) -> Label
    @Namespace private var selectionAnimation

    init(
        _ items: [Item],
        selection: Binding<Item>,
        @ViewBuilder label: @escaping (Item, Bool) -> Label
    ) {
        self.items = items
        _selection = selection
        self.label = label
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.self) { item in
                let isSelected = selection == item

                Button {
                    withAnimation(.snappy(duration: 0.25)) {
                        selection = item
                    }
                } label: {
                    label(item, isSelected)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(MoiraColor.controlSelected)
                                    .matchedGeometryEffect(
                                        id: "selection",
                                        in: selectionAnimation
                                    )
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(MoiraColor.surface, in: Capsule())
        .overlay {
            Capsule()
                .stroke(MoiraColor.border, lineWidth: 0.5)
        }
    }
}

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
                        .foregroundStyle(MoiraColor.textPrimary.opacity(0.9))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: max(6, size * 0.19), style: .continuous))
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
        HStack(spacing: MoiraSpace.x3) {
            ArtworkView(data: track.artworkData, seed: track.id, size: layoutMode.artworkSize)
            VStack(alignment: .leading, spacing: MoiraSpace.x1) {
                Text(track.title).font(MoiraType.body(weight: .semibold)).lineLimit(1)
                Text(track.detailText).font(MoiraType.small(weight: .medium)).foregroundStyle(MoiraColor.textMuted).lineLimit(1)
            }
            Spacer(minLength: MoiraSpace.x2)
            if isCurrent {
                Image(systemName: isPlaying ? "waveform" : "pause.fill")
                    .foregroundStyle(MoiraColor.textPrimary)
                    .accessibilityLabel(isPlaying ? "Playing" : "Paused")
            }
            Text(track.durationText).font(MoiraType.small(weight: .medium)).foregroundStyle(MoiraColor.textMuted).monospacedDigit()
        }
        .frame(minHeight: layoutMode.rowHeight)
        .padding(.horizontal, MoiraSpace.x2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isCurrent ? MoiraColor.controlSelected : .clear)
        .clipShape(RoundedRectangle(cornerRadius: MoiraRadius.card, style: .continuous))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(track.title), \(track.artist), \(track.album), \(track.durationText)")
    }
}

struct MediaGroupRow: View {
    let group: AudioGroupSummary
    var layoutMode: SemiquaverLayoutMode = .compact

    var body: some View {
        HStack(spacing: MoiraSpace.x3) {
            ArtworkView(
                data: group.artworkData,
                seed: group.id,
                systemImage: group.kind == .artist ? "music.mic" : "square.stack",
                size: layoutMode.artworkSize
            )
            VStack(alignment: .leading, spacing: MoiraSpace.x1) {
                Text(group.title).font(MoiraType.body(weight: .semibold)).lineLimit(1)
                Text(group.subtitle).font(MoiraType.small(weight: .medium)).foregroundStyle(MoiraColor.textMuted).lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right").font(MoiraType.caption(weight: .bold)).foregroundStyle(MoiraColor.textSubtle)
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
            HStack(spacing: MoiraSpace.x6) { artwork; labels }
            VStack(spacing: MoiraSpace.x4) { artwork; labels }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(MoiraSpace.x6)
    }

    private var artwork: some View {
        ArtworkView(data: data, seed: seed, systemImage: systemImage, size: layoutMode == .compact ? 180 : 156)
    }

    private var labels: some View {
        VStack(alignment: layoutMode == .compact ? .center : .leading, spacing: MoiraSpace.x2) {
            Text(title).font(MoiraType.titleLarge()).foregroundStyle(MoiraColor.textPrimary).multilineTextAlignment(layoutMode == .compact ? .center : .leading)
            if let subtitle { Text(subtitle).font(MoiraType.bodyLarge()).foregroundStyle(MoiraColor.textMuted) }
        }
    }
}

struct MiniPlayerContent: View {
    @ObservedObject var player: AudioPlayerController

    var body: some View {
        HStack(spacing: MoiraSpace.x3) {
            if let track = player.currentTrack {
                ArtworkView(data: track.artworkData, seed: track.id, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title).font(MoiraType.body(weight: .semibold)).lineLimit(1)
                    Text(track.artist).font(MoiraType.small(weight: .medium)).foregroundStyle(MoiraColor.textMuted).lineLimit(1)
                }
            } else {
                Image(systemName: "music.note").foregroundStyle(MoiraColor.textMuted)
                Text("Nothing Playing").font(MoiraType.body()).foregroundStyle(MoiraColor.textMuted)
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
        VStack(spacing: MoiraSpace.x1) {
            Slider(
                value: Binding(
                    get: { player.currentTime },
                    set: { player.updateSliderTime($0) }
                ),
                in: 0...max(player.duration, 1)
            ) { editing in
                editing ? player.beginSliderInteraction() : player.endSliderInteraction(at: player.currentTime)
            }
            .disabled(player.currentTrack == nil)
            HStack {
                Text(Self.time(player.currentTime)); Spacer(); Text(Self.time(player.duration))
            }
            .font(MoiraType.caption(weight: .semibold)).foregroundStyle(MoiraColor.textMuted).monospacedDigit()
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
                    .foregroundStyle(MoiraColor.textPrimary)
            }
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
            .disabled(player.currentTrack == nil)
            Button { player.playNext() } label: { Image(systemName: "forward.fill") }
                .accessibilityLabel("Next")
            Button { player.repeatMode = nextRepeatMode } label: {
                Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat")
                    .foregroundStyle(player.repeatMode == .off ? MoiraColor.textMuted : MoiraColor.textPrimary)
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
        VStack(spacing: MoiraSpace.x6) {
            if let track = player.currentTrack {
                ArtworkView(data: track.artworkData, seed: track.id, size: layoutMode == .compact ? 280 : 240)
                VStack(spacing: MoiraSpace.x2) {
                    Text(track.title).font(MoiraType.titleLarge()).foregroundStyle(MoiraColor.textPrimary).lineLimit(2).multilineTextAlignment(.center)
                    Text(track.detailText).font(MoiraType.bodyLarge()).foregroundStyle(MoiraColor.textMuted).lineLimit(1)
                    Text(player.playbackContext.shortName).font(MoiraType.small(weight: .medium)).foregroundStyle(MoiraColor.textSubtle)
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
        .padding(MoiraSpace.x6)
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
                } else { Text("Nothing Playing").font(MoiraType.body()).foregroundStyle(MoiraColor.textMuted) }
            }
            Section("History") {
                if player.playbackHistory.isEmpty { Text("No History").font(MoiraType.body()).foregroundStyle(MoiraColor.textMuted) }
                ForEach(player.playbackHistory) { track in
                    TrackRow(track: track, layoutMode: layoutMode)
                        .contextMenu { Button("Add to Queue") { player.addToQueue(track) } }
                }
            }
            Section("Up Next") {
                if player.playbackQueue.isEmpty { Text("End of Queue").font(MoiraType.body()).foregroundStyle(MoiraColor.textMuted) }
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
        VStack(spacing: MoiraSpace.x3) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(MoiraColor.textSubtle)
            Text(title)
                .font(MoiraType.title())
                .foregroundStyle(MoiraColor.textPrimary)
            Text(message)
                .font(MoiraType.body())
                .foregroundStyle(MoiraColor.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(MoiraSpace.x6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SemiquaverLoadingState: View {
    var body: some View {
        VStack(spacing: MoiraSpace.x4) {
            ProgressView()
            Text("Scanning Library…")
                .font(MoiraType.body())
                .foregroundStyle(MoiraColor.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
