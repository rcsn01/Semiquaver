import CoreServices
import Foundation

@MainActor
final class LibraryWatcher {
    private var stream: FSEventStreamRef?
    private var sources: [ResolvedLibrarySource] = []
    private var pendingIDs = Set<UUID>()
    private var debounceTask: Task<Void, Never>?
    var onChange: ((Set<UUID>) -> Void)?

    func watch(_ sources: [ResolvedLibrarySource]) {
        stop()
        self.sources = sources
        guard !sources.isEmpty else { return }
        var context = FSEventStreamContext(version: 0,
                                           info: Unmanaged.passUnretained(self).toOpaque(),
                                           retain: nil, release: nil, copyDescription: nil)
        let callback: FSEventStreamCallback = { _, info, count, paths, _, _ in
            guard let info else { return }
            let watcher = Unmanaged<LibraryWatcher>.fromOpaque(info).takeUnretainedValue()
            let changedPaths = unsafeBitCast(paths, to: NSArray.self) as? [String] ?? []
            Task { @MainActor in watcher.receive(paths: Array(changedPaths.prefix(count))) }
        }
        stream = FSEventStreamCreate(nil, callback, &context,
                                     sources.map(\.url.path) as CFArray,
                                     FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0.25,
                                     FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes |
                                                              kFSEventStreamCreateFlagFileEvents))
        guard let stream else { return }
        FSEventStreamSetDispatchQueue(stream, DispatchQueue.global(qos: .utility))
        FSEventStreamStart(stream)
    }

    func stop() {
        debounceTask?.cancel()
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
        stream = nil
        pendingIDs = []
    }

    private func receive(paths: [String]) {
        for path in paths {
            for source in sources where path == source.url.path || path.hasPrefix(source.url.path + "/") {
                pendingIDs.insert(source.id)
            }
        }
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(750))
            guard !Task.isCancelled, let self else { return }
            let ids = self.pendingIDs
            self.pendingIDs = []
            self.onChange?(ids)
        }
    }

}
