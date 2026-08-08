import AVFoundation
import Foundation

private struct CachedTrack: Codable, Sendable {
    let sourceID: UUID
    let relativePath: String
    let modificationDate: Date?
    let track: AudioTrack
}

@MainActor
final class AppMusicLibrary: ObservableObject {
    @Published private(set) var tracks: [AudioTrack] = [] { didSet { rebuild() } }
    @Published private(set) var songs: [AudioTrack] = []
    @Published private(set) var artists: [AudioGroupSummary] = []
    @Published private(set) var albums: [AudioGroupSummary] = []
    @Published private(set) var tracksByArtist: [String: [AudioTrack]] = [:]
    @Published private(set) var tracksByAlbumID: [String: [AudioTrack]] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private var cache: [CachedTrack] = []
    private let cacheURL: URL

    init(cacheURL: URL? = nil) {
        self.cacheURL = cacheURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("library-cache.json")
        if let data = try? Data(contentsOf: self.cacheURL) {
            cache = (try? JSONDecoder().decode([CachedTrack].self, from: data)) ?? []
        }
        rebuild()
    }

    func reload(from sources: [ResolvedLibrarySource], force: Bool = false, only sourceIDs: Set<UUID>? = nil) async {
        isLoading = true
        errorMessage = nil
        let existing = cache
        let scannedSources = sourceIDs.map { ids in sources.filter { ids.contains($0.id) } } ?? sources
        let scanned = await Task.detached(priority: .userInitiated) {
            await Self.scan(sources: scannedSources, existing: existing, force: force)
        }.value
        cache = scanned
        let availableSourceIDs = Set(sources.map(\.id))
        tracks = scanned.filter { availableSourceIDs.contains($0.sourceID) }.map(\.track).sorted(by: Self.sortTracks)
        persistCache()
        isLoading = false
    }

    func removeSource(id: UUID) {
        let removedIDs = Set(cache.filter { $0.sourceID == id }.map(\.track.id))
        cache.removeAll { $0.sourceID == id }
        tracks.removeAll { removedIDs.contains($0.id) }
        persistCache()
    }

    func removeTrack(id: String) {
        cache.removeAll { $0.track.id == id }
        tracks.removeAll { $0.id == id }
        persistCache()
    }

    func cachedTrackIDs(sourceID: UUID) -> Set<String> {
        Set(cache.filter { $0.sourceID == sourceID }.map(\.track.id))
    }

    private func rebuild() {
        songs = tracks.sorted(by: Self.sortTracks)
        let artistMap = Dictionary(grouping: tracks, by: \.artist)
        tracksByArtist = artistMap.mapValues { $0.sorted(by: Self.sortTracks) }
        artists = artistMap.map { key, value in
            AudioGroupSummary(id: "artist::\(key)", title: key, subtitle: Self.songCount(value.count), kind: .artist, artworkData: value.first?.artworkData)
        }.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        let albumMap = Dictionary(grouping: tracks) { "\($0.artist)::\($0.album)" }
        tracksByAlbumID = albumMap.mapValues { $0.sorted(by: Self.sortTracks) }
        albums = albumMap.compactMap { key, value -> AudioGroupSummary? in
            guard let first = value.first else { return nil }
            return AudioGroupSummary(id: "album::\(key)", title: first.album,
                                     subtitle: "\(first.artist) • \(Self.songCount(value.count))",
                                     kind: .album, artworkData: first.artworkData)
        }.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private func persistCache() {
        try? FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let data = try? JSONEncoder().encode(cache) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }

    private nonisolated static func scan(sources: [ResolvedLibrarySource], existing: [CachedTrack], force: Bool) async -> [CachedTrack] {
        let supported: Set<String> = ["aac", "aiff", "alac", "caf", "flac", "m4a", "mp3", "mp4", "wav"]
        let old = Dictionary(uniqueKeysWithValues: existing.map { ("\($0.sourceID.uuidString)/\($0.relativePath)", $0) })
        let scannedSourceIDs = Set(sources.map(\.id))
        // Keep records for unavailable or unaffected roots so playlists can recover when they return.
        var result = existing.filter { !scannedSourceIDs.contains($0.sourceID) }
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .isSymbolicLinkKey, .contentModificationDateKey]
        for source in sources {
            guard let enumerator = FileManager.default.enumerator(at: source.url, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }
            while let url = enumerator.nextObject() as? URL {
                guard supported.contains(url.pathExtension.lowercased()),
                      let values = try? url.resourceValues(forKeys: keys),
                      values.isRegularFile == true, values.isSymbolicLink != true else { continue }
                let relative = relativePath(of: url, in: source.url)
                let key = "\(source.id.uuidString)/\(relative)"
                if !force, let cached = old[key], cached.modificationDate == values.contentModificationDate {
                    let rebased = AudioTrack(id: cached.track.id, fileURL: url, title: cached.track.title,
                                             artist: cached.track.artist, album: cached.track.album, genre: cached.track.genre,
                                             duration: cached.track.duration, artworkData: cached.track.artworkData,
                                             lastModified: values.contentModificationDate)
                    result.append(CachedTrack(sourceID: source.id, relativePath: relative, modificationDate: values.contentModificationDate, track: rebased))
                } else if let track = await makeTrack(url: url, id: stableID(sourceID: source.id, relativePath: relative), modificationDate: values.contentModificationDate) {
                    result.append(CachedTrack(sourceID: source.id, relativePath: relative, modificationDate: values.contentModificationDate, track: track))
                }
            }
        }
        return result
    }

    nonisolated static func stableID(sourceID: UUID, relativePath: String) -> String {
        "\(sourceID.uuidString.lowercased())::\(relativePath.precomposedStringWithCanonicalMapping.lowercased())"
    }

    private nonisolated static func relativePath(of url: URL, in root: URL) -> String {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        return String(path.dropFirst(min(path.count, rootPath.count))).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private nonisolated static func makeTrack(url: URL, id: String, modificationDate: Date?) async -> AudioTrack? {
        let asset = AVURLAsset(url: url)
        let common = (try? await asset.load(.commonMetadata)) ?? []
        func value(_ key: AVMetadataKey) async -> String? {
            guard let item = AVMetadataItem.metadataItems(from: common, filteredByIdentifier: AVMetadataIdentifier(rawValue: key.rawValue)).first else { return nil }
            return try? await item.load(.stringValue)
        }
        let title = await value(.commonKeyTitle) ?? url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ")
        let artist = await value(.commonKeyArtist) ?? AudioMetadataFallbacks.artist
        let album = await value(.commonKeyAlbumName) ?? AudioMetadataFallbacks.album
        let genre = await value(.commonKeyType) ?? AudioMetadataFallbacks.genre
        let durationTime = try? await asset.load(.duration)
        let seconds = durationTime.map(CMTimeGetSeconds) ?? 0
        let artwork = AVMetadataItem.metadataItems(from: common, filteredByIdentifier: .commonIdentifierArtwork).first
        let artworkData = try? await artwork?.load(.dataValue)
        return AudioTrack(id: id, fileURL: url, title: title, artist: artist, album: album, genre: genre,
                          duration: seconds.isFinite ? max(seconds, 0) : 0, artworkData: artworkData,
                          lastModified: modificationDate)
    }

    private nonisolated static func sortTracks(_ lhs: AudioTrack, _ rhs: AudioTrack) -> Bool {
        let title = lhs.title.localizedCaseInsensitiveCompare(rhs.title)
        return title == .orderedSame ? lhs.artist.localizedCaseInsensitiveCompare(rhs.artist) == .orderedAscending : title == .orderedAscending
    }
    private nonisolated static func songCount(_ count: Int) -> String { "\(count) song\(count == 1 ? "" : "s")" }
}
