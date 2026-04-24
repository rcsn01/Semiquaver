import SwiftUI

struct VideoTabView: View {
    var body: some View {
        PlayerScaffold(title: "Video") {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Now Playing")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.playerTextSecondary)

                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.playerAccent.opacity(0.35), Color.blue.opacity(0.35)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 210)
                            .overlay(alignment: .bottomLeading) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Night Drive Sessions")
                                        .font(.system(size: 23, weight: .semibold, design: .rounded))
                                    Text("Synthwave Visual Mix - 43:12")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(Color.playerTextSecondary)
                                }
                                .padding(18)
                            }
                    }

                    Text("Recently Added")
                        .font(.system(size: 30, weight: .bold, design: .rounded))

                    VStack(spacing: 0) {
                        ForEach(MockLibrary.videos) { item in
                            MediaRow(item: item, showsChevron: true)
                            if item.id != MockLibrary.videos.last?.id {
                                Divider()
                                    .overlay(Color.playerDivider)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 36)
            }
        }
    }
}
