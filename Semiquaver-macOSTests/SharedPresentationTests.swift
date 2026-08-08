import XCTest
@testable import Semiquaver

final class SharedPresentationTests: XCTestCase {
    func testSearchNormalizationAndTrackFields() {
        let tracks = [
            makeTrack(id: "one", title: "Héroes", artist: "Beyoncé", album: "Lemonade", genre: "R&B"),
            makeTrack(id: "two", title: "Elsewhere", artist: "Artist", album: "Record", genre: "Jazz")
        ]

        XCTAssertEqual(LibrarySearch.normalized("  HÉROES \n"), "heroes")
        XCTAssertEqual(LibrarySearch.tracks(tracks, matching: "beyonce").map(\.id), ["one"])
        XCTAssertEqual(LibrarySearch.tracks(tracks, matching: "r&b").map(\.id), ["one"])
        XCTAssertEqual(LibrarySearch.tracks(tracks, matching: "  ").count, 2)
    }

    func testGroupSearchMatchesMetadataAndContainedTracks() {
        let contained = makeTrack(id: "one", title: "Hidden Match", artist: "Artist", album: "Album", genre: "Genre")
        let group = AudioGroupSummary(id: "artist::Artist", title: "Artist", subtitle: "1 song", kind: .artist, artworkData: nil)

        XCTAssertEqual(LibrarySearch.groups([group], tracksForGroup: { _ in [contained] }, matching: "hidden"), [group])
        XCTAssertEqual(LibrarySearch.groups([group], tracksForGroup: { _ in [] }, matching: "1 SONG"), [group])
    }

    func testPlaylistNameMatchReturnsFullContents() {
        let first = makeTrack(id: "one", title: "First")
        let second = makeTrack(id: "two", title: "Second")
        let playlist = PlaylistItem(title: "Road Trip", detail: "2 songs", trackIDs: [first.id, second.id])

        XCTAssertEqual(LibrarySearch.playlistTracks(playlist, allTracks: [first, second], matching: "road").map(\.id), ["one", "two"])
        XCTAssertEqual(LibrarySearch.playlistTracks(playlist, allTracks: [first, second], matching: "second").map(\.id), ["two"])
    }

    @MainActor
    func testPlaylistCRUDTrimmingAndPersistence() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("playlists.json")
        let storage = PlaylistStorage(fileURL: url)

        XCTAssertFalse(storage.createPlaylist(title: " \n "))
        XCTAssertTrue(storage.createPlaylist(title: "  Focus  "))
        let playlist = try XCTUnwrap(storage.playlists.first)
        XCTAssertEqual(playlist.title, "Focus")
        storage.addTrack("track", to: playlist)
        XCTAssertFalse(storage.renamePlaylist(id: playlist.id, title: "  "))
        XCTAssertTrue(storage.renamePlaylist(id: playlist.id, title: "  Deep Focus "))

        let reloaded = PlaylistStorage(fileURL: url)
        XCTAssertEqual(reloaded.playlists.first?.title, "Deep Focus")
        XCTAssertEqual(reloaded.playlists.first?.trackIDs, ["track"])
        reloaded.removeTrack("track", from: try XCTUnwrap(reloaded.playlists.first))
        reloaded.deletePlaylist(try XCTUnwrap(reloaded.playlists.first))
        XCTAssertTrue(PlaylistStorage(fileURL: url).playlists.isEmpty)
    }

    func testNavigationLabelsAndSymbols() {
        XCTAssertEqual(LibraryDestination.songs.label, "Songs")
        XCTAssertEqual(LibraryDestination.artists.label, "Artists")
        XCTAssertEqual(LibraryDestination.albums.label, "Albums")
        XCTAssertEqual(LibraryDestination.settings.systemImage, "gearshape")
        XCTAssertEqual(LibraryDestination.playlist(UUID()).label, "Playlist")
    }

    @MainActor
    func testQueueRemovalAndReordering() {
        let player = AudioPlayerController()
        let first = makeTrack(id: "one", title: "First")
        let second = makeTrack(id: "two", title: "Second")
        let third = makeTrack(id: "three", title: "Third")
        player.addToQueue(first)
        player.addToQueue(second)
        player.addToQueue(third)
        player.moveQueueItem(from: IndexSet(integer: 2), to: 0)
        XCTAssertEqual(player.playbackQueue.map(\.id), ["three", "one", "two"])
        player.removeFromQueue(at: 1)
        XCTAssertEqual(player.playbackQueue.map(\.id), ["three", "two"])
        player.addToHistory(first)
        XCTAssertEqual(player.playbackHistory.map(\.id), ["one"])
        player.repeatMode = .all
        XCTAssertEqual(player.repeatMode, .all)
    }

    private func makeTrack(
        id: String,
        title: String,
        artist: String = "Artist",
        album: String = "Album",
        genre: String = "Genre"
    ) -> AudioTrack {
        AudioTrack(
            id: id,
            fileURL: URL(fileURLWithPath: "/tmp/\(id).wav"),
            title: title,
            artist: artist,
            album: album,
            genre: genre,
            duration: 60,
            artworkData: nil,
            lastModified: nil
        )
    }
}
