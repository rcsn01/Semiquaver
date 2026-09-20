import SwiftUI
import MoirasiaUI

struct QueueListView: View {
    @ObservedObject var player: AudioPlayerController
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false

    var body: some View {
        NavigationStack {
            List {
                // Now Playing Section
                Section {
                    if let currentTrack = player.currentTrack {
                        MediaRow(
                            item: currentTrack.mediaItem(
                                isCurrent: true,
                                isPlaying: player.isPlaying
                            ),
                            trailingSystemImage: player.isPlaying ? "pause.fill" : "play.fill",
                            isHighlighted: false
                        )
                        .listRowBackground(MoiraColor.controlSelected)
                    } else {
                        Text("Nothing playing")
                            .font(MoiraType.body())
                            .foregroundStyle(MoiraColor.textMuted)
                            .listRowBackground(Color.clear)
                    }
                } header: {
                    Text("Now Playing")
                        .font(MoiraType.small(weight: .semibold))
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .foregroundStyle(MoiraColor.textMuted)
                        .padding(.bottom, 4)
                }

                // History Section
                if !player.playbackHistory.isEmpty {
                    Section {
                        ForEach(player.playbackHistory) { track in
                            MediaRow(
                                item: track.mediaItem(isCurrent: false, isPlaying: false)
                            )
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    withAnimation {
                                        player.addToQueue(track)
                                    }
                                } label: {
                                    Label("Queue", systemImage: "text.line.first.and.arrowtriangle.forward")
                                }
                            }
                        }
                    } header: {
                        Text("History")
                            .font(MoiraType.small(weight: .semibold))
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .foregroundStyle(MoiraColor.textMuted)
                            .padding(.bottom, 4)
                    }
                }

                // Up Next Section
                Section {
                    if player.playbackQueue.isEmpty {
                        Text("End of queue")
                            .font(MoiraType.body())
                            .foregroundStyle(MoiraColor.textMuted)
                    } else {
                        ForEach(Array(player.playbackQueue.enumerated()), id: \.element.id) { index, track in
                            MediaRow(
                                item: track.mediaItem(isCurrent: false, isPlaying: false)
                            )
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        player.removeFromQueue(at: index)
                                    }
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                        .onMove(perform: { indices, newOffset in
                            player.moveQueueItem(from: indices, to: newOffset)
                        })
                    }
                } header: {
                    HStack {
                        Text("Up Next")
                            .font(MoiraType.small(weight: .semibold))
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .foregroundStyle(MoiraColor.textMuted)
                            .padding(.bottom, 4)

                        Spacer()

                        if !player.playbackQueue.isEmpty {
                            Button {
                                withAnimation {
                                    isEditing.toggle()
                                }
                            } label: {
                                Text(isEditing ? "Done" : "Edit")
                                    .font(MoiraType.small(weight: .semibold))
                                    .foregroundStyle(MoiraColor.textPrimary)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            .scrollContentBackground(.hidden)
            .background(MoiraColor.canvas)
            .navigationTitle("Queue")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(MoiraColor.textPrimary)
                }
            }
        }
    }
}
