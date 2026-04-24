import SwiftUI

struct PlaylistsTabView: View {
    @State private var showingCreatePlaylist = false

    var body: some View {
        PlayerScaffold(
            title: "Playlists",
            trailingSystemImage: "plus",
            trailingAction: { showingCreatePlaylist = true }
        ) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(MockLibrary.playlists) { playlist in
                        Button {
                            // TODO: Navigate to playlist detail
                        } label: {
                            PlaylistRow(playlist: playlist)
                                .padding(.horizontal, 4)
                        }
                        .buttonStyle(PressScaleButtonStyle())

                        if playlist.id != MockLibrary.playlists.last?.id {
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
}
