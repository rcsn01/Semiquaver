import Foundation
import Combine

final class PlaylistStorage: ObservableObject, @unchecked Sendable {
    @Published var playlists: [PlaylistItem] = []

    private static let fileName = "playlists.json"
    private let overriddenFileURL: URL?

    init(fileURL: URL? = nil) {
        self.overriddenFileURL = fileURL
        load()
    }

    // MARK: - CRUD

    func createPlaylist(title: String) {
        let playlist = PlaylistItem(title: title, detail: "0 songs", trackIDs: [])
        playlists.append(playlist)
        save()
    }

    func deletePlaylist(_ playlist: PlaylistItem) {
        playlists.removeAll { $0.id == playlist.id }
        save()
    }

    func addTrack(_ trackID: String, to playlist: PlaylistItem) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        if !playlists[index].trackIDs.contains(trackID) {
            playlists[index].trackIDs.append(trackID)
            updateDetail(for: index)
            save()
        }
    }

    func removeTrack(_ trackID: String, from playlist: PlaylistItem) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[index].trackIDs.removeAll { $0 == trackID }
        updateDetail(for: index)
        save()
    }

    func isTrackInPlaylist(_ trackID: String, playlist: PlaylistItem) -> Bool {
        playlist.trackIDs.contains(trackID)
    }

    func playlistsContaining(trackID: String) -> [PlaylistItem] {
        playlists.filter { $0.trackIDs.contains(trackID) }
    }

    // MARK: - Persistence

    private func save() {
        guard let url = fileURL else { return }
        do {
            let data = try JSONEncoder().encode(playlists)
            try data.write(to: url)
        } catch {
            print("Failed to save playlists: \(error.localizedDescription)")
        }
    }

    private func load() {
        guard let url = fileURL, FileManager.default.fileExists(atPath: url.path) else {
            #if os(macOS)
            playlists = []
            #else
            // Keep the existing iOS first-launch experience unchanged.
            playlists = MockLibrary.playlists.map {
                PlaylistItem(title: $0.title, detail: $0.detail, trackIDs: [])
            }
            #endif
            save()
            return
        }
        do {
            let data = try Data(contentsOf: url)
            playlists = try JSONDecoder().decode([PlaylistItem].self, from: data)
        } catch {
            print("Failed to load playlists: \(error.localizedDescription)")
            playlists = []
        }
    }

    private var fileURL: URL? {
        if let overriddenFileURL { return overriddenFileURL }
        return FileManager.default.urls(for: Self.storageDirectory, in: .userDomainMask).first?
            .appendingPathComponent(Self.fileName)
    }

    private static var storageDirectory: FileManager.SearchPathDirectory {
        #if os(macOS)
        .applicationSupportDirectory
        #else
        .documentDirectory
        #endif
    }

    func removeTrackFromAllPlaylists(_ trackID: String) {
        for index in playlists.indices {
            playlists[index].trackIDs.removeAll { $0 == trackID }
            updateDetail(for: index)
        }
        save()
    }

    private func updateDetail(for index: Int) {
        let count = playlists[index].trackIDs.count
        playlists[index].detail = "\(count) song\(count == 1 ? "" : "s")"
    }
}
