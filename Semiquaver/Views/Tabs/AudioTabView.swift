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
    @State private var showNowPlayingFullScreen = false

    var body: some View {
        PlayerScaffold(
            title: "Library",
            trailingSystemImage: "arrow.clockwise",
            trailingAction: reloadLibrary
        ) {
            VStack(spacing: 0) {
                categoryBar

                if let currentTrack = player.currentTrack {
                    Button {
                        showNowPlayingFullScreen = true
                    } label: {
                        NowPlayingBar(track: currentTrack, player: player)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                content
            }
        }
        .task {
            await library.reload()
        }
        .onChange(of: library.tracks) { _, newTracks in
            player.setLibrary(newTracks)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                reloadLibrary()
            }
        }
        .sheet(isPresented: $showNowPlayingFullScreen) {
            if let currentTrack = player.currentTrack {
                NowPlayingView(track: currentTrack, player: player)
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
            }
        }
    }

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
