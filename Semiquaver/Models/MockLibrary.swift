import SwiftUI

enum MockLibrary {
    static let songs: [MediaItem] = [
        MediaItem(
            title: "#icanteven (feat. French Montana)",
            subtitle: "The Neighbourhood - French Montana",
            icon: "music.note",
            colors: MediaArtworkPalette.colors(for: "song-1")
        ),
        MediaItem(
            title: "10 Mile Stereo",
            subtitle: "Beach House - Unknown Album",
            icon: "music.mic",
            colors: MediaArtworkPalette.colors(for: "song-2")
        ),
        MediaItem(
            title: "10:37",
            subtitle: "Beach House - Depression Cherry",
            icon: "dot.radiowaves.left.and.right",
            colors: MediaArtworkPalette.colors(for: "song-3")
        ),
        MediaItem(
            title: "123",
            subtitle: "Claire Rosinkranz - Unknown Album",
            icon: "number",
            colors: MediaArtworkPalette.colors(for: "song-4")
        ),
        MediaItem(
            title: "21",
            subtitle: "Gracie Abrams - minor",
            icon: "sparkles",
            colors: MediaArtworkPalette.colors(for: "song-5")
        ),
        MediaItem(
            title: "4EVER",
            subtitle: "Clairo - 4EVER",
            icon: "heart.fill",
            colors: MediaArtworkPalette.colors(for: "song-6")
        )
    ]

    static let albums: [MediaItem] = [
        MediaItem(
            title: "#000000 & #FFFFFF",
            subtitle: "Various Artists",
            icon: "square.split.2x1",
            colors: MediaArtworkPalette.colors(for: "album-1")
        ),
        MediaItem(
            title: "((((ultraSOUND))))",
            subtitle: "The Neighbourhood",
            icon: "speaker.wave.3.fill",
            colors: MediaArtworkPalette.colors(for: "album-2")
        ),
        MediaItem(
            title: "0.1 flaws and all.",
            subtitle: "wave to earth",
            icon: "waveform.path.ecg",
            colors: MediaArtworkPalette.colors(for: "album-3")
        ),
        MediaItem(
            title: "19",
            subtitle: "Adele",
            icon: "person.fill",
            colors: MediaArtworkPalette.colors(for: "album-4")
        ),
        MediaItem(
            title: "1989 (Taylor's Version)",
            subtitle: "Taylor Swift",
            icon: "bird.fill",
            colors: MediaArtworkPalette.colors(for: "album-5")
        )
    ]

    static let artists: [MediaItem] = [
        MediaItem(
            title: "The Neighbourhood",
            subtitle: "85 songs",
            icon: "person.2.fill",
            colors: MediaArtworkPalette.colors(for: "artist-1")
        ),
        MediaItem(
            title: "Beach House",
            subtitle: "61 songs",
            icon: "sun.horizon.fill",
            colors: MediaArtworkPalette.colors(for: "artist-2")
        ),
        MediaItem(
            title: "Clairo",
            subtitle: "24 songs",
            icon: "star.fill",
            colors: MediaArtworkPalette.colors(for: "artist-3")
        ),
        MediaItem(
            title: "Adele",
            subtitle: "17 songs",
            icon: "music.quarternote.3",
            colors: MediaArtworkPalette.colors(for: "artist-4")
        )
    ]

    static let genres: [MediaItem] = [
        MediaItem(
            title: "Indie Pop",
            subtitle: "312 tracks",
            icon: "music.note.house.fill",
            colors: MediaArtworkPalette.colors(for: "genre-1")
        ),
        MediaItem(
            title: "Alternative",
            subtitle: "201 tracks",
            icon: "guitars.fill",
            colors: MediaArtworkPalette.colors(for: "genre-2")
        ),
        MediaItem(
            title: "R&B",
            subtitle: "76 tracks",
            icon: "beats.headphones",
            colors: MediaArtworkPalette.colors(for: "genre-3")
        ),
        MediaItem(
            title: "Lo-fi",
            subtitle: "143 tracks",
            icon: "moon.stars.fill",
            colors: MediaArtworkPalette.colors(for: "genre-4")
        )
    ]

    static let playlists: [PlaylistItem] = [
        PlaylistItem(
            title: "Fav",
            detail: "0 songs",
            trackIDs: []
        ),
        PlaylistItem(
            title: "Roadtrip PM",
            detail: "0 songs",
            trackIDs: []
        ),
        PlaylistItem(
            title: "Coding Flow",
            detail: "0 songs",
            trackIDs: []
        )
    ]

    static let videos: [MediaItem] = [
        MediaItem(
            title: "Live at Red Rocks",
            subtitle: "Arctic Monkeys - 1:31:10",
            icon: "play.tv.fill",
            colors: MediaArtworkPalette.colors(for: "video-1")
        ),
        MediaItem(
            title: "Lo-fi City Nights",
            subtitle: "Ambient Reel - 24:09",
            icon: "film.stack.fill",
            colors: MediaArtworkPalette.colors(for: "video-2")
        ),
        MediaItem(
            title: "Studio Session 07",
            subtitle: "Behind the scenes - 11:34",
            icon: "video.fill",
            colors: MediaArtworkPalette.colors(for: "video-3")
        )
    ]

    static let browseTiles: [BrowseTile] = [
        BrowseTile(
            title: "Fresh Finds",
            colors: MediaArtworkPalette.colors(for: "browse-1")
        ),
        BrowseTile(
            title: "Night Shift",
            colors: MediaArtworkPalette.colors(for: "browse-2")
        ),
        BrowseTile(
            title: "Live Sets",
            colors: MediaArtworkPalette.colors(for: "browse-3")
        ),
        BrowseTile(
            title: "Acoustic",
            colors: MediaArtworkPalette.colors(for: "browse-4")
        )
    ]
}
