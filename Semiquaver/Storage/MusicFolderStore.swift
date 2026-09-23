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
    private let fileExistsAtPath: (String) -> Bool
    private let startAccessing: (URL) -> Bool
    private let stopAccessing: (URL) -> Void
    private var scopedURL: URL?

    init(
        fileManager: FileManager = .default,
        storageURL: URL? = nil,
        fileExistsAtPath: ((String) -> Bool)? = nil,
        startAccessing: @escaping (URL) -> Bool = { $0.startAccessingSecurityScopedResource() },
        stopAccessing: @escaping (URL) -> Void = { $0.stopAccessingSecurityScopedResource() }
    ) {
        self.fileManager = fileManager
        self.storageURL = storageURL ?? Self.applicationSupportURL(fileManager: fileManager)
            .appendingPathComponent("music-folder.json")
        self.fileExistsAtPath = fileExistsAtPath ?? { fileManager.fileExists(atPath: $0) }
        self.startAccessing = startAccessing
        self.stopAccessing = stopAccessing
        load()
    }

    deinit {
        if let scopedURL { stopAccessing(scopedURL) }
    }

    func set(_ url: URL) throws {
        // Keep the exact URL returned by the document picker. On iOS, making
        // a standardized or symlink-resolved copy drops its security scope,
        // so a bookmark made from that copy cannot restore access on relaunch.
        // The return value is legitimately false for non-security-scoped URLs
        // (e.g. plain test fixtures); only balance a successful start.
        let started = startAccessing(url)
        defer {
            if started { stopAccessing(url) }
        }

        let bookmark: Data
        do {
            bookmark = try url.bookmarkData(includingResourceValuesForKeys: [.nameKey], relativeTo: nil)
        } catch {
            throw MusicFolderError.bookmarkCreation(url.path)
        }

        if let scopedURL { stopAccessing(scopedURL) }
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
            url = try URL(
                resolvingBookmarkData: record.bookmark,
                options: [.withoutImplicitStartAccessing],
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            )
        } catch {
            record.status = .permissionRequired
            self.record = record
            save()
            return nil
        }

        // A bookmark restored after relaunch does not grant filesystem access
        // until its security scope is opened. Checking first makes an existing
        // external folder look missing and empties the library on startup.
        let started = startAccessing(url)
        guard fileExistsAtPath(url.path) else {
            if started { stopAccessing(url) }
            record.status = .unavailable
            record.lastKnownPath = url.path
            self.record = record
            save()
            return nil
        }

        if let scopedURL { stopAccessing(scopedURL) }
        scopedURL = started ? url : nil

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
        if let scopedURL { stopAccessing(scopedURL) }
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
