import SwiftUI

struct MediaItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]
}

struct PlaylistItem: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let colors: [Color]
}

struct BrowseTile: Identifiable {
    let id = UUID()
    let title: String
    let colors: [Color]
}
