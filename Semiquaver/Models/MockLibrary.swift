import SwiftUI

enum MockLibrary {
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
