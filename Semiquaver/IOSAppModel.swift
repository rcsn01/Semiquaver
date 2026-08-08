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
    private let fileRemover: any TrackFileRemoving

    init() {
        self.player = AudioPlayerController()
        self.library = AppMusicLibrary()
        self.playlists = PlaylistStorage()
        self.fileRemover = LocalTrackFileRemover()
        player.shuffleByDefault = UserDefaults.standard.bool(forKey: "shuffleByDefault")
    }

    init(
        player: AudioPlayerController,
        library: AppMusicLibrary,
        playlists: PlaylistStorage,
        fileRemover: any TrackFileRemoving = LocalTrackFileRemover()
    ) {
        self.player = player
        self.library = library
        self.playlists = playlists
        self.fileRemover = fileRemover
        player.shuffleByDefault = UserDefaults.standard.bool(forKey: "shuffleByDefault")
    }

    func start() async { await library.reload() }

    func delete(_ track: AudioTrack) throws {
        try fileRemover.removeItem(at: track.fileURL)
        playlists.removeTrackFromAllPlaylists(track.id)
        player.removeTracks(withIDs: [track.id])
        Task { await library.reload(force: true) }
    }
}
