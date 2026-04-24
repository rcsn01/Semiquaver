import SwiftUI
import UIKit

// MARK: - UI Models

struct MediaItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]
    var artwork: UIImage? = nil

    init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String,
        icon: String,
        colors: [Color],
        artwork: UIImage? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.colors = colors
        self.artwork = artwork
    }
}

struct PlaylistItem: Identifiable, Codable {
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

struct BrowseTile: Identifiable {
    let id = UUID()
    let title: String
    let colors: [Color]
}

// MARK: - Audio Domain Models

enum AudioMetadataFallbacks {
    static let artist = "Unknown Artist"
    static let album = "Unknown Album"
    static let genre = "Unknown Genre"
}

enum AudioGroupKind: Sendable {
    case artist
    case album
    case genre
}

struct AudioTrack: Identifiable, Hashable, Sendable {
    let id: String
    let fileURL: URL
    let title: String
    let artist: String
    let album: String
    let genre: String
    let duration: TimeInterval
    let artworkData: Data?

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

        var artworkImage: UIImage?
        if let artworkData {
            artworkImage = UIImage(data: artworkData)
        }

        return MediaItem(
            id: id,
            title: title,
            subtitle: subtitle.isEmpty ? durationText : subtitle,
            icon: isCurrent && isPlaying ? "waveform" : "music.note",
            colors: isCurrent
                ? [Color.playerAccent.opacity(0.85), Color.orange.opacity(0.55)]
                : MediaArtworkPalette.colors(for: id),
            artwork: artworkImage
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
        var artworkImage: UIImage?
        if let artworkData {
            artworkImage = UIImage(data: artworkData)
        }

        return MediaItem(
            id: id,
            title: title,
            subtitle: subtitle,
            icon: kind.systemImage,
            colors: MediaArtworkPalette.colors(for: id),
            artwork: artworkImage
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
