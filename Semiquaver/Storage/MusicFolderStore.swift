import Combine
import Foundation

enum MusicFolderStatus: String, Codable, Sendable {
    case available
    case unavailable
    case permissionRequired
}

struct MusicFolderRecord: Codable, Equatable, Sendable {
    var bookmark: Data
    var displayName: String
    var lastKnownPath: String
    var status: MusicFolderStatus
}

enum MusicFolderError: LocalizedError {
    case bookmarkCreation(String)

    var errorDescription: String? {
        switch self {
        case .bookmarkCreation(let path): "Semiquaver couldn't retain access to \(path)."
        }
    }
}

/// Holds the single user-chosen music folder as a security-scoped bookmark.
/// The resolved URL's security scope is kept open for the app session so that
/// lazy playback (`AVAudioPlayer(contentsOf:)`) can read files from the folder.
@MainActor
final class MusicFolderStore: ObservableObject {
    @Published private(set) var record: MusicFolderRecord?
    private let fileManager: FileManager
    private let storageURL: URL
    private var scopedURL: URL?

    init(fileManager: FileManager = .default, storageURL: URL? = nil) {
        self.fileManager = fileManager
        self.storageURL = storageURL ?? Self.applicationSupportURL(fileManager: fileManager)
            .appendingPathComponent("music-folder.json")
        load()
    }

    deinit {
        scopedURL?.stopAccessingSecurityScopedResource()
    }

    func set(_ rawURL: URL) throws {
        let url = rawURL.standardizedFileURL.resolvingSymlinksInPath()
        // The return value is legitimately false for non-security-scoped URLs
        // (e.g. plain test fixtures); only balance a successful start.
        let started = url.startAccessingSecurityScopedResource()
        defer {
            if started { url.stopAccessingSecurityScopedResource() }
        }

        let bookmark: Data
        do {
            bookmark = try url.bookmarkData(includingResourceValuesForKeys: [.nameKey], relativeTo: nil)
        } catch {
            throw MusicFolderError.bookmarkCreation(url.path)
        }

        scopedURL?.stopAccessingSecurityScopedResource()
        scopedURL = nil
        record = MusicFolderRecord(
            bookmark: bookmark,
            displayName: url.lastPathComponent,
            lastKnownPath: url.path,
            status: .available
        )
        save()
    }

    /// Resolves the stored bookmark into a live URL with an open security
    /// scope. Returns nil when no folder is configured, the folder is gone,
    /// or access can no longer be established (record status reflects why).
    func resolve() -> URL? {
        guard var record else { return nil }

        var stale = false
        let url: URL
        do {
            url = try URL(resolvingBookmarkData: record.bookmark, options: [], relativeTo: nil, bookmarkDataIsStale: &stale)
        } catch {
            record.status = .permissionRequired
            self.record = record
            save()
            return nil
        }

        guard fileManager.fileExists(atPath: url.path) else {
            record.status = .unavailable
            record.lastKnownPath = url.path
            self.record = record
            save()
            return nil
        }

        _ = url.startAccessingSecurityScopedResource()
        scopedURL?.stopAccessingSecurityScopedResource()
        scopedURL = url

        record.status = .available
        record.lastKnownPath = url.path
        if stale, let refreshed = try? url.bookmarkData(includingResourceValuesForKeys: nil, relativeTo: nil) {
            record.bookmark = refreshed
        }
        self.record = record
        save()
        return url
    }

    func clear() {
        scopedURL?.stopAccessingSecurityScopedResource()
        scopedURL = nil
        record = nil
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode(MusicFolderRecord.self, from: data) else { return }
        record = decoded
    }

    private func save() {
        try? fileManager.createDirectory(at: storageURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let record else {
            try? fileManager.removeItem(at: storageURL)
            return
        }
        guard let data = try? JSONEncoder().encode(record) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    private static func applicationSupportURL(fileManager: FileManager) -> URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }
}