import SwiftUI

struct PlaylistsTabView: View {
    @ObservedObject var playlistStorage: PlaylistStorage
    @ObservedObject var library: AppMusicLibrary
    @ObservedObject var player: AudioPlayerController
    @Binding var showNowPlayingFullScreen: Bool
    @State private var showingCreatePlaylist = false
    @State private var newPlaylistTitle = ""
    @State private var playlistToRename: PlaylistItem?
    @State private var playlistToDelete: PlaylistItem?
    @State private var editedTitle = ""

    var body: some View {
        PlayerScaffold(
            title: "Playlists",
            trailingSystemImage: "plus",
            trailingAction: { showingCreatePlaylist = true }
        ) {
            NavigationStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(playlistStorage.playlists) { playlist in
                            NavigationLink {
                                PlaylistDetailView(
                                    playlist: playlist,
                                    allTracks: library.tracks,
                                    playlistStorage: playlistStorage,
                                    player: player,
                                    showNowPlayingFullScreen: $showNowPlayingFullScreen
                                )
                            } label: {
                                PlaylistRow(playlist: playlist)
                                    .padding(.horizontal, 4)
                            }
                            .buttonStyle(PressScaleButtonStyle())
                            .contextMenu {
                                Button("Rename") {
                                    editedTitle = playlist.title
                                    playlistToRename = playlist
                                }
                                Button("Delete", role: .destructive) { playlistToDelete = playlist }
                            }

                            if playlist.id != playlistStorage.playlists.last?.id {
                                Divider()
                                    .overlay(Color.playerDivider)
                                    .padding(.leading, 76)
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                    .padding(.horizontal, 12)
                }
            }
        }
        .alert("New Playlist", isPresented: $showingCreatePlaylist) {
            TextField("Playlist Name", text: $newPlaylistTitle)
            Button("Create") {
                guard playlistStorage.createPlaylist(title: newPlaylistTitle) else { return }
                newPlaylistTitle = ""
            }
            Button("Cancel", role: .cancel) {
                newPlaylistTitle = ""
            }
        } message: {
            Text("Enter a name for your new playlist.")
        }
        .alert("Rename Playlist", isPresented: Binding(
            get: { playlistToRename != nil },
            set: { if !$0 { playlistToRename = nil } }
        )) {
            TextField("Playlist Name", text: $editedTitle)
            Button("Rename") {
                if let playlistToRename { _ = playlistStorage.renamePlaylist(id: playlistToRename.id, title: editedTitle) }
                playlistToRename = nil
            }
            Button("Cancel", role: .cancel) { playlistToRename = nil }
        }
        .confirmationDialog("Delete Playlist?", isPresented: Binding(
            get: { playlistToDelete != nil },
            set: { if !$0 { playlistToDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete Playlist", role: .destructive) {
                if let playlistToDelete { playlistStorage.deletePlaylist(playlistToDelete) }
                playlistToDelete = nil
            }
            Button("Cancel", role: .cancel) { playlistToDelete = nil }
        }
    }
}
