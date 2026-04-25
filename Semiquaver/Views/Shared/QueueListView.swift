import SwiftUI

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
                        .listRowBackground(Color.playerAccent.opacity(0.06))
                    } else {
                        Text("Nothing playing")
                            .font(.bodyRegular())
                            .foregroundStyle(Color.playerTextSecondary)
                            .listRowBackground(Color.clear)
                    }
                } header: {
                    Text("Now Playing")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .foregroundStyle(Color.playerAccent)
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
                                .tint(Color.playerAccent)
                            }
                        }
                    } header: {
                        Text("History")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .foregroundStyle(Color.playerAccent)
                            .padding(.bottom, 4)
                    }
                }

                // Up Next Section
                Section {
                    if player.playbackQueue.isEmpty {
                        Text("End of queue")
                            .font(.bodyRegular())
                            .foregroundStyle(Color.playerTextSecondary)
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
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .foregroundStyle(Color.playerAccent)
                            .padding(.bottom, 4)

                        Spacer()

                        if !player.playbackQueue.isEmpty {
                            Button {
                                withAnimation {
                                    isEditing.toggle()
                                }
                            } label: {
                                Text(isEditing ? "Done" : "Edit")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.playerAccent)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            .scrollContentBackground(.hidden)
            .background(Color.playerBackground)
            .navigationTitle("Queue")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.playerAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
