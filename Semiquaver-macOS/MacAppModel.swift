import AppKit
import Combine
import Foundation

@MainActor
final class MacAppModel: ObservableObject {
    let player = AudioPlayerController()
    let library = AppMusicLibrary()
    let playlists = PlaylistStorage()
    let locations = LibraryLocationStore()
    let watcher = LibraryWatcher()
    private let trashService: any TrackTrashServicing

    @Published var isQueueVisible = false
    @Published var errorMessage: String?
    @Published var trackPendingTrash: AudioTrack?

    init(trashService: (any TrackTrashServicing)? = nil) {
        self.trashService = trashService ?? TrackTrashService()
        player.shuffleByDefault = UserDefaults.standard.bool(forKey: "shuffleByDefault")
        watcher.onChange = { [weak self] sourceIDs in Task { await self?.rescan(only: sourceIDs) } }
    }

    func start() async {
        await rescan()
        NotificationCenter.default.addObserver(forName: NSWorkspace.didMountNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in await self?.rescan() }
        }
    }

    func chooseFolders() {
        let panel = NSOpenPanel()
        panel.title = "Choose Music Folders"
        panel.prompt = "Add Folders"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.begin { [weak self] response in
            guard response == .OK, let self else { return }
            do {
                try self.locations.add(urls: panel.urls)
                Task { await self.rescan(force: true) }
            } catch { self.errorMessage = error.localizedDescription }
        }
    }

    func relink(_ record: LibraryLocationRecord) {
        let panel = NSOpenPanel()
        panel.title = "Relink \(record.displayName)"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url, let self else { return }
            do {
                try self.locations.relink(id: record.id, to: url)
                Task { await self.rescan(force: true) }
            } catch { self.errorMessage = error.localizedDescription }
        }
    }

    func removeLocation(_ record: LibraryLocationRecord) {
        let ids = library.cachedTrackIDs(sourceID: record.id)
        locations.remove(id: record.id)
        library.removeSource(id: record.id)
        ids.forEach(playlists.removeTrackFromAllPlaylists)
        player.removeTracks(withIDs: ids)
        Task { await rescan() }
    }

    func rescan(force: Bool = false, only sourceIDs: Set<UUID>? = nil) async {
        let sources = locations.resolveAll()
        await library.reload(from: sources, force: force, only: sourceIDs)
        let availableIDs = Set(library.tracks.map(\.id))
        let unavailableQueueIDs = Set((player.playbackQueue + player.playbackHistory).map(\.id)).subtracting(availableIDs)
        player.removeTracks(withIDs: unavailableQueueIDs)
        if let current = player.currentTrack, !availableIDs.contains(current.id) { player.stop() }
        watcher.watch(sources)
    }

    func reveal(_ track: AudioTrack) {
        NSWorkspace.shared.activateFileViewerSelecting([track.fileURL])
    }

    func requestTrash(_ track: AudioTrack) { trackPendingTrash = track }

    func confirmTrash() {
        guard let track = trackPendingTrash else { return }
        do {
            try trashService.moveToTrash(track.fileURL)
            playlists.removeTrackFromAllPlaylists(track.id)
            player.removeTracks(withIDs: [track.id])
            library.removeTrack(id: track.id)
            trackPendingTrash = nil
            Task { await rescan() }
        } catch {
            errorMessage = "The file couldn't be moved to Trash: \(error.localizedDescription)"
        }
    }
}
