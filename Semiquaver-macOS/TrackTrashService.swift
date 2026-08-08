import AppKit
import Foundation

protocol TrackTrashServicing: Sendable {
    func moveToTrash(_ url: URL) throws
}

struct TrackTrashService: TrackTrashServicing {
    func moveToTrash(_ url: URL) throws {
        var resultingURL: NSURL?
        try FileManager.default.trashItem(at: url, resultingItemURL: &resultingURL)
    }
}
