import SwiftUI

enum AudioCategory: String, CaseIterable {
    case artists = "Artists"
    case albums = "Albums"
    case songs = "Songs"
    case genres = "Genres"
}

struct AudioTabView: View {
    @State private var selectedCategory: AudioCategory = .songs

    private var items: [MediaItem] {
        switch selectedCategory {
        case .artists:
            MockLibrary.artists
        case .albums:
            MockLibrary.albums
        case .songs:
            MockLibrary.songs
        case .genres:
            MockLibrary.genres
        }
    }

    var body: some View {
        PlayerScaffold(title: "Audio", trailingSystemImage: "ellipsis.circle") {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(AudioCategory.allCases, id: \.self) { category in
                        categoryButton(category)
                    }
                }
                .padding(.top, 4)

                Divider()
                    .overlay(Color.playerDivider)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(items) { item in
                            MediaRow(item: item)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private func categoryButton(_ category: AudioCategory) -> some View {
        let isSelected = selectedCategory == category

        return Button {
            selectedCategory = category
        } label: {
            VStack(spacing: 12) {
                Text(category.rawValue)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? Color.playerAccent : Color.playerMuted)
                    .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(isSelected ? Color.playerAccent : Color.clear)
                    .frame(height: 4)
            }
        }
        .buttonStyle(.plain)
    }
}
