import SwiftUI
import MoirasiaUI
import UniformTypeIdentifiers

enum AudioCategory: String, CaseIterable {
    case all = "All"
    case artists = "Artists"
    case albums = "Albums"
}

struct AudioTabView: View {
    @ObservedObject var library: AppMusicLibrary
    @ObservedObject var player: AudioPlayerController
    @ObservedObject var playlists: PlaylistStorage
    @Binding var showNowPlayingFullScreen: Bool
    let onFolderPicked: (URL) -> Void
    @State private var selectedCategory: AudioCategory = .all
    @State private var searchText = ""
    @State private var showFolderPicker = false
 
    var body: some View {
        NavigationStack {
            ZStack {
                MoiraColor.canvas.ignoresSafeArea()

                VStack(spacing: 0) {
                    categoryBar

                    content
                }
            }
        }
        .navigationTitle("Library")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    reloadLibrary()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Songs, artists, albums, genres")
        .fileImporter(
            isPresented: $showFolderPicker,
            allowedContentTypes: [UTType.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first { onFolderPicked(url) }
        }
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
                .font(MoiraType.small(weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? MoiraColor.textPrimary : MoiraColor.textMuted)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: MoiraRadius.pill, style: .continuous)
                        .fill(isSelected ? MoiraColor.controlSelected : MoiraColor.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: MoiraRadius.pill, style: .continuous)
                                .stroke(isSelected ? Color.clear : MoiraColor.border, lineWidth: 0.5)
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
        } else if library.songs.isEmpty && !library.folderConfigured {
            chooseFolderState
        } else if library.songs.isEmpty {
            emptyState(
                title: "No music found",
                message: "The chosen folder has no audio files.",
                systemImage: "music.note"
            )
        } else {
            switch selectedCategory {
            case .artists, .albums:
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        switch selectedCategory {
                        case .artists:
                            artistRows(for: LibrarySearch.groups(
                                library.artists,
                                tracksForGroup: { library.tracksByArtist[$0.title] ?? [] },
                                matching: searchText
                            ))
                        case .albums:
                            albumRows(for: LibrarySearch.groups(
                                library.albums,
                                tracksForGroup: { library.tracksByAlbumID[String($0.id.dropFirst("album::".count))] ?? [] },
                                matching: searchText
                            ))
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            case .all:
                List {
                    songRows(for: LibrarySearch.tracks(library.songs, matching: searchText))
                }
                .listStyle(.plain)
                .scrollIndicators(.hidden)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.horizontal, 0)
            }
        }
    }

    // MARK: - Rows

    private func artistRows(for summaries: [AudioGroupSummary]) -> some View {
        ForEach(summaries) { summary in
            let artistTracks = library.tracksByArtist[summary.title] ?? []

            NavigationLink {
                ArtistDetailView(
                    tracks: artistTracks,
                    artistName: summary.title,
                    player: player,
                    showNowPlayingFullScreen: $showNowPlayingFullScreen
                )
            } label: {
                MediaRow(item: summary.mediaItem, showsChevron: true)
                    .padding(.horizontal, 4)
            }
            .buttonStyle(PressScaleButtonStyle())

            if summary.id != summaries.last?.id {
                Divider()
                    .overlay(MoiraColor.border)
                    .padding(.leading, 76)
            }
        }
    }

    private func albumRows(for summaries: [AudioGroupSummary]) -> some View {
        ForEach(summaries) { summary in
            let albumTracks = library.tracksByAlbumID[String(summary.id.dropFirst("album::".count))] ?? []

            NavigationLink {
                AlbumDetailView(
                    tracks: albumTracks,
                    albumTitle: summary.title,
                    artistName: summary.subtitle.components(separatedBy: " • ").first ?? "Unknown Artist",
                    artworkData: summary.artworkData,
                    player: player,
                    showNowPlayingFullScreen: $showNowPlayingFullScreen
                )
            } label: {
                MediaRow(item: summary.mediaItem, showsChevron: true)
                    .padding(.horizontal, 4)
            }
            .buttonStyle(PressScaleButtonStyle())

            if summary.id != summaries.last?.id {
                Divider()
                    .overlay(MoiraColor.border)
                    .padding(.leading, 76)
            }
        }
    }

    private func songRows(for songs: [AudioTrack]) -> some View {
        ForEach(songs) { track in
            VStack(spacing: 0) {
                Button {
                    if player.play(
                        track: track,
                        in: library.songs,
                        context: .library
                    ) {
                        showNowPlayingFullScreen = true
                    }
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
                .contextMenu {
                    Button("Play", systemImage: "play.fill") {
                        player.play(track: track, in: songs, context: .library)
                    }
                    Button("Add to Queue", systemImage: "text.line.first.and.arrowtriangle.forward") {
                        player.addToQueue(track)
                    }
                    Menu("Add to Playlist") {
                        ForEach(playlists.playlists) { playlist in
                            if playlist.trackIDs.contains(track.id) {
                                Button("Remove from \(playlist.title)") { playlists.removeTrack(track.id, from: playlist) }
                            } else {
                                Button(playlist.title) { playlists.addTrack(track.id, to: playlist) }
                            }
                        }
                    }
                }

                if track.id != songs.last?.id {
                    Divider()
                        .overlay(MoiraColor.border)
                        .padding(.leading, 76)
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
            .swipeActions(edge: .leading) {
                Button {
                    player.addToQueue(track)
                } label: {
                    Label("Queue", systemImage: "text.line.first.and.arrowtriangle.forward")
                }
            }
        }
    }

    // MARK: - Helpers

    private func trailingImage(for track: AudioTrack) -> String? {
        if player.isCurrentTrack(track) {
            return player.isPlaying ? "pause.fill" : "play.fill"
        }
        return nil
    }

    // MARK: - States

    /// Shown when no music folder is configured yet: invites picking one.
    private var chooseFolderState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "folder.badge.music")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(MoiraColor.textSubtle)
                .padding(.bottom, 8)

            Text("No music folder")
                .font(MoiraType.title())
                .foregroundStyle(MoiraColor.textPrimary)

            Text("Choose a folder in Files where your music lives.")
                .font(MoiraType.body())
                .foregroundStyle(MoiraColor.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showFolderPicker = true
            } label: {
                Text("Choose Music Folder")
                    .font(MoiraType.body(weight: .semibold))
                    .foregroundStyle(MoiraColor.canvas)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: MoiraRadius.pill, style: .continuous)
                            .fill(MoiraColor.textPrimary)
                    )
            }
            .buttonStyle(PressScaleButtonStyle())

            Spacer()
        }
        .padding(.bottom, 24)
    }

    private var loadingState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(MoiraColor.border, lineWidth: 3)
                    .frame(width: 48, height: 48)

                ProgressView()
                    .scaleEffect(1.2)
            }

            Text("Scanning your library...")
                .font(MoiraType.body())
                .foregroundStyle(MoiraColor.textMuted)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func emptyState(title: String, message: String, systemImage: String) -> some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: systemImage)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(MoiraColor.textSubtle)
                .padding(.bottom, 8)

            Text(title)
                .font(MoiraType.title())
                .foregroundStyle(MoiraColor.textPrimary)

            Text(message)
                .font(MoiraType.body())
                .foregroundStyle(MoiraColor.textMuted)
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
}
