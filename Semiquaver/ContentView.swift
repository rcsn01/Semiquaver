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
            AudioTabView()
                .tabItem {
                    Label("Audio", systemImage: "music.note")
                }

            PlaylistsTabView()
                .tabItem {
                    Label("Playlists", systemImage: "music.note.list")
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
