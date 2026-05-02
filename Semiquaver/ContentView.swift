//
//  ContentView.swift
//  Semiquaver
//
//  Created by Ivan on 24/4/2026.
//

import SwiftUI

enum Tab: String, CaseIterable {
    case library = "Library"
    case playlists = "Playlists"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .library: return "music.note"
        case .playlists: return "music.note.list"
        case .settings: return "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: Tab = .library
    @StateObject private var player = AudioPlayerController()
    @StateObject private var library = AppMusicLibrary()
    @State private var showNowPlayingFullScreen = false

    var body: some View {
        Group {
            switch selectedTab {
            case .library:
                AudioTabView(library: library, player: player, showNowPlayingFullScreen: $showNowPlayingFullScreen)
            case .playlists:
                PlaylistsTabView(player: player, showNowPlayingFullScreen: $showNowPlayingFullScreen)
            case .settings:
                SettingsTabView(player: player)
            }
        }
        .task {
            await library.reload()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let currentTrack = player.currentTrack {
                Button {
                    showNowPlayingFullScreen = true
                } label: {
                    NowPlayingBar(track: currentTrack, player: player)
                }
                .buttonStyle(PressScaleButtonStyle())
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customTabBar
        }
        .sheet(isPresented: $showNowPlayingFullScreen) {
            if let currentTrack = player.currentTrack {
                NowPlayingView(track: currentTrack, player: player, library: library)
            }
        }
        .alert("Playback Error", isPresented: playbackErrorBinding) {
            Button("OK", role: .cancel) {
                player.clearError()
            }
        } message: {
            Text(player.errorMessage ?? "")
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var playbackErrorBinding: Binding<Bool> {
        Binding(
            get: { player.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    player.clearError()
                }
            }
        )
    }

    private var customTabBar: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color.playerDivider)

            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: selectedTab == tab ? .bold : .medium))
                            Text(tab.rawValue)
                                .font(.captionSmall())
                        }
                        .foregroundStyle(selectedTab == tab ? Color.playerAccent : Color.playerTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
        .background(Color.playerSurface)
    }
}

#Preview {
    ContentView()
}
