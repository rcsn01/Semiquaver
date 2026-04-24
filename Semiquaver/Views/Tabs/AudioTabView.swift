import SwiftUI

enum AudioCategory: String, CaseIterable {
    case artists = "Artists"
    case albums = "Albums"
    case songs = "Songs"
    case genres = "Genres"
}

struct AudioTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var library = AppMusicLibrary()
    @StateObject private var player = AudioPlayerController()
    @State private var selectedCategory: AudioCategory = .songs

    var body: some View {
        PlayerScaffold(
            title: "Audio",
            trailingSystemImage: "arrow.clockwise",
            trailingAction: reloadLibrary
        ) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(AudioCategory.allCases, id: \.self) { category in
                        categoryButton(category)
                    }
                }
                .padding(.top, 4)

                Divider()
                    .overlay(Color.playerDivider)

                if let currentTrack = player.currentTrack {
                    nowPlayingView(track: currentTrack)

                    Divider()
                        .overlay(Color.playerDivider)
                }

                content
            }
        }
        .task {
            await library.reload()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                reloadLibrary()
            }
        }
        .alert("Playback Error", isPresented: playbackErrorBinding) {
            Button("OK", role: .cancel) {
                player.clearError()
            }
        } message: {
            Text(player.errorMessage ?? "")
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

    @ViewBuilder
    private var content: some View {
        if library.isLoading && library.songs.isEmpty {
            VStack(spacing: 18) {
                Spacer()
                ProgressView()
                    .tint(Color.playerAccent)
                    .scaleEffect(1.2)
                Text("Scanning your Music folder...")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.playerTextSecondary)
                Spacer()
            }
            .padding(.horizontal, 24)
        } else if let errorMessage = library.errorMessage {
            emptyState(
                title: "Music folder unavailable",
                message: errorMessage,
                systemImage: "externaldrive.badge.exclamationmark"
            )
        } else if library.songs.isEmpty {
            emptyState(
                title: "No music found",
                message: "Add audio files in Files > On My iPhone > Semiquaver > Music, then return to Semiquaver.",
                systemImage: "music.note.list"
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
            }
        }
    }

    private func summaryRows(for summaries: [AudioGroupSummary]) -> some View {
        ForEach(summaries) { summary in
            MediaRow(item: summary.mediaItem)

            if summary.id != summaries.last?.id {
                Divider()
                    .overlay(Color.playerDivider)
                    .padding(.leading, 90)
            }
        }
    }

    private func songRows(for songs: [AudioTrack]) -> some View {
        ForEach(songs) { track in
            Button {
                player.togglePlayback(for: track)
            } label: {
                MediaRow(
                    item: track.mediaItem(
                        isCurrent: player.isCurrentTrack(track),
                        isPlaying: player.isPlaying
                    ),
                    trailingSystemImage: trailingImage(for: track),
                    isHighlighted: player.isCurrentTrack(track)
                )
            }
            .buttonStyle(.plain)

            if track.id != songs.last?.id {
                Divider()
                    .overlay(Color.playerDivider)
                    .padding(.leading, 90)
            }
        }
    }

    private func nowPlayingView(track: AudioTrack) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: MediaArtworkPalette.colors(for: track.id),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 62, height: 62)
                .overlay {
                    Image(systemName: player.isPlaying ? "speaker.wave.2.fill" : "pause.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.88))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("Now Playing")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.playerTextSecondary)

                Text(track.title)
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                    .lineLimit(1)

                Text(track.detailText)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.playerTextSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                player.togglePlayPause()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.playerAccent)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.black.opacity(0.12))
    }

    private func emptyState(title: String, message: String, systemImage: String) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
                .foregroundStyle(Color.white)
        } description: {
            Text(message)
                .foregroundStyle(Color.playerTextSecondary)
        }
    }

    private func reloadLibrary() {
        Task {
            await library.reload()
        }
    }

    private func trailingImage(for track: AudioTrack) -> String {
        if player.isCurrentTrack(track) {
            return player.isPlaying ? "pause.fill" : "play.fill"
        }

        return "play.fill"
    }

    private var playbackErrorBinding: Binding<Bool> {
        Binding(
            get: { player.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    player.clearError()
                }
            }
        )
    }
}
