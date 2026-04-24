//
//  ContentView.swift
//  Semiquaver
//
//  Created by Ivan on 24/4/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            VideoTabView()
                .tabItem {
                    Label("Video", systemImage: "play.square.fill")
                }

            AudioTabView()
                .tabItem {
                    Label("Audio", systemImage: "music.note")
                }

            PlaylistsTabView()
                .tabItem {
                    Label("Playlists", systemImage: "music.note.list")
                }

            BrowseTabView()
                .tabItem {
                    Label("Browse", systemImage: "chart.bar.fill")
                }

            SettingsTabView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(Color.playerAccent)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
