import AppKit
import Foundation

enum LibraryLocationStatus: String, Codable, Sendable {
    case available
    case unavailable
    case permissionRequired
}

struct LibraryLocationRecord: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var displayName: String
    var bookmark: Data
    var lastKnownPath: String
    var status: LibraryLocationStatus
}

struct ResolvedLibrarySource: Identifiable, Sendable {
    let id: UUID
    let url: URL
}

enum LibraryLocationError: LocalizedError {
    case overlapping(String)
    case bookmarkCreation(String)

    var errorDescription: String? {
        switch self {
        case .overlapping(let path): "That folder overlaps an existing library location: \(path)"
        case .bookmarkCreation(let path): "Semiquaver couldn't retain access to \(path)."
        }
    }
}

@MainActor
final class LibraryLocationStore: ObservableObject {
    @Published private(set) var records: [LibraryLocationRecord] = []
    private let fileManager: FileManager
    private let storageURL: URL
    private var scopedURLs: [UUID: URL] = [:]

    init(fileManager: FileManager = .default, storageURL: URL? = nil) {
        self.fileManager = fileManager
        self.storageURL = storageURL ?? Self.applicationSupportURL(fileManager: fileManager)
            .appendingPathComponent("library-locations.json")
        load()
    }

    deinit {
        for url in scopedURLs.values { url.stopAccessingSecurityScopedResource() }
    }

    func add(urls: [URL]) throws {
        var additions: [LibraryLocationRecord] = []
        for rawURL in urls {
            let url = rawURL.standardizedFileURL.resolvingSymlinksInPath()
            try rejectOverlap(with: url, considering: records + additions)
            guard let bookmark = try? url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: [.nameKey], relativeTo: nil
            ) else { throw LibraryLocationError.bookmarkCreation(url.path) }
            additions.append(LibraryLocationRecord(
                id: UUID(), displayName: url.lastPathComponent, bookmark: bookmark,
                lastKnownPath: url.path, status: .available
            ))
        }
        records.append(contentsOf: additions)
        save()
    }

    func remove(id: UUID) {
        stopAccessing(id: id)
        records.removeAll { $0.id == id }
        save()
    }

    func relink(id: UUID, to rawURL: URL) throws {
        let url = rawURL.standardizedFileURL.resolvingSymlinksInPath()
        try rejectOverlap(with: url, considering: records.filter { $0.id != id })
        guard let bookmark = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil),
              let index = records.firstIndex(where: { $0.id == id }) else {
            throw LibraryLocationError.bookmarkCreation(url.path)
        }
        stopAccessing(id: id)
        records[index].bookmark = bookmark
        records[index].displayName = url.lastPathComponent
        records[index].lastKnownPath = url.path
        records[index].status = .available
        save()
    }

    func resolveAll() -> [ResolvedLibrarySource] {
        stopAccessingAll()
        var sources: [ResolvedLibrarySource] = []
        for index in records.indices {
            var stale = false
            do {
                let url = try URL(resolvingBookmarkData: records[index].bookmark,
                                  options: [.withSecurityScope], relativeTo: nil,
                                  bookmarkDataIsStale: &stale)
                guard fileManager.fileExists(atPath: url.path) else {
                    records[index].status = .unavailable
                    continue
                }
                guard url.startAccessingSecurityScopedResource() else {
                    records[index].status = .permissionRequired
                    continue
                }
                scopedURLs[records[index].id] = url
                records[index].status = .available
                records[index].lastKnownPath = url.path
                if stale, let refreshed = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
                    records[index].bookmark = refreshed
                }
                sources.append(ResolvedLibrarySource(id: records[index].id, url: url))
            } catch {
                records[index].status = .permissionRequired
            }
        }
        save()
        return sources
    }

    func stopAccessingAll() {
        for id in Array(scopedURLs.keys) { stopAccessing(id: id) }
    }

    func reveal(id: UUID) {
        guard let record = records.first(where: { $0.id == id }) else { return }
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: record.lastKnownPath)
    }

    private func stopAccessing(id: UUID) {
        scopedURLs.removeValue(forKey: id)?.stopAccessingSecurityScopedResource()
    }

    private func rejectOverlap(with url: URL, considering candidates: [LibraryLocationRecord]) throws {
        let newPath = url.pathComponents
        for record in candidates {
            let oldPath = URL(fileURLWithPath: record.lastKnownPath).standardizedFileURL.pathComponents
            if newPath.starts(with: oldPath) || oldPath.starts(with: newPath) {
                throw LibraryLocationError.overlapping(record.lastKnownPath)
            }
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([LibraryLocationRecord].self, from: data) else { return }
        records = decoded
    }

    private func save() {
        try? fileManager.createDirectory(at: storageURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    private static func applicationSupportURL(fileManager: FileManager) -> URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }
}
