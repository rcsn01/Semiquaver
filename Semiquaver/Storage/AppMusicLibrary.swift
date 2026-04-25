import AVFoundation
import Combine
import Foundation

@MainActor
final class AppMusicLibrary: ObservableObject {
    @Published private(set) var tracks: [AudioTrack] = [] {
        didSet { rebuildDerivedCollections() }
    }
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    @Published private(set) var songs: [AudioTrack] = []
    @Published private(set) var artists: [AudioGroupSummary] = []
    @Published private(set) var albums: [AudioGroupSummary] = []

    @Published private(set) var tracksByArtist: [String: [AudioTrack]] = [:]
    @Published private(set) var tracksByAlbumID: [String: [AudioTrack]] = [:]

    init() {
        rebuildDerivedCollections()
    }

    private func rebuildDerivedCollections() {
        songs = tracks.sorted(by: Self.sortTracks)

        let artistMap = Dictionary(grouping: tracks, by: \.artist)
        tracksByArtist = artistMap.mapValues { $0.sorted(by: Self.sortTracks) }
        artists = artistMap
            .map { artist, groupedTracks in
                AudioGroupSummary(
                    id: "artist::\(artist)",
                    title: artist,
                    subtitle: Self.songCountLabel(groupedTracks.count),
                    kind: .artist,
                    artworkData: groupedTracks.first?.artworkData
                )
            }
            .sorted { Self.sortTitles($0.title, $1.title) }

        let albumMap = Dictionary(grouping: tracks) { track in
            "\(track.artist)::\(track.album)"
        }
        tracksByAlbumID = albumMap.mapValues { $0.sorted(by: Self.sortTracks) }
        albums = albumMap
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
                kind: .album,
                artworkData: firstTrack.artworkData
            )
        }
        .sorted { Self.sortTitles($0.title, $1.title) }
    }

    func reload(force: Bool = false) async {
        guard let musicFolderURL = AppMusicDirectory.ensureExists() else {
            tracks = []
            errorMessage = "Semiquaver couldn't access its Music folder."
            return
        }

        isLoading = true
        errorMessage = nil

        if !force, let cachedTracks = Self.loadCache() {
            tracks = cachedTracks
            isLoading = false

            let updatedTracks = await Task.detached(priority: .userInitiated) {
                await Self.incrementalScan(in: musicFolderURL, existingTracks: cachedTracks)
            }.value

            if !Self.isTrackListEqual(updatedTracks, tracks) {
                tracks = updatedTracks
                Self.saveCache(tracks: updatedTracks)
            }
        } else {
            let scannedTracks = await Task.detached(priority: .userInitiated) {
                await Self.scanTracks(in: musicFolderURL)
            }.value

            tracks = scannedTracks
            isLoading = false
            Self.saveCache(tracks: scannedTracks)
        }
    }

    private nonisolated static func cacheURL() -> URL? {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent("library_cache.json")
    }

    private nonisolated static func loadCache() -> [AudioTrack]? {
        guard let url = cacheURL(), FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let tracks = try JSONDecoder().decode([AudioTrack].self, from: data)
            return tracks
        } catch {
            print("Failed to load library cache: \(error)")
            return nil
        }
    }

    private nonisolated static func saveCache(tracks: [AudioTrack]) {
        guard let url = cacheURL() else { return }
        do {
            let data = try JSONEncoder().encode(tracks)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Failed to save library cache: \(error)")
        }
    }

    private nonisolated static func incrementalScan(in directoryURL: URL, existingTracks: [AudioTrack]) async -> [AudioTrack] {
        let fileManager = FileManager.default
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .contentModificationDateKey]
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
            return existingTracks
        }

        var trackByID = Dictionary(uniqueKeysWithValues: existingTracks.map { ($0.id, $0) })
        var foundIDs = Set<String>()

        while let fileURL = enumerator.nextObject() as? URL {
            guard supportedExtensions.contains(fileURL.pathExtension.lowercased()) else {
                continue
            }

            let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys))
            guard resourceValues?.isRegularFile == true else {
                continue
            }

            let fileID = fileURL.path
            foundIDs.insert(fileID)
            let modDate = resourceValues?.contentModificationDate

            if let existingTrack = trackByID[fileID], existingTrack.lastModified == modDate {
                continue
            }

            if let track = await makeTrack(from: fileURL, lastModified: modDate) {
                trackByID[fileID] = track
            }
        }

        let staleIDs = Set(trackByID.keys).subtracting(foundIDs)
        for staleID in staleIDs {
            trackByID.removeValue(forKey: staleID)
        }

        return trackByID.values.sorted(by: sortTracks)
    }

    private nonisolated static func isTrackListEqual(_ lhs: [AudioTrack], _ rhs: [AudioTrack]) -> Bool {
        let lhsIDs = lhs.map(\.id)
        let rhsIDs = rhs.map(\.id)
        return lhsIDs == rhsIDs
    }

    private nonisolated static func scanTracks(in directoryURL: URL) async -> [AudioTrack] {
        let fileManager = FileManager.default
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .contentModificationDateKey]
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

            let modDate = resourceValues?.contentModificationDate
            if let track = await makeTrack(from: fileURL, lastModified: modDate) {
                scannedTracks.append(track)
            }
        }

        return scannedTracks.sorted(by: sortTracks)
    }

    private nonisolated static func makeTrack(from fileURL: URL, lastModified: Date? = nil) async -> AudioTrack? {
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

        let artworkData = await extractArtworkData(from: metadata)

        return AudioTrack(
            id: fileURL.path,
            fileURL: fileURL,
            title: title,
            artist: artist,
            album: album,
            genre: genre,
            duration: duration,
            artworkData: artworkData,
            lastModified: lastModified
        )
    }

    private nonisolated static func extractArtworkData(from metadata: [AVMetadataItem]) async -> Data? {
        for item in metadata {
            let descriptors = metadataDescriptors(for: item)
            let isArtwork = descriptors.contains { descriptor in
                descriptor.contains("artwork") || descriptor.contains("image") || descriptor.contains("picture")
            }

            guard isArtwork else { continue }

            if let dataValue = try? await item.load(.dataValue), !dataValue.isEmpty {
                return dataValue
            }
        }
        return nil
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
