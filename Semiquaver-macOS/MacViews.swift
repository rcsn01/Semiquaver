import AppKit
import SwiftUI

struct MacContentView: View {
    @ObservedObject var model: MacAppModel
    @ObservedObject private var player: AudioPlayerController
    @ObservedObject private var library: AppMusicLibrary
    @State private var selection: LibraryDestination? = .songs
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
                NavigationStack { detail }
                    .searchable(text: $searchText, placement: .toolbar, prompt: "Songs, artists, albums, genres")
                    .searchFocused($searchFocused)
                    .onReceive(NotificationCenter.default.publisher(for: .focusLibrarySearch)) { _ in searchFocused = true }
                    .inspector(isPresented: $model.isQueueVisible) {
                        NavigationStack { QueueContent(player: player, layoutMode: .expanded) }
                            .inspectorColumnWidth(min: 280, ideal: 330, max: 420)
                    }
            }
            Divider()
            MacExpandedPlayer(player: player, showNowPlaying: $showNowPlaying, showQueue: $model.isQueueVisible)
        }
        .tint(.playerAccent)
        .frame(minWidth: 760, minHeight: 520)
        .task { await model.start() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await model.rescan() }
        }
        .sheet(isPresented: $showNowPlaying) {
            NowPlayingContent(player: player, playlists: model.playlists, layoutMode: .expanded) {
                showNowPlaying = false
                model.isQueueVisible = true
            }
            .frame(width: 460, height: 590)
        }
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
            SemiquaverUnavailableState(
                title: "Choose Your Music Folders",
                message: "Semiquaver plays files in place. Your music is never copied.",
                systemImage: "music.note.house"
            )
            .toolbar { Button("Choose Music Folders", systemImage: "folder.badge.plus") { model.chooseFolders() } }
        } else if library.isLoading && library.tracks.isEmpty {
            SemiquaverLoadingState()
        } else if let error = library.errorMessage {
            SemiquaverUnavailableState(title: "Library Unavailable", message: error, systemImage: "externaldrive.badge.exclamationmark")
        } else {
            switch selection ?? .songs {
            case .songs:
                MacTrackList(title: "Songs", tracks: LibrarySearch.tracks(library.songs, matching: searchText), context: .library, model: model, searchActive: !LibrarySearch.normalized(searchText).isEmpty)
            case .artists:
                MacGroupList(title: "Artists", groups: library.artists, searchText: searchText, model: model)
            case .albums:
                MacGroupList(title: "Albums", groups: library.albums, searchText: searchText, model: model)
            case .playlist(let id):
                if let playlist = model.playlists.playlists.first(where: { $0.id == id }) {
                    MacTrackList(
                        title: playlist.title,
                        tracks: LibrarySearch.playlistTracks(playlist, allTracks: library.tracks, matching: searchText),
                        context: .playlist(playlist), model: model,
                        searchActive: !LibrarySearch.normalized(searchText).isEmpty
                    )
                } else {
                    SemiquaverUnavailableState(title: "Playlist Not Found", message: "This playlist is no longer available.", systemImage: "music.note.list")
                }
            case .settings:
                EmptyView()
            }
        }
    }
}

private struct MacSidebar: View {
    @Binding var selection: LibraryDestination?
    @ObservedObject var playlists: PlaylistStorage
    @State private var draftName = ""
    @State private var creatingPlaylist = false
    @State private var renamingPlaylist: PlaylistItem?
    @State private var deletingPlaylist: PlaylistItem?

    var body: some View {
        List(selection: $selection) {
            Section("Library") {
                Label(LibraryDestination.songs.label, systemImage: LibraryDestination.songs.systemImage).tag(LibraryDestination.songs)
                Label(LibraryDestination.artists.label, systemImage: LibraryDestination.artists.systemImage).tag(LibraryDestination.artists)
                Label(LibraryDestination.albums.label, systemImage: LibraryDestination.albums.systemImage).tag(LibraryDestination.albums)
            }
            Section("Playlists") {
                ForEach(playlists.playlists) { playlist in
                    Label(playlist.title, systemImage: "music.note.list")
                        .tag(LibraryDestination.playlist(playlist.id))
                        .contextMenu {
                            Button("Rename") { draftName = playlist.title; renamingPlaylist = playlist }
                            Button("Delete", role: .destructive) { deletingPlaylist = playlist }
                        }
                }
                Button("New Playlist", systemImage: "plus") { draftName = ""; creatingPlaylist = true }.buttonStyle(.plain)
            }
        }
        .navigationTitle("Semiquaver")
        .alert("New Playlist", isPresented: $creatingPlaylist) {
            TextField("Name", text: $draftName)
            Button("Create") { _ = playlists.createPlaylist(title: draftName) }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Rename Playlist", isPresented: Binding(get: { renamingPlaylist != nil }, set: { if !$0 { renamingPlaylist = nil } })) {
            TextField("Name", text: $draftName)
            Button("Rename") { if let playlist = renamingPlaylist { _ = playlists.renamePlaylist(id: playlist.id, title: draftName) }; renamingPlaylist = nil }
            Button("Cancel", role: .cancel) { renamingPlaylist = nil }
        }
        .confirmationDialog("Delete Playlist?", isPresented: Binding(get: { deletingPlaylist != nil }, set: { if !$0 { deletingPlaylist = nil } })) {
            Button("Delete Playlist", role: .destructive) { if let playlist = deletingPlaylist { playlists.deletePlaylist(playlist) }; deletingPlaylist = nil }
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
    let searchActive: Bool

    init(title: String, tracks: [AudioTrack], context: PlaybackContext, model: MacAppModel, searchActive: Bool = false) {
        self.title = title
        self.tracks = tracks
        self.context = context
        self.model = model
        self.searchActive = searchActive
        _player = ObservedObject(wrappedValue: model.player)
        _playlists = ObservedObject(wrappedValue: model.playlists)
    }

    var body: some View {
        List(tracks) { track in
            TrackRow(track: track, isCurrent: player.isCurrentTrack(track), isPlaying: player.isPlaying, layoutMode: .expanded)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { player.play(track: track, in: tracks, context: context) }
                .contextMenu { actions(for: track) }
        }
        .navigationTitle(title)
        .overlay {
            if tracks.isEmpty {
                SemiquaverUnavailableState(
                    title: searchActive ? "No Search Results" : "No Music",
                    message: searchActive ? "Try a different search." : "No available tracks.",
                    systemImage: searchActive ? "magnifyingglass" : "music.note"
                )
            }
        }
    }

    @ViewBuilder private func actions(for track: AudioTrack) -> some View {
        Button("Play", systemImage: "play.fill") { player.play(track: track, in: tracks, context: context) }
        Button("Add to Queue", systemImage: "text.line.first.and.arrowtriangle.forward") { player.addToQueue(track) }
        Menu("Add to Playlist") {
            ForEach(playlists.playlists) { playlist in
                if playlist.trackIDs.contains(track.id) {
                    Button("Remove from \(playlist.title)") { playlists.removeTrack(track.id, from: playlist) }
                } else {
                    Button(playlist.title) { playlists.addTrack(track.id, to: playlist) }
                }
            }
        }
        if case .playlist(let playlist) = context {
            Button("Remove from Playlist") { playlists.removeTrack(track.id, from: playlist) }
        }
        Divider()
        Button("Reveal in Finder", systemImage: "folder") { model.reveal(track) }
        Button("Move to Trash", systemImage: "trash", role: .destructive) { model.requestTrash(track) }
    }
}

private struct MacGroupList: View {
    let title: String
    let groups: [AudioGroupSummary]
    let searchText: String
    @ObservedObject var model: MacAppModel

    private var filtered: [AudioGroupSummary] {
        LibrarySearch.groups(groups, tracksForGroup: tracks(for:), matching: searchText)
    }

    var body: some View {
        List(filtered) { group in
            NavigationLink {
                let contents = tracks(for: group)
                MacTrackList(title: group.title, tracks: contents, context: context(for: group, tracks: contents), model: model)
            } label: { MediaGroupRow(group: group, layoutMode: .expanded) }
        }
        .navigationTitle(title)
        .overlay {
            if filtered.isEmpty {
                SemiquaverUnavailableState(title: "No Search Results", message: "Try a different search.", systemImage: "magnifyingglass")
            }
        }
    }

    private func tracks(for group: AudioGroupSummary) -> [AudioTrack] {
        switch group.kind {
        case .artist: model.library.tracksByArtist[group.title] ?? []
        case .album: model.library.tracksByAlbumID[String(group.id.dropFirst("album::".count))] ?? []
        case .genre: []
        }
    }

    private func context(for group: AudioGroupSummary, tracks: [AudioTrack]) -> PlaybackContext {
        group.kind == .artist ? .artist(group.title) : .album(artist: tracks.first?.artist ?? AudioMetadataFallbacks.artist, title: group.title)
    }
}

private struct MacExpandedPlayer: View {
    @ObservedObject var player: AudioPlayerController
    @Binding var showNowPlaying: Bool
    @Binding var showQueue: Bool

    var body: some View {
        HStack(spacing: 18) {
            Button { showNowPlaying = true } label: {
                MiniPlayerContent(player: player).frame(width: 270)
            }
            .buttonStyle(.plain).disabled(player.currentTrack == nil)
            Spacer(minLength: 8)
            PlayerControls(player: player)
            PlaybackProgress(player: player).frame(maxWidth: 340)
            Spacer(minLength: 8)
            Button("Queue", systemImage: "list.bullet") { showQueue.toggle() }
                .labelStyle(.iconOnly).help("Queue (⌘U)")
        }
        .padding(.horizontal, 16).frame(height: SemiquaverLayoutMode.expanded.playerHeight).background(.bar)
    }
}

extension Notification.Name { static let focusLibrarySearch = Notification.Name("Semiquaver.focusLibrarySearch") }
