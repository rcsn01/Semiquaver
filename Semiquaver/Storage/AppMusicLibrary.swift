import AVFoundation
import Combine
import Foundation

@MainActor
final class AppMusicLibrary: ObservableObject {
    @Published private(set) var tracks: [AudioTrack] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    var songs: [AudioTrack] {
        tracks.sorted(by: Self.sortTracks)
    }

    var artists: [AudioGroupSummary] {
        Dictionary(grouping: tracks, by: \ .artist)
            .map { artist, groupedTracks in
                AudioGroupSummary(
                    id: "artist::\(artist)",
                    title: artist,
                    subtitle: Self.songCountLabel(groupedTracks.count),
                    kind: .artist
                )
            }
            .sorted { Self.sortTitles($0.title, $1.title) }
    }

    var albums: [AudioGroupSummary] {
        Dictionary(grouping: tracks) { track in
            "\(track.artist)::\(track.album)"
        }
        .values
        .compactMap { groupedTracks in
            guard let firstTrack = groupedTracks.first else {
                return nil
            }

            let subtitleParts = [
                firstTrack.artist == AudioMetadataFallbacks.artist ? nil : firstTrack.artist,
                Self.songCountLabel(groupedTracks.count)
            ].compactMap { $0 }

            return AudioGroupSummary(
                id: "album::\(firstTrack.artist)::\(firstTrack.album)",
                title: firstTrack.album,
                subtitle: subtitleParts.joined(separator: " • "),
                kind: .album
            )
        }
        .sorted { Self.sortTitles($0.title, $1.title) }
    }

    var genres: [AudioGroupSummary] {
        Dictionary(grouping: tracks, by: \ .genre)
            .map { genre, groupedTracks in
                AudioGroupSummary(
                    id: "genre::\(genre)",
                    title: genre,
                    subtitle: Self.songCountLabel(groupedTracks.count),
                    kind: .genre
                )
            }
            .sorted { Self.sortTitles($0.title, $1.title) }
    }

    func reload() async {
        guard let musicFolderURL = AppMusicDirectory.ensureExists() else {
            tracks = []
            errorMessage = "Semiquaver couldn't access its Music folder."
            return
        }

        isLoading = true
        errorMessage = nil

        let scannedTracks = await Task.detached(priority: .userInitiated) {
            await Self.scanTracks(in: musicFolderURL)
        }.value

        tracks = scannedTracks
        isLoading = false
    }

    private nonisolated static func scanTracks(in directoryURL: URL) async -> [AudioTrack] {
        let fileManager = FileManager.default
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey]
        let supportedExtensions: Set<String> = [
            "aac",
            "aiff",
            "alac",
            "caf",
            "flac",
            "m4a",
            "mp3",
            "mp4",
            "wav"
        ]

        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        var scannedTracks: [AudioTrack] = []

        while let fileURL = enumerator.nextObject() as? URL {
            guard supportedExtensions.contains(fileURL.pathExtension.lowercased()) else {
                continue
            }

            let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys))
            guard resourceValues?.isRegularFile == true else {
                continue
            }

            if let track = await makeTrack(from: fileURL) {
                scannedTracks.append(track)
            }
        }

        return scannedTracks.sorted(by: sortTracks)
    }

    private nonisolated static func makeTrack(from fileURL: URL) async -> AudioTrack? {
        let asset = AVURLAsset(url: fileURL)
        let unknownArtist = "Unknown Artist"
        let unknownAlbum = "Unknown Album"
        let unknownGenre = "Unknown Genre"
        let metadata = await allMetadata(from: asset)
        let title = await metadataValue(in: metadata, matching: ["title", "name"]) ?? fallbackTitle(for: fileURL)
        let artist = await metadataValue(in: metadata, matching: ["artist", "albumartist", "album artist", "creator", "author"]) ?? unknownArtist
        let album = await metadataValue(in: metadata, matching: ["album"], excluding: ["artist"]) ?? unknownAlbum
        let genre = await metadataValue(in: metadata, matching: ["genre", "contenttype", "content type"]) ?? unknownGenre

        let durationTime = try? await asset.load(.duration)
        let seconds = durationTime.map(CMTimeGetSeconds) ?? 0
        let duration = seconds.isFinite ? max(seconds, 0) : 0

        return AudioTrack(
            id: fileURL.path,
            fileURL: fileURL,
            title: title,
            artist: artist,
            album: album,
            genre: genre,
            duration: duration
        )
    }

    private nonisolated static func allMetadata(from asset: AVURLAsset) async -> [AVMetadataItem] {
        var metadata = (try? await asset.load(.commonMetadata)) ?? []
        let formats = (try? await asset.load(.availableMetadataFormats)) ?? []

        for format in formats {
            if let formatMetadata = try? await asset.loadMetadata(for: format) {
                metadata.append(contentsOf: formatMetadata)
            }
        }

        return metadata
    }

    private nonisolated static func metadataValue(
        in metadata: [AVMetadataItem],
        matching keywords: [String],
        excluding excludedKeywords: [String] = []
    ) async -> String? {
        for item in metadata {
            let descriptors = metadataDescriptors(for: item)
            let matchesKeyword = descriptors.contains { descriptor in
                keywords.contains(where: descriptor.contains)
            }
            let hitsExcludedKeyword = descriptors.contains { descriptor in
                excludedKeywords.contains(where: descriptor.contains)
            }

            guard matchesKeyword && !hitsExcludedKeyword else {
                continue
            }

            let stringValue = try? await item.load(.stringValue)
            if let cleanedValue = cleaned(stringValue) {
                return cleanedValue
            }
        }

        return nil
    }

    private nonisolated static func metadataDescriptors(for item: AVMetadataItem) -> [String] {
        [
            item.commonKey?.rawValue,
            item.identifier?.rawValue,
            item.key as? String
        ]
        .compactMap { $0?.lowercased() }
    }

    private nonisolated static func cleaned(_ value: String?) -> String? {
        guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmedValue.isEmpty else {
            return nil
        }

        return trimmedValue
    }

    private nonisolated static func fallbackTitle(for fileURL: URL) -> String {
        fileURL.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ")
    }

    private nonisolated static func sortTracks(_ lhs: AudioTrack, _ rhs: AudioTrack) -> Bool {
        if sortTitles(lhs.title, rhs.title) {
            return true
        }

        if sortTitles(rhs.title, lhs.title) {
            return false
        }

        return sortTitles(lhs.artist, rhs.artist)
    }

    private nonisolated static func sortTitles(_ lhs: String, _ rhs: String) -> Bool {
        lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
    }

    private nonisolated static func songCountLabel(_ count: Int) -> String {
        if count == 1 {
            return "1 song"
        }

        return "\(count) songs"
    }
}