import SwiftUI

struct PlaylistsTabView: View {
    var body: some View {
        PlayerScaffold(title: "Playlists", trailingSystemImage: "ellipsis.circle") {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(MockLibrary.playlists) { playlist in
                        PlaylistRow(playlist: playlist)
                        Divider()
                            .overlay(Color.playerDivider)
                            .padding(.leading, 90)
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 32)
            }
        }
    }
}
