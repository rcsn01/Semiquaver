import Combine
import Foundation

protocol TrackFileRemoving {
    func removeItem(at url: URL) throws
}

struct LocalTrackFileRemover: TrackFileRemoving {
    func removeItem(at url: URL) throws { try FileManager.default.removeItem(at: url) }
}

@MainActor
final class IOSAppModel: ObservableObject {
    let player: AudioPlayerController
    let library: AppMusicLibrary
    let playlists: PlaylistStorage
    let folderStore: MusicFolderStore
    private let fileRemover: any TrackFileRemoving

    init() {
        self.player = AudioPlayerController()
        self.library = AppMusicLibrary()
        self.playlists = PlaylistStorage()
        self.folderStore = MusicFolderStore()
        self.fileRemover = LocalTrackFileRemover()
        player.shuffleByDefault = UserDefaults.standard.bool(forKey: "shuffleByDefault")
    }

    init(
        player: AudioPlayerController,
        library: AppMusicLibrary,
        playlists: PlaylistStorage,
        folderStore: MusicFolderStore? = nil,
        fileRemover: any TrackFileRemoving = LocalTrackFileRemover()
    ) {
        self.player = player
        self.library = library
        self.playlists = playlists
        self.folderStore = folderStore ?? MusicFolderStore()
        self.fileRemover = fileRemover
        player.shuffleByDefault = UserDefaults.standard.bool(forKey: "shuffleByDefault")
    }

    func start() async {
        await rescan()
    }

    /// Re-resolves the configured folder and re-scans the library. Does not
    /// purge playlists: a temporarily missing folder recovers when it returns.
    func rescan(force: Bool = false) async {
        let resolved = folderStore.resolve()
        let record = folderStore.record
        library.folderConfigured = record != nil
        library.folderName = record?.displayName
        if let record, resolved == nil {
            library.errorMessage = "“\(record.displayName)” isn't available right now. Reconnect it, or choose the folder again in Settings."
        } else {
            library.errorMessage = nil
        }
        await library.reload(from: resolved, force: force)
        let availableIDs = Set(library.tracks.map(\.id))
        let unavailableIDs = Set((player.playbackQueue + player.playbackHistory).map(\.id)).subtracting(availableIDs)
        player.removeTracks(withIDs: unavailableIDs)
        if let current = player.currentTrack, !availableIDs.contains(current.id) { player.stop() }
    }

    /// Replaces the configured folder. Tracks that no longer exist under the
    /// new folder are purged from playlists and the playback queue.
    func chooseFolder(_ url: URL) async {
        let oldIDs = Set(library.tracks.map(\.id))
        do {
            try folderStore.set(url)
        } catch {
            library.errorMessage = error.localizedDescription
            return
        }
        await rescan(force: true)
        purgeTracks(oldIDs: oldIDs)
    }

    /// Forgets the configured folder entirely; the library empties and the
    /// UI returns to the choose-folder state.
    func removeFolder() async {
        let removedIDs = Set(library.tracks.map(\.id))
        removedIDs.forEach(playlists.removeTrackFromAllPlaylists)
        player.removeTracks(withIDs: removedIDs)
        folderStore.clear()
        await rescan()
    }

    private func purgeTracks(oldIDs: Set<String>) {
        let vanished = oldIDs.subtracting(library.tracks.map(\.id))
        guard !vanished.isEmpty else { return }
        vanished.forEach(playlists.removeTrackFromAllPlaylists)
        player.removeTracks(withIDs: vanished)
    }

    func delete(_ track: AudioTrack) throws {
        try fileRemover.removeItem(at: track.fileURL)
        playlists.removeTrackFromAllPlaylists(track.id)
        player.removeTracks(withIDs: [track.id])
        Task { await library.reload(force: true) }
    }
}
