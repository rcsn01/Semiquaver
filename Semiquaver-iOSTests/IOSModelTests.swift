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

    @MainActor
    func testMusicFolderStoreStartsSecurityScopeBeforeCheckingRelaunchedFolder() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let folder = fixture.appendingPathComponent("Music")
        let storageURL = fixture.appendingPathComponent("music-folder.json")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let bookmark = try folder.bookmarkData(includingResourceValuesForKeys: nil, relativeTo: nil)
        let record = MusicFolderRecord(
            bookmark: bookmark,
            displayName: "Music",
            lastKnownPath: folder.path,
            status: .available
        )
        try JSONEncoder().encode(record).write(to: storageURL)

        var scopeIsOpen = false
        let store = MusicFolderStore(
            storageURL: storageURL,
            fileExistsAtPath: { _ in scopeIsOpen },
            startAccessing: { _ in scopeIsOpen = true; return true },
            stopAccessing: { _ in scopeIsOpen = false }
        )

        XCTAssertEqual(store.resolve()?.standardizedFileURL, folder.standardizedFileURL)
        XCTAssertEqual(store.record?.status, .available)
    }

    @MainActor
    func testMusicFolderStoreBookmarksTheOriginalSecurityScopedURL() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let folder = fixture.appendingPathComponent("Music")
        let pickedURL = fixture.appendingPathComponent("Picked Music")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: pickedURL, withDestinationURL: folder)

        var accessedURL: URL?
        let store = MusicFolderStore(
            storageURL: fixture.appendingPathComponent("music-folder.json"),
            startAccessing: { url in accessedURL = url; return false }
        )
        try store.set(pickedURL)

        XCTAssertEqual(accessedURL, pickedURL)
    }

    @MainActor
    func testMusicFolderStorePersistsAndClears() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let storageURL = fixture.appendingPathComponent("music-folder.json")
        let store = MusicFolderStore(storageURL: storageURL)
        XCTAssertNil(store.record)

        let folder = fixture.appendingPathComponent("Music")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        do {
            try store.set(folder)
        } catch {
            throw XCTSkip("Bookmark creation isn't available in this test host: \(error)")
        }
        XCTAssertEqual(store.record?.displayName, "Music")
        XCTAssertEqual(store.record?.status, .available)

        let reloaded = MusicFolderStore(storageURL: storageURL)
        XCTAssertEqual(reloaded.record, store.record)

        let resolved = try XCTUnwrap(store.resolve())
        XCTAssertTrue(FileManager.default.fileExists(atPath: resolved.path))
        XCTAssertEqual(store.record?.status, .available)

        store.clear()
        XCTAssertNil(store.record)
        XCTAssertFalse(FileManager.default.fileExists(atPath: storageURL.path))
    }

    @MainActor
    func testReloadFromScansChosenFolderAndClearsOnNil() async throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let folder = fixture.appendingPathComponent("Music")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let audioURL = folder.appendingPathComponent("One.wav")
        try silentWAV().write(to: audioURL)
        let library = AppMusicLibrary(cacheURL: fixture.appendingPathComponent("cache.json"))

        await library.reload(from: nil)
        XCTAssertTrue(library.tracks.isEmpty)
        XCTAssertNil(library.errorMessage)

        await library.reload(from: folder, force: true)
        XCTAssertEqual(library.tracks.count, 1)

        try FileManager.default.removeItem(at: audioURL)
        await library.reload(force: true)
        XCTAssertTrue(library.tracks.isEmpty)
    }

    @MainActor
    func testScannedLibrarySurvivesAppRelaunch() async throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let folder = fixture.appendingPathComponent("Music")
        let storageURL = fixture.appendingPathComponent("music-folder.json")
        let cacheURL = fixture.appendingPathComponent("library-cache.json")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try silentWAV().write(to: folder.appendingPathComponent("One.wav"))

        let firstStore = MusicFolderStore(storageURL: storageURL)
        do {
            try firstStore.set(folder)
        } catch {
            throw XCTSkip("Bookmark creation isn't available in this test host: \(error)")
        }
        let firstLibrary = AppMusicLibrary(cacheURL: cacheURL)
        let firstModel = IOSAppModel(
            player: AudioPlayerController(),
            library: firstLibrary,
            playlists: PlaylistStorage(fileURL: fixture.appendingPathComponent("playlists.json")),
            folderStore: firstStore
        )
        await firstModel.start()
        XCTAssertEqual(firstLibrary.tracks.count, 1)

        let relaunchedLibrary = AppMusicLibrary(cacheURL: cacheURL)
        let relaunchedModel = IOSAppModel(
            player: AudioPlayerController(),
            library: relaunchedLibrary,
            playlists: PlaylistStorage(fileURL: fixture.appendingPathComponent("playlists.json")),
            folderStore: MusicFolderStore(storageURL: storageURL)
        )
        await relaunchedModel.start()

        XCTAssertTrue(relaunchedLibrary.folderConfigured)
        XCTAssertEqual(relaunchedLibrary.folderName, "Music")
        XCTAssertNil(relaunchedLibrary.errorMessage)
        XCTAssertEqual(relaunchedLibrary.tracks.map(\.title), ["One"])
    }

    @MainActor
    func testChooseFolderPurgesVanishedTracksFromPlaylistsAndQueue() async throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let oldFolder = fixture.appendingPathComponent("Old")
        let newFolder = fixture.appendingPathComponent("New")
        try FileManager.default.createDirectory(at: oldFolder, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: newFolder, withIntermediateDirectories: true)
        try silentWAV().write(to: oldFolder.appendingPathComponent("Gone.wav"))
        try silentWAV().write(to: newFolder.appendingPathComponent("Kept.wav"))

        let store = MusicFolderStore(storageURL: fixture.appendingPathComponent("music-folder.json"))
        let library = AppMusicLibrary(cacheURL: fixture.appendingPathComponent("cache.json"))
        let playlists = PlaylistStorage(fileURL: fixture.appendingPathComponent("playlists.json"))
        _ = playlists.createPlaylist(title: "Mix")
        let player = AudioPlayerController()
        let model = IOSAppModel(player: player, library: library, playlists: playlists, folderStore: store)

        do { try store.set(oldFolder) } catch {
            throw XCTSkip("Bookmark creation isn't available in this test host: \(error)")
        }
        await model.rescan()
        let vanishedID = try XCTUnwrap(library.tracks.first?.id)
        playlists.addTrack(vanishedID, to: playlists.playlists[0])
        player.addToQueue(makeTrack(id: vanishedID, url: library.tracks[0].fileURL))

        await model.chooseFolder(newFolder)

        XCTAssertTrue(playlists.playlists[0].trackIDs.isEmpty)
        XCTAssertTrue(player.playbackQueue.isEmpty)
        XCTAssertEqual(library.tracks.count, 1)
        XCTAssertFalse(library.tracks.contains { $0.id == vanishedID })
        XCTAssertTrue(library.folderConfigured)
        XCTAssertEqual(library.folderName, "New")
    }

    @MainActor
    func testChooseFolderSameFolderKeepsPlaylistEntries() async throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let folder = fixture.appendingPathComponent("Music")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try silentWAV().write(to: folder.appendingPathComponent("Kept.wav"))

        let store = MusicFolderStore(storageURL: fixture.appendingPathComponent("music-folder.json"))
        let library = AppMusicLibrary(cacheURL: fixture.appendingPathComponent("cache.json"))
        let playlists = PlaylistStorage(fileURL: fixture.appendingPathComponent("playlists.json"))
        _ = playlists.createPlaylist(title: "Mix")
        let model = IOSAppModel(player: AudioPlayerController(), library: library, playlists: playlists, folderStore: store)

        do { try store.set(folder) } catch {
            throw XCTSkip("Bookmark creation isn't available in this test host: \(error)")
        }
        await model.rescan()
        let trackID = try XCTUnwrap(library.tracks.first?.id)
        playlists.addTrack(trackID, to: playlists.playlists[0])

        await model.chooseFolder(folder)

        XCTAssertEqual(playlists.playlists[0].trackIDs, [trackID])
        XCTAssertEqual(library.tracks.map(\.id), [trackID])
    }

    @MainActor
    func testRemoveFolderClearsLibraryAndPlaylists() async throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let folder = fixture.appendingPathComponent("Music")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try silentWAV().write(to: folder.appendingPathComponent("One.wav"))

        let store = MusicFolderStore(storageURL: fixture.appendingPathComponent("music-folder.json"))
        let library = AppMusicLibrary(cacheURL: fixture.appendingPathComponent("cache.json"))
        let playlists = PlaylistStorage(fileURL: fixture.appendingPathComponent("playlists.json"))
        _ = playlists.createPlaylist(title: "Mix")
        let player = AudioPlayerController()
        let model = IOSAppModel(player: player, library: library, playlists: playlists, folderStore: store)

        do { try store.set(folder) } catch {
            throw XCTSkip("Bookmark creation isn't available in this test host: \(error)")
        }
        await model.rescan()
        let trackID = try XCTUnwrap(library.tracks.first?.id)
        playlists.addTrack(trackID, to: playlists.playlists[0])
        player.addToQueue(makeTrack(id: trackID, url: library.tracks[0].fileURL))

        await model.removeFolder()

        XCTAssertNil(store.record)
        XCTAssertFalse(library.folderConfigured)
        XCTAssertNil(library.folderName)
        XCTAssertNil(library.errorMessage)
        XCTAssertTrue(library.tracks.isEmpty)
        XCTAssertTrue(playlists.playlists[0].trackIDs.isEmpty)
        XCTAssertTrue(player.playbackQueue.isEmpty)
    }

    private func makeFixture() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeTrack(id: String, url: URL) -> AudioTrack {
        AudioTrack(id: id, fileURL: url, title: "Track", artist: "Artist", album: "Album", genre: "Genre", duration: 1, artworkData: nil, lastModified: nil)
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

private struct FailingRemover: TrackFileRemoving {
    struct Failure: Error { }
    func removeItem(at url: URL) throws { throw Failure() }
}
