import SwiftUI

struct NowPlayingView: View {
    let track: AudioTrack
    @ObservedObject var player: AudioPlayerController
    @Environment(\.dismiss) private var dismiss
    @StateObject private var playlistStorage = PlaylistStorage()
    @State private var dragOffset: CGFloat = 0
    @State private var showActionSheet = false
    @State private var showAddToPlaylistSheet = false
    @State private var showRemoveFromPlaylistSheet = false
    @State private var showDeleteConfirmation = false
    @State private var errorMessage: String?

    private var artworkImage: UIImage? {
        if let data = track.artworkData {
            return UIImage(data: data)
        }
        return nil
    }

    var body: some View {
        ZStack {
            PlayerBackground()

            VStack(spacing: 0) {
                header

                Spacer(minLength: 20)

                VStack(spacing: 40) {
                    artworkDisplay

                    trackInfo

                    progressSection

                    controlsSection
                }
                .padding(.horizontal, 28)

                Spacer(minLength: 40)
            }
        }
        .presentationBackground(.clear)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let translation = value.translation.height
                    if translation > 0 {
                        dragOffset = translation
                    }
                }
                .onEnded { value in
                    let translation = value.translation.height
                    let velocity = value.predictedEndTranslation.height
                    if translation > 120 || velocity > 200 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            dragOffset = UIScreen.main.bounds.height
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            dismiss()
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .confirmationDialog("Track Options", isPresented: $showActionSheet, titleVisibility: .visible) {
            Button("Add to Playlist") {
                showAddToPlaylistSheet = true
            }
            if !playlistStorage.playlistsContaining(trackID: track.id).isEmpty {
                Button("Remove from Playlist") {
                    showRemoveFromPlaylistSheet = true
                }
            }
            Button("Delete Song", role: .destructive) {
                showDeleteConfirmation = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showAddToPlaylistSheet) {
            PlaylistPickerSheet(
                trackID: track.id,
                playlistStorage: playlistStorage,
                mode: .add
            )
        }
        .sheet(isPresented: $showRemoveFromPlaylistSheet) {
            PlaylistPickerSheet(
                trackID: track.id,
                playlistStorage: playlistStorage,
                mode: .remove
            )
        }
        .alert("Delete Song", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteTrack()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(track.title)\"? This will remove the file from your Music folder.")
        }
        .alert("Error", isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.playerTextSecondary)
                    .frame(width: 44, height: 44)
                    .background(Color.playerGlass)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.playerGlassBorder, lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(PressScaleButtonStyle())

            Spacer()

            Text("Now Playing")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .textCase(.uppercase)
                .tracking(0.5)
                .foregroundStyle(Color.playerTextSecondary)

            Spacer()

            Button {
                showActionSheet = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.playerTextSecondary)
                    .frame(width: 44, height: 44)
                    .background(Color.playerGlass)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.playerGlassBorder, lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var artworkDisplay: some View {
        if let artworkImage {
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                Image(uiImage: artworkImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 12)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxHeight: 340)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: MediaArtworkPalette.colors(for: track.id),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 12)

                Image(systemName: "music.note")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxHeight: 340)
            .modifier(GlowModifier(color: MediaArtworkPalette.colors(for: track.id).first ?? .clear, radius: 20))
        }
    }

    private var trackInfo: some View {
        VStack(spacing: 8) {
            Text(track.title)
                .font(.system(size: 24, weight: .bold, design: .default))
                .foregroundStyle(Color.playerTextPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(track.detailText)
                .font(.system(size: 16, weight: .medium, design: .default))
                .foregroundStyle(Color.playerTextSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
    }

    private var progressSection: some View {
        VStack(spacing: 10) {
            Slider(
                value: .init(
                    get: { player.currentTime },
                    set: { player.updateSliderTime($0) }
                ),
                in: 0...max(player.duration, 1)
            ) { editing in
                if editing {
                    player.beginSliderInteraction()
                } else {
                    player.endSliderInteraction(at: player.currentTime)
                }
            }
            .tint(Color.playerAccent)
            .padding(.horizontal, 4)

            HStack {
                Text(formatTime(player.currentTime))
                    .font(.captionSmall())
                    .foregroundStyle(Color.playerTextSecondary)
                    .monospacedDigit()

                Spacer()

                Text(formatTime(player.duration))
                    .font(.captionSmall())
                    .foregroundStyle(Color.playerTextSecondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 6)
        }
    }

    private var controlsSection: some View {
        VStack(spacing: 32) {
            // Secondary controls
            HStack(spacing: 32) {
                Button {
                    player.shuffleEnabled.toggle()
                } label: {
                    Image(systemName: "shuffle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(player.shuffleEnabled ? Color.playerAccent : Color.playerTextTertiary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(PressScaleButtonStyle())

                Spacer()

                Button {
                    player.repeatMode = nextRepeatMode(player.repeatMode)
                } label: {
                    Group {
                        switch player.repeatMode {
                        case .off:
                            Image(systemName: "repeat")
                                .foregroundStyle(Color.playerTextTertiary)
                        case .all:
                            Image(systemName: "repeat")
                                .foregroundStyle(Color.playerAccent)
                        case .one:
                            Image(systemName: "repeat.1")
                                .foregroundStyle(Color.playerAccent)
                        }
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
                }
                .buttonStyle(PressScaleButtonStyle())
            }

            // Primary controls
            HStack(spacing: 36) {
                Button {
                    player.playPrevious(from: player.libraryTracks)
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(player.libraryTracks.isEmpty ? Color.playerTextTertiary : Color.playerTextPrimary)
                        .frame(width: 56, height: 56)
                }
                .buttonStyle(PressScaleButtonStyle())
                .disabled(player.libraryTracks.isEmpty)

                Button {
                    player.togglePlayPause()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 40, style: .continuous)
                            .fill(Color.playerAccent)
                            .frame(width: 80, height: 80)
                            .shadow(color: Color.playerAccent.opacity(0.25), radius: 16, x: 0, y: 8)

                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(Color.black)
                    }
                }
                .buttonStyle(PressScaleButtonStyle())

                Button {
                    player.playNext(from: player.libraryTracks)
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(player.libraryTracks.isEmpty ? Color.playerTextTertiary : Color.playerTextPrimary)
                        .frame(width: 56, height: 56)
                }
                .buttonStyle(PressScaleButtonStyle())
                .disabled(player.libraryTracks.isEmpty)
            }
        }
    }

    // MARK: - Helpers

    private func nextRepeatMode(_ mode: RepeatMode) -> RepeatMode {
        switch mode {
        case .off: return .all
        case .all: return .one
        case .one: return .off
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = max(Int(time.rounded()), 0)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func deleteTrack() {
        do {
            try FileManager.default.removeItem(at: track.fileURL)
            // Remove from all playlists
            for playlist in playlistStorage.playlistsContaining(trackID: track.id) {
                playlistStorage.removeTrack(track.id, from: playlist)
            }
            // Stop playback if this is the current track
            if player.currentTrack?.id == track.id {
                player.stop()
            }
            dismiss()
        } catch {
            errorMessage = "Failed to delete song: \(error.localizedDescription)"
        }
    }
}

// MARK: - Playlist Picker Sheet

enum PlaylistPickerMode {
    case add
    case remove
}

struct PlaylistPickerSheet: View {
    let trackID: String
    @ObservedObject var playlistStorage: PlaylistStorage
    let mode: PlaylistPickerMode
    @Environment(\.dismiss) private var dismiss

    private var relevantPlaylists: [PlaylistItem] {
        switch mode {
        case .add:
            return playlistStorage.playlists.filter { !$0.trackIDs.contains(trackID) }
        case .remove:
            return playlistStorage.playlistsContaining(trackID: trackID)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.playerBackground.ignoresSafeArea()

                List {
                    ForEach(relevantPlaylists) { playlist in
                        Button {
                            switch mode {
                            case .add:
                                playlistStorage.addTrack(trackID, to: playlist)
                            case .remove:
                                playlistStorage.removeTrack(trackID, from: playlist)
                            }
                            dismiss()
                        } label: {
                            HStack {
                                Text(playlist.title)
                                    .foregroundStyle(Color.playerTextPrimary)
                                Spacer()
                                Text(playlist.detail)
                                    .foregroundStyle(Color.playerTextSecondary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(mode == .add ? "Add to Playlist" : "Remove from Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.playerAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
