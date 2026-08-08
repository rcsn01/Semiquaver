import SwiftUI

/// iOS presentation shell around the platform-neutral Now Playing content.
struct NowPlayingView: View {
    let track: AudioTrack
    @ObservedObject var player: AudioPlayerController
    @ObservedObject var library: AppMusicLibrary
    @ObservedObject var playlistStorage: PlaylistStorage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @State private var dragOffset: CGFloat = 0
    @State private var showDeleteConfirmation = false
    @State private var showQueue = false
    @State private var errorMessage: String?

    private var activeTrack: AudioTrack { player.currentTrack ?? track }

    var body: some View {
        ZStack {
            PlayerBackground()
            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    NowPlayingContent(
                        player: player,
                        playlists: playlistStorage,
                        layoutMode: .compact,
                        showQueue: { showQueue = true }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .presentationBackground(.clear)
        .offset(y: dragOffset)
        .gesture(dismissGesture)
        .sheet(isPresented: $showQueue) {
            QueueListView(player: player)
        }
        .alert("Delete Song", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { deleteActiveTrack() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(activeTrack.title)\"? This will remove the file from your Music folder.")
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            headerButton(systemImage: "chevron.down") { dismiss() }
                .frame(width: 100, alignment: .leading)
            Spacer()
            Text("Now Playing")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .textCase(.uppercase)
                .tracking(0.5)
                .foregroundStyle(Color.playerTextSecondary)
            Spacer()
            HStack(spacing: 12) {
                headerButton(systemImage: "trash", foregroundColor: .playerAccent) {
                    showDeleteConfirmation = true
                }
                headerButton(systemImage: "list.bullet") { showQueue = true }
            }
            .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    private var dismissGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 { dragOffset = value.translation.height }
            }
            .onEnded { value in
                let shouldDismiss = value.translation.height > 120
                    || value.predictedEndTranslation.height > 200
                if shouldDismiss {
                    if reduceMotion {
                        dismiss()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            dragOffset = UIScreen.main.bounds.height
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { dismiss() }
                    }
                } else {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.85)) {
                        dragOffset = 0
                    }
                }
            }
    }

    private func headerButton(
        systemImage: String,
        foregroundColor: Color = .playerTextSecondary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(foregroundColor)
                .frame(width: 44, height: 44)
                .background(Color.playerGlass)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.playerGlassBorder, lineWidth: 0.5)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private func deleteActiveTrack() {
        let track = activeTrack
        do {
            try FileManager.default.removeItem(at: track.fileURL)
            playlistStorage.removeTrackFromAllPlaylists(track.id)
            player.removeTracks(withIDs: [track.id])
            Task { await library.reload(force: true) }
            dismiss()
        } catch {
            errorMessage = "Failed to delete song: \(error.localizedDescription)"
        }
    }
}
