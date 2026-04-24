import SwiftUI

struct BrowseTabView: View {
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        PlayerScaffold(title: "Browse", trailingSystemImage: "magnifyingglass.circle") {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Discover")
                        .font(.system(size: 30, weight: .bold, design: .rounded))

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(MockLibrary.browseTiles) { tile in
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: tile.colors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 120)
                                .overlay(alignment: .bottomLeading) {
                                    Text(tile.title)
                                        .font(.system(size: 19, weight: .bold, design: .rounded))
                                        .padding(12)
                                }
                        }
                    }

                    Text("Trending Artists")
                        .font(.system(size: 26, weight: .bold, design: .rounded))

                    VStack(spacing: 0) {
                        ForEach(MockLibrary.artists.prefix(4)) { item in
                            MediaRow(item: item, showsChevron: true)
                            if item.id != MockLibrary.artists.prefix(4).last?.id {
                                Divider()
                                    .overlay(Color.playerDivider)
                            }
                        }
                    }
                    .background(Color.black.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 34)
            }
        }
    }
}
