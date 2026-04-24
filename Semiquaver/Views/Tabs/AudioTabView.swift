import SwiftUI

enum AudioCategory: String, CaseIterable {
    case artists = "Artists"
    case albums = "Albums"
    case songs = "Songs"
    case genres = "Genres"
}

struct AudioTabView: View {
    @StateObject private var library = AppMusicLibrary()
    @ObservedObject var player: AudioPlayerController
    @State private var selectedCategory: AudioCategory = .songs
    @Binding var showNowPlayingFullScreen: Bool

    var body: some View {
        ZStack {
            PlayerBackground()

            VStack(spacing: 0) {
                header

                Divider()
                    .overlay(Color.playerDivider)

                categoryBar

                content
            }
        }
        .task {
            await library.reload()
        }
        .onChange(of: library.tracks) { _, newTracks in
            player.setLibrary(newTracks)
        }
        // Reload on scene phase activation removed to avoid full rescans on every foreground.
        // Library stays current via incremental background sync on next cold launch.
        // Use the header refresh button for a forced rescan.
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Text("Library")
                .font(.display())
                .foregroundStyle(Color.playerTextPrimary)

            Spacer()

            Button(action: reloadLibrary) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.playerAccent)
                    .frame(width: 40, height: 40)
                    .background(Color.playerGlass)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.playerGlassBorder, lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    // MARK: - Category Bar

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AudioCategory.allCases, id: \.self) { category in
                    categoryButton(category)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func categoryButton(_ category: AudioCategory) -> some View {
        let isSelected = selectedCategory == category

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedCategory = category
            }
        } label: {
            Text(category.rawValue)
                .font(.system(size: 14, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundStyle(isSelected ? Color.playerBackground : Color.playerTextSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(isSelected ? Color.playerAccent : Color.playerGlass)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(isSelected ? Color.clear : Color.playerGlassBorder, lineWidth: 0.5)
                        )
                )
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if library.isLoading && library.songs.isEmpty {
            loadingState
        } else if let errorMessage = library.errorMessage {
            emptyState(
                title: "Music folder unavailable",
                message: errorMessage,
                systemImage: "externaldrive.badge.exclamationmark"
            )
        } else if library.songs.isEmpty {
            emptyState(
                title: "No music found",
                message: "Add audio files to your Music folder and pull to refresh.",
                systemImage: "music.note"
            )
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    switch selectedCategory {
                    case .artists:
                        summaryRows(for: library.artists)
                    case .albums:
                        summaryRows(for: library.albums)
                    case .songs:
                        songRows(for: library.songs)
                    case .genres:
                        summaryRows(for: library.genres)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Rows

    private func summaryRows(for summaries: [AudioGroupSummary]) -> some View {
        ForEach(summaries) { summary in
            MediaRow(item: summary.mediaItem)
                .padding(.horizontal, 4)

            if summary.id != summaries.last?.id {
                Divider()
                    .overlay(Color.playerDivider)
                    .padding(.leading, 76)
            }
        }
    }

    private func songRows(for songs: [AudioTrack]) -> some View {
        ForEach(songs) { track in
            Button {
                player.togglePlayback(for: track)
                showNowPlayingFullScreen = true
            } label: {
                MediaRow(
                    item: track.mediaItem(
                        isCurrent: player.isCurrentTrack(track),
                        isPlaying: player.isPlaying
                    ),
                    trailingSystemImage: trailingImage(for: track),
                    isHighlighted: player.isCurrentTrack(track)
                )
                .padding(.horizontal, 4)
            }
            .buttonStyle(PressScaleButtonStyle())

            if track.id != songs.last?.id {
                Divider()
                    .overlay(Color.playerDivider)
                    .padding(.leading, 76)
            }
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.playerGlassBorder, lineWidth: 3)
                    .frame(width: 48, height: 48)

                ProgressView()
                    .tint(Color.playerAccent)
                    .scaleEffect(1.2)
            }

            Text("Scanning your library...")
                .font(.bodyRegular())
                .foregroundStyle(Color.playerTextSecondary)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func emptyState(title: String, message: String, systemImage: String) -> some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: systemImage)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Color.playerTextTertiary)
                .padding(.bottom, 8)

            Text(title)
                .font(.heading())
                .foregroundStyle(Color.playerTextPrimary)

            Text(message)
                .font(.bodyRegular())
                .foregroundStyle(Color.playerTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
        .padding(.bottom, 24)
    }

    // MARK: - Helpers

    private func reloadLibrary() {
        Task {
            await library.reload(force: true)
        }
    }

    private func trailingImage(for track: AudioTrack) -> String {
        if player.isCurrentTrack(track) {
            return player.isPlaying ? "pause.fill" : "play.fill"
        }
        return "play.fill"
    }

}
