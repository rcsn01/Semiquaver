import SwiftUI
import MoirasiaUI

enum Tab: String, CaseIterable {
    case library = "Library"
    case playlists = "Playlists"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .library: "music.note"
        case .playlists: "music.note.list"
        case .settings: "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("appTheme") private var appTheme: AppTheme = .automatic
    @StateObject private var model: IOSAppModel
    @State private var selectedTab: Tab = .library
    @State private var showNowPlaying = false

    init() {
        _model = StateObject(wrappedValue: IOSAppModel())
        #if DEBUG
        if let requested = ProcessInfo.processInfo.environment["SEMIQUAVER_START_TAB"]?.lowercased(),
           let tab = Tab.allCases.first(where: { $0.rawValue.lowercased() == requested }) {
            _selectedTab = State(initialValue: tab)
        }
        #endif
    }

    init(model: IOSAppModel) {
        _model = StateObject(wrappedValue: model)
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                IOSExpandedShell(
                    model: model,
                    appTheme: $appTheme,
                    showNowPlaying: $showNowPlaying
                )
            } else {
                compactShell
            }
        }
        .task { await model.start() }
        .sheet(isPresented: $showNowPlaying) {
            if let track = model.player.currentTrack {
                NowPlayingView(
                    track: track,
                    player: model.player,
                    library: model.library,
                    playlistStorage: model.playlists
                )
            }
        }
        .alert("Playback Error", isPresented: playbackErrorBinding) {
            Button("OK", role: .cancel) { model.player.clearError() }
        } message: { Text(model.player.errorMessage ?? "") }
        .tint(MoiraColor.textPrimary)
        .font(MoiraType.body())
        .foregroundStyle(MoiraColor.textPrimary)
        .preferredColorScheme(appTheme.colorScheme)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var compactShell: some View {
        TabView(selection: $selectedTab) {
            AudioTabView(
                library: model.library,
                player: model.player,
                playlists: model.playlists,
                showNowPlayingFullScreen: $showNowPlaying,
                onFolderPicked: { url in Task { await model.chooseFolder(url) } }
            )
            .toolbar(.hidden, for: .tabBar)
            .tabItem { Label(Tab.library.rawValue, systemImage: Tab.library.icon) }
            .tag(Tab.library)

            PlaylistsTabView(
                playlistStorage: model.playlists,
                library: model.library,
                player: model.player,
                showNowPlayingFullScreen: $showNowPlaying
            )
            .toolbar(.hidden, for: .tabBar)
            .tabItem { Label(Tab.playlists.rawValue, systemImage: Tab.playlists.icon) }
            .tag(Tab.playlists)

            NavigationStack {
                SettingsTabView(model: model, appTheme: $appTheme)
            }
            .toolbar(.hidden, for: .tabBar)
            .tabItem { Label(Tab.settings.rawValue, systemImage: Tab.settings.icon) }
            .tag(Tab.settings)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                if model.player.currentTrack != nil {
                    Button { showNowPlaying = true } label: {
                        MiniPlayerContent(player: model.player)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(MoiraColor.surfaceRaised, in: RoundedRectangle(cornerRadius: MoiraRadius.panel, style: .continuous))
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }

                SemiquaverGlassSelectionBar(Tab.allCases, selection: $selectedTab) { tab, isSelected in
                    VStack(spacing: 2) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                        Text(tab.rawValue)
                            .font(MoiraType.small(weight: isSelected ? .semibold : .medium))
                    }
                    .foregroundStyle(isSelected ? MoiraColor.textPrimary : MoiraColor.textMuted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
    }

    private var playbackErrorBinding: Binding<Bool> {
        Binding(get: { model.player.errorMessage != nil }, set: { if !$0 { model.player.clearError() } })
    }
}

private struct IOSExpandedShell: View {
    @ObservedObject var model: IOSAppModel
    @ObservedObject private var player: AudioPlayerController
    @ObservedObject private var library: AppMusicLibrary
    @ObservedObject private var playlists: PlaylistStorage
    @Binding var appTheme: AppTheme
    @Binding var showNowPlaying: Bool
    @State private var selection: LibraryDestination? = .songs
    @State private var query = ""
    @State private var showQueue = false
    @State private var creatingPlaylist = false
    @State private var newPlaylistName = ""
    @State private var renamingPlaylist: PlaylistItem?
    @State private var deletingPlaylist: PlaylistItem?

    init(
        model: IOSAppModel,
        appTheme: Binding<AppTheme>,
        showNowPlaying: Binding<Bool>
    ) {
        self.model = model
        _player = ObservedObject(wrappedValue: model.player)
        _library = ObservedObject(wrappedValue: model.library)
        _playlists = ObservedObject(wrappedValue: model.playlists)
        _appTheme = appTheme
        _showNowPlaying = showNowPlaying
    }

    var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView {
                List(selection: $selection) {
                    Section("Library") {
                        destinationLabel(.songs)
                        destinationLabel(.artists)
                        destinationLabel(.albums)
                    }
                    Section("Playlists") {
                        ForEach(playlists.playlists) { playlist in
                            Label(playlist.title, systemImage: "music.note.list")
                                .tag(LibraryDestination.playlist(playlist.id))
                                .contextMenu {
                                    Button("Rename") { newPlaylistName = playlist.title; renamingPlaylist = playlist }
                                    Button("Delete", role: .destructive) { deletingPlaylist = playlist }
                                }
                        }
                        Button("New Playlist", systemImage: "plus") { creatingPlaylist = true }
                    }
                    Section { destinationLabel(.settings) }
                }
                .navigationTitle("Semiquaver")
            } detail: {
                NavigationStack { expandedDetail }
                    .searchable(text: $query, prompt: "Songs, artists, albums, genres")
            }
            Divider()
            HStack(spacing: 18) {
                Button { showNowPlaying = true } label: {
                    MiniPlayerContent(player: player).frame(width: 280)
                }.buttonStyle(.plain).disabled(player.currentTrack == nil)
                PlayerControls(player: player)
                PlaybackProgress(player: player).frame(maxWidth: 360)
                Button("Queue", systemImage: "list.bullet") { showQueue = true }.labelStyle(.iconOnly)
            }
            .padding(.horizontal, 20).frame(height: SemiquaverLayoutMode.expanded.playerHeight).background(MoiraColor.surface)
        }
        .sheet(isPresented: $showQueue) { NavigationStack { QueueContent(player: player, layoutMode: .expanded) } }
        .alert("New Playlist", isPresented: $creatingPlaylist) {
            TextField("Playlist Name", text: $newPlaylistName)
            Button("Create") { if playlists.createPlaylist(title: newPlaylistName) { newPlaylistName = "" } }
            Button("Cancel", role: .cancel) { newPlaylistName = "" }
        }
        .alert("Rename Playlist", isPresented: Binding(get: { renamingPlaylist != nil }, set: { if !$0 { renamingPlaylist = nil } })) {
            TextField("Playlist Name", text: $newPlaylistName)
            Button("Rename") {
                if let playlist = renamingPlaylist { _ = playlists.renamePlaylist(id: playlist.id, title: newPlaylistName) }
                renamingPlaylist = nil; newPlaylistName = ""
            }
            Button("Cancel", role: .cancel) { renamingPlaylist = nil; newPlaylistName = "" }
        }
        .confirmationDialog("Delete Playlist?", isPresented: Binding(get: { deletingPlaylist != nil }, set: { if !$0 { deletingPlaylist = nil } })) {
            Button("Delete Playlist", role: .destructive) {
                if let playlist = deletingPlaylist { playlists.deletePlaylist(playlist) }
                deletingPlaylist = nil
            }
        }
    }

    private func destinationLabel(_ destination: LibraryDestination) -> some View {
        Label(destination.label, systemImage: destination.systemImage).tag(destination)
    }

    @ViewBuilder private var expandedDetail: some View {
        if library.isLoading && library.tracks.isEmpty { SemiquaverLoadingState() }
        else if let error = library.errorMessage {
            SemiquaverUnavailableState(title: "Library Unavailable", message: error, systemImage: "externaldrive.badge.exclamationmark")
        } else {
            switch selection ?? .songs {
            case .songs: trackList(LibrarySearch.tracks(library.songs, matching: query), title: "Songs", context: .library)
            case .artists: groupList(library.artists, kind: .artist)
            case .albums: groupList(library.albums, kind: .album)
            case .playlist(let id):
                if let playlist = playlists.playlists.first(where: { $0.id == id }) {
                    trackList(LibrarySearch.playlistTracks(playlist, allTracks: library.tracks, matching: query), title: playlist.title, context: .playlist(playlist))
                } else { SemiquaverUnavailableState(title: "Playlist Not Found", message: "This playlist is no longer available.", systemImage: "music.note.list") }
            case .settings: SettingsTabView(model: model, appTheme: $appTheme)
            }
        }
    }

    private func trackList(_ tracks: [AudioTrack], title: String, context: PlaybackContext) -> some View {
        List(tracks) { track in
            Button { player.play(track: track, in: tracks, context: context) } label: {
                TrackRow(track: track, isCurrent: player.isCurrentTrack(track), isPlaying: player.isPlaying, layoutMode: .expanded)
            }
            .buttonStyle(.plain)
            .swipeActions(edge: .leading) { Button("Queue") { player.addToQueue(track) } }
            .contextMenu {
                Button("Play") { player.play(track: track, in: tracks, context: context) }
                Button("Add to Queue") { player.addToQueue(track) }
                Menu("Add to Playlist") { ForEach(playlists.playlists) { playlist in Button(playlist.title) { playlists.addTrack(track.id, to: playlist) } } }
                if case .playlist(let playlist) = context {
                    Button("Remove from Playlist", role: .destructive) { playlists.removeTrack(track.id, from: playlist) }
                }
            }
        }
        .navigationTitle(title)
        .overlay { if tracks.isEmpty { SemiquaverUnavailableState(title: query.isEmpty ? "No Music" : "No Search Results", message: query.isEmpty ? "Choose a music folder in Settings." : "No matching available tracks.", systemImage: "music.note") } }
    }

    private func groupList(_ groups: [AudioGroupSummary], kind: AudioGroupKind) -> some View {
        let filtered = LibrarySearch.groups(groups, tracksForGroup: tracks(for:), matching: query)
        return List(filtered) { group in
            NavigationLink {
                let groupTracks = tracks(for: group)
                trackList(groupTracks, title: group.title, context: kind == .artist ? .artist(group.title) : .album(artist: groupTracks.first?.artist ?? AudioMetadataFallbacks.artist, title: group.title))
            } label: { MediaGroupRow(group: group, layoutMode: .expanded) }
        }
        .navigationTitle(kind == .artist ? "Artists" : "Albums")
        .overlay { if filtered.isEmpty { SemiquaverUnavailableState(title: "No Search Results", message: "Try a different search.", systemImage: "magnifyingglass") } }
    }

    private func tracks(for group: AudioGroupSummary) -> [AudioTrack] {
        switch group.kind {
        case .artist: library.tracksByArtist[group.title] ?? []
        case .album: library.tracksByAlbumID[String(group.id.dropFirst("album::".count))] ?? []
        case .genre: []
        }
    }
}

#Preview { ContentView() }
