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

private struct PlayerScaffold<Content: View>: View {
    let title: String
    var trailingSystemImage: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            PlayerBackground()

            VStack(spacing: 0) {
                header
                Divider()
                    .overlay(Color.playerDivider)
                content()
            }
        }
    }

    private var header: some View {
        ZStack {
            Text(title)
                .font(.system(size: 43, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            HStack {
                Spacer()
                if let trailingSystemImage {
                    Button {
                    } label: {
                        Image(systemName: trailingSystemImage)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(Color.playerAccent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.trailing, 18)
        }
        .padding(.top, 10)
        .padding(.bottom, 14)
    }
}

private struct PlayerBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.playerSurfaceTop, Color.playerSurfaceBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.playerAccent.opacity(0.13))
                .frame(width: 230)
                .blur(radius: 80)
                .offset(x: 170, y: -360)

            Circle()
                .fill(.blue.opacity(0.07))
                .frame(width: 300)
                .blur(radius: 90)
                .offset(x: -210, y: 260)
        }
    }
}

private struct VideoTabView: View {
    var body: some View {
        PlayerScaffold(title: "Video") {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Now Playing")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.playerTextSecondary)

                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.playerAccent.opacity(0.35), .blue.opacity(0.35)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 210)
                            .overlay(alignment: .bottomLeading) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Night Drive Sessions")
                                        .font(.system(size: 23, weight: .semibold, design: .rounded))
                                    Text("Synthwave Visual Mix - 43:12")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(Color.playerTextSecondary)
                                }
                                .padding(18)
                            }
                    }

                    Text("Recently Added")
                        .font(.system(size: 30, weight: .bold, design: .rounded))

                    VStack(spacing: 0) {
                        ForEach(MockLibrary.videos) { item in
                            MediaRow(item: item, showsChevron: true)
                            if item.id != MockLibrary.videos.last?.id {
                                Divider()
                                    .overlay(Color.playerDivider)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 36)
            }
        }
    }
}

private enum AudioCategory: String, CaseIterable {
    case artists = "Artists"
    case albums = "Albums"
    case songs = "Songs"
    case genres = "Genres"
}

private struct AudioTabView: View {
    @State private var selectedCategory: AudioCategory = .songs

    private var items: [MediaItem] {
        switch selectedCategory {
        case .artists:
            MockLibrary.artists
        case .albums:
            MockLibrary.albums
        case .songs:
            MockLibrary.songs
        case .genres:
            MockLibrary.genres
        }
    }

    var body: some View {
        PlayerScaffold(title: "Audio", trailingSystemImage: "ellipsis.circle") {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(AudioCategory.allCases, id: \.self) { category in
                        categoryButton(category)
                    }
                }
                .padding(.top, 4)

                Divider()
                    .overlay(Color.playerDivider)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(items) { item in
                            MediaRow(item: item)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private func categoryButton(_ category: AudioCategory) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            selectedCategory = category
        } label: {
            VStack(spacing: 12) {
                Text(category.rawValue)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? Color.playerAccent : Color.playerMuted)
                    .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(isSelected ? Color.playerAccent : .clear)
                    .frame(height: 4)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct PlaylistsTabView: View {
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

private struct BrowseTabView: View {
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        PlayerScaffold(title: "Browse", trailingSystemImage: "magnifyingglass.circle") {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Discover")
                        .font(.system(size: 30, weight: .bold, design: .rounded))

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(MockLibrary.browseTiles) { tile in
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: tile.colors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 120)
                                .overlay(alignment: .bottomLeading) {
                                    Text(tile.title)
                                        .font(.system(size: 19, weight: .bold, design: .rounded))
                                        .padding(12)
                                }
                        }
                    }

                    Text("Trending Artists")
                        .font(.system(size: 26, weight: .bold, design: .rounded))

                    VStack(spacing: 0) {
                        ForEach(MockLibrary.artists.prefix(4)) { item in
                            MediaRow(item: item, showsChevron: true)
                            if item.id != MockLibrary.artists.prefix(4).last?.id {
                                Divider()
                                    .overlay(Color.playerDivider)
                            }
                        }
                    }
                    .background(.black.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 34)
            }
        }
    }
}

private struct SettingsTabView: View {
    @State private var playVideoFullscreen = true
    @State private var enableTextScrolling = false
    @State private var rememberPlayerState = true
    @State private var restoreLastPlayedMedia = false

    var body: some View {
        ZStack {
            PlayerBackground()

            VStack(spacing: 0) {
                HStack {
                    Button("About") {}
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.playerAccent)

                    Spacer()

                    Text("Settings")
                        .font(.system(size: 43, weight: .semibold, design: .rounded))

                    Spacer()

                    Button("Documentation") {}
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.playerAccent)
                }
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 16)

                Divider()
                    .overlay(Color.playerDivider)

                ScrollView(showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 0) {
                        SettingsLinkRow(
                            title: "Privacy",
                            subtitle: "Open in Settings"
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsLinkRow(
                            title: "Appearance",
                            subtitle: "Automatic"
                        )

                        sectionGap

                        SettingsLinkRow(
                            title: "Make a Donation to VideoLAN",
                            subtitle: "Support free and open source multimedia"
                        )

                        sectionGap

                        Text("Generic")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)

                        SettingsLinkRow(
                            title: "Default playback speed",
                            subtitle: "1.00x"
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsLinkRow(
                            title: "Continue audio playback",
                            subtitle: "Always",
                            showsInfo: true
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsToggleRow(
                            title: "Play video in fullscreen",
                            subtitle: nil,
                            isOn: $playVideoFullscreen
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsLinkRow(
                            title: "Continue video playback",
                            subtitle: "Always",
                            showsInfo: true
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsLinkRow(
                            title: "Automatically play next item",
                            subtitle: nil
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsToggleRow(
                            title: "Enable text scrolling in media list",
                            subtitle: nil,
                            isOn: $enableTextScrolling
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsToggleRow(
                            title: "Remember player state (shuffle, loop)",
                            subtitle: nil,
                            isOn: $rememberPlayerState
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsToggleRow(
                            title: "Restore last played media on launch",
                            subtitle: "Not applicable to externally stored media",
                            isOn: $restoreLastPlayedMedia
                        )
                    }
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private var sectionGap: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: 26)
            .overlay(alignment: .top) {
                Divider().overlay(Color.playerDivider)
            }
            .overlay(alignment: .bottom) {
                Divider().overlay(Color.playerDivider)
            }
    }
}

private struct MediaRow: View {
    let item: MediaItem
    var showsChevron = false

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: item.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 58, height: 58)
                .overlay {
                    Image(systemName: item.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.playerTextSecondary)
                    .lineLimit(1)
            }

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.playerAccent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

private struct PlaylistRow: View {
    let playlist: PlaylistItem

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: playlist.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 58, height: 58)
                .overlay {
                    Image(systemName: "music.note")
                        .foregroundStyle(.white.opacity(0.84))
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(playlist.title)
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                Text(playlist.detail)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.playerTextSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.playerAccent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct SettingsLinkRow: View {
    let title: String
    let subtitle: String?
    var showsInfo = false

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.playerTextSecondary)
                }
            }

            Spacer()

            if showsInfo {
                Image(systemName: "info.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.playerAccent)
                    .padding(.trailing, 10)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.playerMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.playerTextSecondary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.playerAccent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private struct MediaItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]
}

private struct PlaylistItem: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let colors: [Color]
}

private struct BrowseTile: Identifiable {
    let id = UUID()
    let title: String
    let colors: [Color]
}

private enum MockLibrary {
    static let songs: [MediaItem] = [
        MediaItem(
            title: "#icanteven (feat. French Montana)",
            subtitle: "The Neighbourhood - French Montana",
            icon: "music.note",
            colors: [.black, .white.opacity(0.85)]
        ),
        MediaItem(
            title: "10 Mile Stereo",
            subtitle: "Beach House - Unknown Album",
            icon: "music.mic",
            colors: [.gray, .indigo.opacity(0.7)]
        ),
        MediaItem(
            title: "10:37",
            subtitle: "Beach House - Depression Cherry",
            icon: "dot.radiowaves.left.and.right",
            colors: [.red.opacity(0.95), .red.opacity(0.45)]
        ),
        MediaItem(
            title: "123",
            subtitle: "Claire Rosinkranz - Unknown Album",
            icon: "number",
            colors: [.orange, .brown.opacity(0.8)]
        ),
        MediaItem(
            title: "21",
            subtitle: "Gracie Abrams - minor",
            icon: "sparkles",
            colors: [.white.opacity(0.95), .pink.opacity(0.55)]
        ),
        MediaItem(
            title: "4EVER",
            subtitle: "Clairo - 4EVER",
            icon: "heart.fill",
            colors: [.teal, .purple.opacity(0.7)]
        )
    ]

    static let albums: [MediaItem] = [
        MediaItem(
            title: "#000000 & #FFFFFF",
            subtitle: "Various Artists",
            icon: "square.split.2x1",
            colors: [.black, .white.opacity(0.84)]
        ),
        MediaItem(
            title: "((((ultraSOUND))))",
            subtitle: "The Neighbourhood",
            icon: "speaker.wave.3.fill",
            colors: [.gray.opacity(0.85), .black]
        ),
        MediaItem(
            title: "0.1 flaws and all.",
            subtitle: "wave to earth",
            icon: "waveform.path.ecg",
            colors: [.white.opacity(0.9), .mint.opacity(0.35)]
        ),
        MediaItem(
            title: "19",
            subtitle: "Adele",
            icon: "person.fill",
            colors: [.brown.opacity(0.95), .black.opacity(0.8)]
        ),
        MediaItem(
            title: "1989 (Taylor's Version)",
            subtitle: "Taylor Swift",
            icon: "bird.fill",
            colors: [.blue.opacity(0.95), .cyan.opacity(0.7)]
        )
    ]

    static let artists: [MediaItem] = [
        MediaItem(
            title: "The Neighbourhood",
            subtitle: "85 songs",
            icon: "person.2.fill",
            colors: [.black, .gray]
        ),
        MediaItem(
            title: "Beach House",
            subtitle: "61 songs",
            icon: "sun.horizon.fill",
            colors: [.blue, .indigo]
        ),
        MediaItem(
            title: "Clairo",
            subtitle: "24 songs",
            icon: "star.fill",
            colors: [.pink, .purple]
        ),
        MediaItem(
            title: "Adele",
            subtitle: "17 songs",
            icon: "music.quarternote.3",
            colors: [.orange, .brown]
        )
    ]

    static let genres: [MediaItem] = [
        MediaItem(
            title: "Indie Pop",
            subtitle: "312 tracks",
            icon: "music.note.house.fill",
            colors: [.purple.opacity(0.8), .blue.opacity(0.8)]
        ),
        MediaItem(
            title: "Alternative",
            subtitle: "201 tracks",
            icon: "guitars.fill",
            colors: [.teal, .mint]
        ),
        MediaItem(
            title: "R&B",
            subtitle: "76 tracks",
            icon: "beats.headphones",
            colors: [.red, .pink]
        ),
        MediaItem(
            title: "Lo-fi",
            subtitle: "143 tracks",
            icon: "moon.stars.fill",
            colors: [.indigo, .black]
        )
    ]

    static let playlists: [PlaylistItem] = [
        PlaylistItem(
            title: "Fav",
            detail: "1 Track - 03:50",
            colors: [.purple.opacity(0.8), .blue.opacity(0.8)]
        ),
        PlaylistItem(
            title: "Roadtrip PM",
            detail: "28 Tracks - 1:46:03",
            colors: [.orange.opacity(0.85), .red.opacity(0.85)]
        ),
        PlaylistItem(
            title: "Coding Flow",
            detail: "52 Tracks - 3:11:40",
            colors: [.mint.opacity(0.8), .teal.opacity(0.95)]
        )
    ]

    static let videos: [MediaItem] = [
        MediaItem(
            title: "Live at Red Rocks",
            subtitle: "Arctic Monkeys - 1:31:10",
            icon: "play.tv.fill",
            colors: [.red.opacity(0.9), .orange.opacity(0.9)]
        ),
        MediaItem(
            title: "Lo-fi City Nights",
            subtitle: "Ambient Reel - 24:09",
            icon: "film.stack.fill",
            colors: [.indigo.opacity(0.9), .blue.opacity(0.9)]
        ),
        MediaItem(
            title: "Studio Session 07",
            subtitle: "Behind the scenes - 11:34",
            icon: "video.fill",
            colors: [.mint.opacity(0.9), .teal.opacity(0.9)]
        )
    ]

    static let browseTiles: [BrowseTile] = [
        BrowseTile(title: "Fresh Finds", colors: [.orange.opacity(0.8), .pink.opacity(0.7)]),
        BrowseTile(title: "Night Shift", colors: [.indigo.opacity(0.9), .blue.opacity(0.7)]),
        BrowseTile(title: "Live Sets", colors: [.mint.opacity(0.8), .teal.opacity(0.7)]),
        BrowseTile(title: "Acoustic", colors: [.yellow.opacity(0.8), .orange.opacity(0.7)])
    ]
}

private extension Color {
    static let playerSurfaceTop = Color(red: 0.07, green: 0.09, blue: 0.13)
    static let playerSurfaceBottom = Color(red: 0.05, green: 0.07, blue: 0.10)
    static let playerAccent = Color(red: 1.0, green: 0.60, blue: 0.02)
    static let playerTextSecondary = Color.white.opacity(0.56)
    static let playerMuted = Color.white.opacity(0.58)
    static let playerDivider = Color.white.opacity(0.09)
}

#Preview {
    ContentView()
}
