import Foundation

enum AppMusicDirectory {
    static let folderName = "Music"
    static let placeholderFileName = "Place media here to add them"
    static let rootMarkerMessage = "Put music files in the Music folder."
    static let libraryMarkerMessage = "Drop your music files in this folder."

    @discardableResult
    static func ensureExists() -> URL? {
        let fileManager = FileManager.default

        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        ensureMarkerFile(in: documentsURL, message: rootMarkerMessage)

        let musicURL = documentsURL.appendingPathComponent(folderName, isDirectory: true)

        if !fileManager.fileExists(atPath: musicURL.path) {
            do {
                try fileManager.createDirectory(at: musicURL, withIntermediateDirectories: true)
            } catch {
                print("Failed to create app Music folder: \(error.localizedDescription)")
                return nil
            }
        }

        ensureMarkerFile(in: musicURL, message: libraryMarkerMessage)

        return musicURL
    }

    private static func ensureMarkerFile(in directoryURL: URL, message: String) {
        let fileManager = FileManager.default
        let markerURL = directoryURL.appendingPathComponent(placeholderFileName, isDirectory: false)

        if fileManager.fileExists(atPath: markerURL.path) {
            return
        }

        do {
            try Data(message.utf8).write(to: markerURL)
        } catch {
            print("Failed to create placeholder file at \(markerURL.path): \(error.localizedDescription)")
        }
    }
}
