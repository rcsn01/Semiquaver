import SwiftUI

struct PlaylistsTabView: View {
    @StateObject private var playlistStorage = PlaylistStorage()
    @ObservedObject var player: AudioPlayerController
    @Binding var showNowPlayingFullScreen: Bool
    @State private var showingCreatePlaylist = false
    @State private var newPlaylistTitle = ""

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
                                    allTracks: [],
                                    player: player,
                                    showNowPlayingFullScreen: $showNowPlayingFullScreen
                                )
                            } label: {
                                PlaylistRow(playlist: playlist)
                                    .padding(.horizontal, 4)
                            }
                            .buttonStyle(PressScaleButtonStyle())

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
                guard !newPlaylistTitle.isEmpty else { return }
                playlistStorage.createPlaylist(title: newPlaylistTitle)
                newPlaylistTitle = ""
            }
            Button("Cancel", role: .cancel) {
                newPlaylistTitle = ""
            }
        } message: {
            Text("Enter a name for your new playlist.")
        }
    }
}
