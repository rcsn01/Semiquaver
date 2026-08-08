import AppKit
import SwiftUI

enum MacSidebarSelection: Hashable {
    case songs, artists, albums
    case playlist(UUID)
}

struct MacContentView: View {
    @ObservedObject var model: MacAppModel
    @ObservedObject private var player: AudioPlayerController
    @ObservedObject private var library: AppMusicLibrary
    @State private var selection: MacSidebarSelection? = .songs
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool
    @State private var showNowPlaying = false

    init(model: MacAppModel) {
        self.model = model
        _player = ObservedObject(wrappedValue: model.player)
        _library = ObservedObject(wrappedValue: model.library)
    }

    var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView {
                MacSidebar(selection: $selection, playlists: model.playlists)
                    .navigationSplitViewColumnWidth(min: 180, ideal: 215)
            } detail: {
                detail
                    .searchable(text: $searchText, placement: .toolbar, prompt: "Songs, artists, albums, genres")
                    .searchFocused($searchFocused)
                    .onReceive(NotificationCenter.default.publisher(for: .focusLibrarySearch)) { _ in searchFocused = true }
                    .inspector(isPresented: $model.isQueueVisible) {
                        MacQueueView(player: player).inspectorColumnWidth(min: 260, ideal: 320, max: 400)
                    }
            }
            Divider()
            MacPlayerBar(player: player, showNowPlaying: $showNowPlaying, showQueue: $model.isQueueVisible)
        }
        .frame(minWidth: 760, minHeight: 520)
        .task { await model.start() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await model.rescan() }
        }
        .sheet(isPresented: $showNowPlaying) { MacNowPlayingView(player: player) }
        .alert("Move to Trash?", isPresented: Binding(get: { model.trackPendingTrash != nil }, set: { if !$0 { model.trackPendingTrash = nil } })) {
            Button("Move to Trash", role: .destructive) { model.confirmTrash() }
            Button("Cancel", role: .cancel) { model.trackPendingTrash = nil }
        } message: { Text("The audio file will be moved to the macOS Trash and can be recovered there.") }
        .alert("Semiquaver", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK") { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
    }

    @ViewBuilder private var detail: some View {
        if model.locations.records.isEmpty {
            ContentUnavailableView("Choose Your Music Folders", systemImage: "music.note.house",
                                   description: Text("Semiquaver plays files in place. Your music is never copied."))
                .toolbar { Button("Choose Music Folders", systemImage: "folder.badge.plus") { model.chooseFolders() } }
        } else if library.isLoading && library.tracks.isEmpty {
            ProgressView("Scanning music…")
        } else {
            switch selection ?? .songs {
            case .songs:
                MacTrackList(title: "Songs", tracks: filtered(library.songs), context: .library, model: model)
            case .artists:
                let mapped = Dictionary(uniqueKeysWithValues: library.artists.map { ($0.id, library.tracksByArtist[$0.title] ?? []) })
                MacGroupedList(title: "Artists", groups: library.artists, tracks: mapped, searchText: searchText, model: model)
            case .albums:
                let mapped = Dictionary(uniqueKeysWithValues: library.albums.map { ($0.id, library.tracksByAlbumID[String($0.id.dropFirst("album::".count))] ?? []) })
                MacGroupedList(title: "Albums", groups: library.albums, tracks: mapped, searchText: searchText, model: model)
            case .playlist(let id):
                if let playlist = model.playlists.playlists.first(where: { $0.id == id }) {
                    let ids = Set(playlist.trackIDs)
                    let playlistTracks = library.tracks.filter { ids.contains($0.id) }
                    let titleMatches = !searchText.isEmpty && playlist.title.localizedCaseInsensitiveContains(searchText)
                    MacTrackList(title: playlist.title, tracks: titleMatches ? playlistTracks : filtered(playlistTracks), context: .playlist(playlist), model: model)
                } else { ContentUnavailableView("Playlist Not Found", systemImage: "music.note.list") }
            }
        }
    }

    private func filtered(_ tracks: [AudioTrack]) -> [AudioTrack] {
        guard !searchText.isEmpty else { return tracks }
        return tracks.filter { [$0.title, $0.artist, $0.album, $0.genre].contains { $0.localizedCaseInsensitiveContains(searchText) } }
    }
}

private struct MacSidebar: View {
    @Binding var selection: MacSidebarSelection?
    @ObservedObject var playlists: PlaylistStorage
    @State private var newPlaylistName = ""
    @State private var creatingPlaylist = false

    var body: some View {
        List(selection: $selection) {
            Section("Library") {
                Label("Songs", systemImage: "music.note").tag(MacSidebarSelection.songs)
                Label("Artists", systemImage: "music.mic").tag(MacSidebarSelection.artists)
                Label("Albums", systemImage: "square.stack").tag(MacSidebarSelection.albums)
            }
            Section("Playlists") {
                ForEach(playlists.playlists) { playlist in
                    Label(playlist.title, systemImage: "music.note.list").tag(MacSidebarSelection.playlist(playlist.id))
                        .contextMenu { Button("Delete", role: .destructive) { playlists.deletePlaylist(playlist) } }
                }
                Button("New Playlist", systemImage: "plus") { creatingPlaylist = true }.buttonStyle(.plain)
            }
        }
        .navigationTitle("Semiquaver")
        .alert("New Playlist", isPresented: $creatingPlaylist) {
            TextField("Name", text: $newPlaylistName)
            Button("Create") { if !newPlaylistName.isEmpty { playlists.createPlaylist(title: newPlaylistName); newPlaylistName = "" } }
            Button("Cancel", role: .cancel) {}
        }
    }
}

private struct MacTrackList: View {
    let title: String
    let tracks: [AudioTrack]
    let context: PlaybackContext
    @ObservedObject var model: MacAppModel
    @ObservedObject private var player: AudioPlayerController
    @ObservedObject private var playlists: PlaylistStorage

    init(title: String, tracks: [AudioTrack], context: PlaybackContext, model: MacAppModel) {
        self.title = title; self.tracks = tracks; self.context = context; self.model = model
        _player = ObservedObject(wrappedValue: model.player)
        _playlists = ObservedObject(wrappedValue: model.playlists)
    }

    var body: some View {
        List(tracks) { track in
            MacTrackRow(track: track, isPlaying: player.currentTrack?.id == track.id && player.isPlaying)
                .contentShape(Rectangle()).onTapGesture(count: 2) { player.play(track: track, in: tracks, context: context) }
                .contextMenu {
                    Button("Play") { player.play(track: track, in: tracks, context: context) }
                    Button("Add to Queue") { player.addToQueue(track) }
                    Menu("Add to Playlist") {
                        ForEach(playlists.playlists) { playlist in
                            Button(playlist.title) { playlists.addTrack(track.id, to: playlist) }
                        }
                    }
                    if case .playlist(let playlist) = context {
                        Button("Remove from Playlist") { playlists.removeTrack(track.id, from: playlist) }
                    }
                    Divider()
                    Button("Reveal in Finder") { model.reveal(track) }
                    Button("Move to Trash", role: .destructive) { model.requestTrash(track) }
                }
        }
        .navigationTitle(title)
        .overlay { if tracks.isEmpty { ContentUnavailableView("No Music", systemImage: "music.note", description: Text("No matching available tracks.")) } }
    }
}

private struct MacGroupedList: View {
    let title: String
    let groups: [AudioGroupSummary]
    let tracks: [String: [AudioTrack]]
    let searchText: String
    let model: MacAppModel

    var body: some View {
        List {
            ForEach(groups.filter { searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) || $0.subtitle.localizedCaseInsensitiveContains(searchText) }) { group in
                DisclosureGroup {
                    ForEach(tracks[group.id] ?? []) { track in
                        MacTrackRow(track: track, isPlaying: model.player.currentTrack?.id == track.id && model.player.isPlaying)
                            .onTapGesture(count: 2) { model.player.play(track: track, in: tracks[group.id] ?? [], context: .library) }
                            .contextMenu {
                                Button("Play") { model.player.play(track: track, in: tracks[group.id] ?? [], context: .library) }
                                Button("Add to Queue") { model.player.addToQueue(track) }
                                Menu("Add to Playlist") {
                                    ForEach(model.playlists.playlists) { playlist in
                                        Button(playlist.title) { model.playlists.addTrack(track.id, to: playlist) }
                                    }
                                }
                                Divider()
                                Button("Reveal in Finder") { model.reveal(track) }
                                Button("Move to Trash", role: .destructive) { model.requestTrash(track) }
                            }
                    }
                } label: { Label(group.title, systemImage: group.kind == .artist ? "music.mic" : "square.stack") }
            }
        }.navigationTitle(title)
    }
}

private struct MacTrackRow: View {
    let track: AudioTrack
    let isPlaying: Bool
    var body: some View {
        HStack(spacing: 12) {
            MacArtwork(data: track.artworkData, seed: track.id, size: 42)
            VStack(alignment: .leading) {
                Text(track.title).lineLimit(1)
                Text("\(track.artist) • \(track.album)").font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            if isPlaying { Image(systemName: "waveform").foregroundStyle(Color.playerAccent).accessibilityLabel("Playing") }
            Text(track.durationText).font(.caption).foregroundStyle(.secondary).monospacedDigit()
        }.padding(.vertical, 3)
    }
}

private struct MacArtwork: View {
    let data: Data?; let seed: String; let size: CGFloat
    var body: some View {
        Group {
            if let data, let image = NSImage(data: data) { Image(nsImage: image).resizable().scaledToFill() }
            else { LinearGradient(colors: MediaArtworkPalette.colors(for: seed), startPoint: .topLeading, endPoint: .bottomTrailing).overlay(Image(systemName: "music.note").foregroundStyle(.white)) }
        }.frame(width: size, height: size).clipShape(RoundedRectangle(cornerRadius: size * 0.18))
    }
}

private struct MacPlayerBar: View {
    @ObservedObject var player: AudioPlayerController
    @Binding var showNowPlaying: Bool
    @Binding var showQueue: Bool
    var body: some View {
        HStack(spacing: 12) {
            if let track = player.currentTrack {
                Button { showNowPlaying = true } label: {
                    HStack { MacArtwork(data: track.artworkData, seed: track.id, size: 46); VStack(alignment: .leading) { Text(track.title).lineLimit(1); Text(track.artist).font(.caption).foregroundStyle(.secondary).lineLimit(1) } }.frame(width: 240, alignment: .leading)
                }.buttonStyle(.plain)
            } else { Text("Nothing Playing").foregroundStyle(.secondary).frame(width: 240, alignment: .leading) }
            Spacer()
            Button { player.playPrevious() } label: { Image(systemName: "backward.fill") }.accessibilityLabel("Previous")
            Button { player.togglePlayPause() } label: { Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill").font(.title) }.accessibilityLabel(player.isPlaying ? "Pause" : "Play")
            Button { player.playNext() } label: { Image(systemName: "forward.fill") }.accessibilityLabel("Next")
            Slider(value: Binding(get: { player.currentTime }, set: { player.setCurrentTime($0) }), in: 0...max(player.duration, 1)).frame(maxWidth: 320)
            Spacer()
            Button { showQueue.toggle() } label: { Image(systemName: "list.bullet") }.accessibilityLabel("Toggle Queue").help("Queue (⌘U)")
        }.buttonStyle(.borderless).padding(.horizontal, 16).padding(.vertical, 8).background(.bar)
    }
}

private struct MacQueueView: View {
    @ObservedObject var player: AudioPlayerController
    var body: some View {
        List {
            Section("Now Playing") { if let track = player.currentTrack { MacTrackRow(track: track, isPlaying: player.isPlaying) } else { Text("Nothing playing") } }
            Section("Up Next") { ForEach(Array(player.playbackQueue.enumerated()), id: \.element.id) { index, track in MacTrackRow(track: track, isPlaying: false).contextMenu { Button("Remove") { player.removeFromQueue(at: index) } } } }
        }.navigationTitle("Queue")
    }
}

private struct MacNowPlayingView: View {
    @ObservedObject var player: AudioPlayerController
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 20) {
            if let track = player.currentTrack {
                MacArtwork(data: track.artworkData, seed: track.id, size: 240)
                Text(track.title).font(.title.bold()).lineLimit(2)
                Text(track.detailText).foregroundStyle(.secondary)
                Slider(value: Binding(get: { player.currentTime }, set: { player.setCurrentTime($0) }), in: 0...max(player.duration, 1))
                HStack { Button { player.playPrevious() } label: { Image(systemName: "backward.fill") }; Button { player.togglePlayPause() } label: { Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill").font(.largeTitle) }; Button { player.playNext() } label: { Image(systemName: "forward.fill") } }.buttonStyle(.borderless)
            }
        }.padding(32).frame(width: 420, height: 500).toolbar { Button("Done") { dismiss() } }
    }
}

extension Notification.Name { static let focusLibrarySearch = Notification.Name("Semiquaver.focusLibrarySearch") }
