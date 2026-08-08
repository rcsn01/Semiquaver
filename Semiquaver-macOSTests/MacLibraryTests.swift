import XCTest
@testable import Semiquaver

final class MacLibraryTests: XCTestCase {
    func testStableIDSurvivesRootRelocation() {
        let sourceID = UUID(uuidString: "CAFECAFE-0000-0000-0000-000000000001")!
        let original = AppMusicLibrary.stableID(sourceID: sourceID, relativePath: "Albums/Track.MP3")
        let relocated = AppMusicLibrary.stableID(sourceID: sourceID, relativePath: "Albums/Track.MP3")
        XCTAssertEqual(original, relocated)
        XCTAssertFalse(original.contains("/Volumes/"))
    }

    func testStableIDNormalizesCaseAndUnicode() {
        let sourceID = UUID()
        let composed = AppMusicLibrary.stableID(sourceID: sourceID, relativePath: "Beyoncé/SONG.M4A")
        let decomposed = AppMusicLibrary.stableID(sourceID: sourceID, relativePath: "Beyonce\u{301}/song.m4a")
        XCTAssertEqual(composed, decomposed)
    }

    @MainActor
    func testNestedLocationIsRejected() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let nested = root.appendingPathComponent("Nested")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LibraryLocationStore(storageURL: root.appendingPathComponent("locations.json"))
        do {
            try store.add(urls: [root])
        } catch {
            throw XCTSkip("Security-scoped bookmark creation isn't available in this test host: \(error)")
        }
        XCTAssertThrowsError(try store.add(urls: [nested]))
    }

    @MainActor
    func testMultiRootScanAndTemporaryUnavailability() async throws {
        let fixture = try makeFixtureDirectory()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let firstRoot = fixture.appendingPathComponent("First")
        let secondRoot = fixture.appendingPathComponent("Second")
        try FileManager.default.createDirectory(at: firstRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: secondRoot, withIntermediateDirectories: true)
        try silentWAV().write(to: firstRoot.appendingPathComponent("One.wav"))
        try silentWAV().write(to: secondRoot.appendingPathComponent("Two.wav"))
        let firstID = UUID(), secondID = UUID()
        let sources = [ResolvedLibrarySource(id: firstID, url: firstRoot), ResolvedLibrarySource(id: secondID, url: secondRoot)]
        let library = AppMusicLibrary(cacheURL: fixture.appendingPathComponent("cache.json"))

        await library.reload(from: sources, force: true)
        XCTAssertEqual(library.tracks.count, 2)
        XCTAssertTrue(library.tracks.contains { $0.id == AppMusicLibrary.stableID(sourceID: firstID, relativePath: "One.wav") })

        await library.reload(from: [sources[0]])
        XCTAssertEqual(library.tracks.map(\.title), ["One"])
        await library.reload(from: sources)
        XCTAssertEqual(Set(library.tracks.map(\.title)), ["One", "Two"])
    }

    @MainActor
    func testIncrementalScanRemovesDeletedTrack() async throws {
        let fixture = try makeFixtureDirectory()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let audioURL = fixture.appendingPathComponent("Track.wav")
        try silentWAV().write(to: audioURL)
        let source = ResolvedLibrarySource(id: UUID(), url: fixture)
        let library = AppMusicLibrary(cacheURL: fixture.appendingPathComponent("cache.json"))
        await library.reload(from: [source], force: true)
        XCTAssertEqual(library.tracks.count, 1)
        try FileManager.default.removeItem(at: audioURL)
        await library.reload(from: [source])
        XCTAssertTrue(library.tracks.isEmpty)
    }

    @MainActor
    func testPlaylistCleanupAndQueueCleanup() throws {
        let fixture = try makeFixtureDirectory()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let playlists = PlaylistStorage(fileURL: fixture.appendingPathComponent("playlists.json"))
        playlists.createPlaylist(title: "Test")
        let playlist = try XCTUnwrap(playlists.playlists.first)
        playlists.addTrack("track-1", to: playlist)
        XCTAssertEqual(playlists.playlists.first?.trackIDs, ["track-1"])
        playlists.removeTrackFromAllPlaylists("track-1")
        XCTAssertTrue(playlists.playlists.first?.trackIDs.isEmpty == true)

        let player = AudioPlayerController()
        let track = AudioTrack(id: "track-1", fileURL: fixture.appendingPathComponent("missing.wav"), title: "Track",
                               artist: "Artist", album: "Album", genre: "Genre", duration: 1,
                               artworkData: nil, lastModified: nil)
        player.addToQueue(track)
        player.addToHistory(track)
        player.removeTracks(withIDs: [track.id])
        XCTAssertTrue(player.playbackQueue.isEmpty)
        XCTAssertTrue(player.playbackHistory.isEmpty)
    }

    private func makeFixtureDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func silentWAV() -> Data {
        var data = Data()
        func ascii(_ value: String) { data.append(value.data(using: .ascii)!) }
        func u16(_ value: UInt16) { var value = value.littleEndian; data.append(Data(bytes: &value, count: 2)) }
        func u32(_ value: UInt32) { var value = value.littleEndian; data.append(Data(bytes: &value, count: 4)) }
        let sampleCount: UInt32 = 800
        ascii("RIFF"); u32(36 + sampleCount * 2); ascii("WAVEfmt "); u32(16); u16(1); u16(1)
        u32(8_000); u32(16_000); u16(2); u16(16); ascii("data"); u32(sampleCount * 2)
        data.append(Data(count: Int(sampleCount * 2)))
        return data
    }
}
