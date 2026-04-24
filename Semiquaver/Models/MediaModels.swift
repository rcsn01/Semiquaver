import SwiftUI

struct MediaItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]

    init(id: String = UUID().uuidString, title: String, subtitle: String, icon: String, colors: [Color]) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.colors = colors
    }
}

struct PlaylistItem: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let colors: [Color]
}

struct BrowseTile: Identifiable {
    let id = UUID()
    let title: String
    let colors: [Color]
}

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
            icon: isCurrent && isPlaying ? "speaker.wave.2.fill" : "music.note",
            colors: isCurrent
                ? [Color.playerAccent.opacity(0.95), Color.orange.opacity(0.65)]
                : MediaArtworkPalette.colors(for: id)
        )
    }
}

struct AudioGroupSummary: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let kind: AudioGroupKind

    var mediaItem: MediaItem {
        MediaItem(
            id: id,
            title: title,
            subtitle: subtitle,
            icon: kind.systemImage,
            colors: MediaArtworkPalette.colors(for: id)
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

enum MediaArtworkPalette {
    private static let palettes: [[Color]] = [
        [Color.playerAccent.opacity(0.85), Color.orange.opacity(0.60)],
        [Color.blue.opacity(0.85), Color.indigo.opacity(0.72)],
        [Color.teal.opacity(0.88), Color.mint.opacity(0.62)],
        [Color.pink.opacity(0.82), Color.red.opacity(0.62)],
        [Color.gray.opacity(0.86), Color.white.opacity(0.46)],
        [Color.cyan.opacity(0.80), Color.blue.opacity(0.58)]
    ]

    static func colors(for seed: String) -> [Color] {
        let scalarTotal = seed.unicodeScalars.reduce(into: 0) { partialResult, scalar in
            partialResult += Int(scalar.value)
        }
        let index = scalarTotal % palettes.count
        return palettes[index]
    }
}

private func formatAudioDuration(_ duration: TimeInterval) -> String {
    let totalSeconds = max(Int(duration.rounded()), 0)
    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    return String(format: "%d:%02d", minutes, seconds)
}
