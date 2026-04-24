import AVFoundation
import Combine
import Foundation

enum RepeatMode: String, CaseIterable {
    case off = "off"
    case one = "one"
    case all = "all"
}

@MainActor
final class AudioPlayerController: NSObject, ObservableObject {
    @Published private(set) var currentTrack: AudioTrack?
    @Published private(set) var isPlaying = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published var shuffleEnabled = false
    @Published var repeatMode: RepeatMode = .off

    @Published private(set) var libraryTracks: [AudioTrack] = []

    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    private var isDraggingSlider = false

    // MARK: - Playback

    func togglePlayback(for track: AudioTrack) {
        if currentTrack?.id == track.id {
            togglePlayPause()
            return
        }
        play(track)
    }

    func togglePlayPause() {
        guard let audioPlayer else { return }

        if audioPlayer.isPlaying {
            audioPlayer.pause()
            isPlaying = false
            stopProgressTimer()
        } else {
            audioPlayer.play()
            isPlaying = true
            startProgressTimer()
        }
    }

    func isCurrentTrack(_ track: AudioTrack) -> Bool {
        currentTrack?.id == track.id
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Progress

    func beginSliderInteraction() {
        isDraggingSlider = true
    }

    func endSliderInteraction(at time: TimeInterval) {
        isDraggingSlider = false
        setCurrentTime(time)
    }

    func updateSliderTime(_ time: TimeInterval) {
        guard isDraggingSlider else { return }
        currentTime = time
    }

    func setCurrentTime(_ time: TimeInterval) {
        guard let audioPlayer else { return }
        let clamped = max(0, min(time, duration))
        audioPlayer.currentTime = clamped
        currentTime = clamped
    }

    // MARK: - Navigation

    func playPrevious(from tracks: [AudioTrack]) {
        guard let current = currentTrack else { return }
        guard let currentIndex = tracks.firstIndex(where: { $0.id == current.id }) else { return }

        if currentTime > 3 {
            setCurrentTime(0)
            return
        }

        let newIndex = max(0, currentIndex - 1)
        if newIndex != currentIndex {
            play(tracks[newIndex])
        }
    }

    func playNext(from tracks: [AudioTrack]) {
        guard let current = currentTrack else { return }
        guard let currentIndex = tracks.firstIndex(where: { $0.id == current.id }) else { return }

        let newIndex: Int
        if shuffleEnabled {
            newIndex = Int.random(in: 0..<tracks.count)
        } else {
            newIndex = min(currentIndex + 1, tracks.count - 1)
        }

        if repeatMode == .all && newIndex == currentIndex {
            play(tracks[0])
        } else if newIndex != currentIndex {
            play(tracks[newIndex])
        }
    }

    // MARK: - Library

    func setLibrary(_ tracks: [AudioTrack]) {
        libraryTracks = tracks
    }

    // MARK: - Private

    private func play(_ track: AudioTrack) {
        do {
            try configureAudioSession()

            let audioPlayer = try AVAudioPlayer(contentsOf: track.fileURL)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            audioPlayer.play()

            self.audioPlayer = audioPlayer
            currentTrack = track
            duration = audioPlayer.duration
            currentTime = 0
            isPlaying = true
            errorMessage = nil
            startProgressTimer()
        } catch {
            errorMessage = error.localizedDescription
            isPlaying = false
        }
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
    }

    // MARK: - Timer

    private func startProgressTimer() {
        stopProgressTimer()
        self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                guard !self.isDraggingSlider else { return }
                self.currentTime = self.audioPlayer?.currentTime ?? 0
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerController: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.stopProgressTimer()

            if repeatMode == .one {
                if let track = currentTrack {
                    self.play(track)
                }
            } else if !libraryTracks.isEmpty {
                playNext(from: libraryTracks)
            }
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        Task { @MainActor in
            self.isPlaying = false
            self.stopProgressTimer()
            self.errorMessage = error?.localizedDescription ?? "Semiquaver couldn't decode that audio file."
        }
    }
}
