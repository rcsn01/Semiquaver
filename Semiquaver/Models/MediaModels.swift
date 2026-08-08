import SwiftUI

enum LibraryDestination: Hashable, Identifiable {
    case songs
    case artists
    case albums
    case playlist(UUID)
    case settings

    var id: String {
        switch self {
        case .songs: "songs"
        case .artists: "artists"
        case .albums: "albums"
        case .playlist(let id): "playlist::\(id.uuidString)"
        case .settings: "settings"
        }
    }

    var label: String {
        switch self {
        case .songs: "Songs"
        case .artists: "Artists"
        case .albums: "Albums"
        case .playlist: "Playlist"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .songs: "music.note"
        case .artists: "music.mic"
        case .albums: "square.stack"
        case .playlist: "music.note.list"
        case .settings: "gearshape"
        }
    }
}

enum TrackActionDescriptor: String, CaseIterable, Identifiable, Sendable {
    case play
    case addToQueue
    case addToPlaylist
    case removeFromPlaylist
    case revealInFinder
    case removeFile

    var id: String { rawValue }
    var title: String {
        switch self {
        case .play: "Play"
        case .addToQueue: "Add to Queue"
        case .addToPlaylist: "Add to Playlist"
        case .removeFromPlaylist: "Remove from Playlist"
        case .revealInFinder: "Reveal in Finder"
        case .removeFile: "Remove File"
        }
    }
    var systemImage: String {
        switch self {
        case .play: "play.fill"
        case .addToQueue: "text.line.first.and.arrowtriangle.forward"
        case .addToPlaylist: "text.badge.plus"
        case .removeFromPlaylist: "text.badge.minus"
        case .revealInFinder: "folder"
        case .removeFile: "trash"
        }
    }
    var isDestructive: Bool { self == .removeFile }
}

enum LibrarySearch {
    static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    static func tracks(_ tracks: [AudioTrack], matching query: String) -> [AudioTrack] {
        let query = normalized(query)
        guard !query.isEmpty else { return tracks }
        return tracks.filter { track in
            [track.title, track.artist, track.album, track.genre]
                .contains { normalized($0).contains(query) }
        }
    }

    static func groups(
        _ groups: [AudioGroupSummary],
        tracksForGroup: (AudioGroupSummary) -> [AudioTrack],
        matching query: String
    ) -> [AudioGroupSummary] {
        let query = normalized(query)
        guard !query.isEmpty else { return groups }
        return groups.filter { group in
            normalized(group.title).contains(query)
                || normalized(group.subtitle).contains(query)
                || !tracks(tracksForGroup(group), matching: query).isEmpty
        }
    }

    static func playlistTracks(
        _ playlist: PlaylistItem,
        allTracks: [AudioTrack],
        matching query: String
    ) -> [AudioTrack] {
        let trackMap = Dictionary(uniqueKeysWithValues: allTracks.map { ($0.id, $0) })
        let contents = playlist.trackIDs.compactMap { trackMap[$0] }
        let query = normalized(query)
        guard !query.isEmpty else { return contents }
        return normalized(playlist.title).contains(query) ? contents : tracks(contents, matching: query)
    }
}

// MARK: - UI Models

struct MediaItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]
    var artworkData: Data? = nil

    init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String,
        icon: String,
        colors: [Color],
        artworkData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.colors = colors
        self.artworkData = artworkData
    }
}

struct PlaylistItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var detail: String
    var trackIDs: [String]

    init(id: UUID = UUID(), title: String, detail: String, trackIDs: [String] = []) {
        self.id = id
        self.title = title
        self.detail = detail
        self.trackIDs = trackIDs
    }

    var colors: [Color] {
        MediaArtworkPalette.colors(for: id.uuidString)
    }
}

// MARK: - Playback Context

enum PlaybackContext: Equatable {
    case library
    case album(artist: String, title: String)
    case artist(String)
    case genre(String)
    case playlist(PlaylistItem)

    var displayName: String {
        switch self {
        case .library:
            return "Library"
        case .album(let artist, let title):
            return "\(title) by \(artist)"
        case .artist(let name):
            return name
        case .genre(let name):
            return name
        case .playlist(let playlist):
            return playlist.title
        }
    }

    var shortName: String {
        switch self {
        case .library:
            return "Library"
        case .album(_, let title):
            return title
        case .artist(let name):
            return name
        case .genre(let name):
            return name
        case .playlist(let playlist):
            return playlist.title
        }
    }
}

struct BrowseTile: Identifiable {
    let id = UUID()
    let title: String
    let colors: [Color]
}

// MARK: - Audio Domain Models

enum AudioMetadataFallbacks {
    nonisolated static let artist = "Unknown Artist"
    nonisolated static let album = "Unknown Album"
    nonisolated static let genre = "Unknown Genre"
}

enum AudioGroupKind: Hashable, Sendable {
    case artist
    case album
    case genre
}

struct AudioTrack: Identifiable, Hashable, Sendable, Codable {
    let id: String
    let fileURL: URL
    let title: String
    let artist: String
    let album: String
    let genre: String
    let duration: TimeInterval
    let artworkData: Data?
    let lastModified: Date?

    var detailText: String {
        let parts = [
            artist == AudioMetadataFallbacks.artist ? nil : artist,
            album == AudioMetadataFallbacks.album ? nil : album
        ].compactMap { $0 }

        if parts.isEmpty {
            return durationText
        }

        return parts.joined(separator: " • ")
    }

    var durationText: String {
        formatAudioDuration(duration)
    }

    func mediaItem(isCurrent: Bool, isPlaying: Bool) -> MediaItem {
        let playbackState = isCurrent ? (isPlaying ? "Now Playing" : "Paused") : nil
        let subtitleParts = [playbackState, detailText].compactMap { $0 }
        let subtitle = subtitleParts.joined(separator: " • ")

        return MediaItem(
            id: id,
            title: title,
            subtitle: subtitle.isEmpty ? durationText : subtitle,
            icon: isCurrent && isPlaying ? "waveform" : "music.note",
            colors: isCurrent
                ? [Color.playerAccent.opacity(0.85), Color.playerAccent.opacity(0.55)]
                : MediaArtworkPalette.colors(for: id),
            artworkData: artworkData
        )
    }
}

struct AudioGroupSummary: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let kind: AudioGroupKind
    let artworkData: Data?

    var mediaItem: MediaItem {
        MediaItem(
            id: id,
            title: title,
            subtitle: subtitle,
            icon: kind.systemImage,
            colors: MediaArtworkPalette.colors(for: id),
            artworkData: artworkData
        )
    }
}

private extension AudioGroupKind {
    var systemImage: String {
        switch self {
        case .artist:
            return "person.2.fill"
        case .album:
            return "square.stack.fill"
        case .genre:
            return "guitars.fill"
        }
    }
}

// MARK: - Artwork Palette

enum MediaArtworkPalette {
    /// A curated set of sophisticated, muted color pairings for cover-art-style thumbnails.
    private static let palettes: [[Color]] = [
        // Sunset – warm amber to muted rose
        [Color(red: 0.90, green: 0.55, blue: 0.35),
         Color(red: 0.75, green: 0.40, blue: 0.45)],

        // Ocean – deep teal to slate
        [Color(red: 0.25, green: 0.50, blue: 0.55),
         Color(red: 0.15, green: 0.30, blue: 0.40)],

        // Sage – soft green to dusty blue
        [Color(red: 0.50, green: 0.60, blue: 0.50),
         Color(red: 0.35, green: 0.45, blue: 0.55)],

        // Berry – muted berry to deep plum
        [Color(red: 0.60, green: 0.35, blue: 0.50),
         Color(red: 0.40, green: 0.25, blue: 0.45)],

        // Stone – warm grey to cool charcoal
        [Color(red: 0.55, green: 0.55, blue: 0.55),
         Color(red: 0.30, green: 0.30, blue: 0.35)],

        // Dusk – soft violet to midnight blue
        [Color(red: 0.45, green: 0.40, blue: 0.65),
         Color(red: 0.20, green: 0.20, blue: 0.40)],

        // Sand – beige to dusty rose
        [Color(red: 0.75, green: 0.65, blue: 0.55),
         Color(red: 0.60, green: 0.45, blue: 0.45)],

        // Forest — deep olive to dark moss
        [Color(red: 0.35, green: 0.40, blue: 0.30),
         Color(red: 0.20, green: 0.25, blue: 0.20)]
    ]

    static func colors(for seed: String) -> [Color] {
        let scalarTotal = seed.unicodeScalars.reduce(into: 0) { partialResult, scalar in
            partialResult += Int(scalar.value)
        }
        let index = scalarTotal % palettes.count
        return palettes[index]
    }
}

// MARK: - Utilities

private func formatAudioDuration(_ duration: TimeInterval) -> String {
    let totalSeconds = max(Int(duration.rounded()), 0)
    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    return String(format: "%d:%02d", minutes, seconds)
}
