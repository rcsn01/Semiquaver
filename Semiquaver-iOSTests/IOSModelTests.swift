import XCTest
@testable import Semiquaver

final class IOSModelTests: XCTestCase {
    @MainActor
    func testSinglePlaylistStoreAndResolvedTracks() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let playlists = PlaylistStorage(fileURL: fixture.appendingPathComponent("playlists.json"))
        XCTAssertTrue(playlists.createPlaylist(title: "Shared"))
        let playlist = try XCTUnwrap(playlists.playlists.first)
        playlists.addTrack("track", to: playlist)
        let model = IOSAppModel(player: AudioPlayerController(), library: AppMusicLibrary(), playlists: playlists)

        XCTAssertTrue(model.playlists === playlists)
        let track = makeTrack(id: "track", url: fixture.appendingPathComponent("track.wav"))
        XCTAssertEqual(LibrarySearch.playlistTracks(model.playlists.playlists[0], allTracks: [track], matching: "").map(\.id), ["track"])
    }

    @MainActor
    func testDeletionFailureLeavesPlaylistAndQueueUnchanged() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let playlists = PlaylistStorage(fileURL: fixture.appendingPathComponent("playlists.json"))
        _ = playlists.createPlaylist(title: "Keep")
        let playlist = try XCTUnwrap(playlists.playlists.first)
        let track = makeTrack(id: "track", url: fixture.appendingPathComponent("track.wav"))
        playlists.addTrack(track.id, to: playlist)
        let player = AudioPlayerController()
        player.addToQueue(track)
        let model = IOSAppModel(player: player, library: AppMusicLibrary(), playlists: playlists, fileRemover: FailingRemover())

        XCTAssertThrowsError(try model.delete(track))
        XCTAssertEqual(playlists.playlists.first?.trackIDs, [track.id])
        XCTAssertEqual(player.playbackQueue.map(\.id), [track.id])
    }

    private func makeFixture() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeTrack(id: String, url: URL) -> AudioTrack {
        AudioTrack(id: id, fileURL: url, title: "Track", artist: "Artist", album: "Album", genre: "Genre", duration: 1, artworkData: nil, lastModified: nil)
    }
}

private struct FailingRemover: TrackFileRemoving {
    struct Failure: Error { }
    func removeItem(at url: URL) throws { throw Failure() }
}
