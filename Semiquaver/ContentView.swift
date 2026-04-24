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

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .library:
                    AudioTabView()
                case .playlists:
                    PlaylistsTabView()
                case .settings:
                    SettingsTabView()
                }
            }

            customTabBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .preferredColorScheme(.dark)
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
            .background(Color.playerSurface)
        }
    }
}

#Preview {
    ContentView()
}
