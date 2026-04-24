import Foundation
import Combine

final class PlaylistStorage: ObservableObject, @unchecked Sendable {
    @Published var playlists: [PlaylistItem] = []

    private static let fileName = "playlists.json"

    init() {
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
            // Seed with mock data on first launch
            playlists = MockLibrary.playlists.map {
                PlaylistItem(title: $0.title, detail: $0.detail, trackIDs: [])
            }
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
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(Self.fileName)
    }

    private func updateDetail(for index: Int) {
        let count = playlists[index].trackIDs.count
        playlists[index].detail = "\(count) song\(count == 1 ? "" : "s")"
    }
}
