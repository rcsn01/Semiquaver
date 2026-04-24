import AVFoundation
import Combine
import Foundation

@MainActor
final class AudioPlayerController: NSObject, ObservableObject {
    @Published private(set) var currentTrack: AudioTrack?
    @Published private(set) var isPlaying = false
    @Published private(set) var errorMessage: String?

    private var audioPlayer: AVAudioPlayer?

    func togglePlayback(for track: AudioTrack) {
        if currentTrack?.id == track.id {
            togglePlayPause()
            return
        }

        play(track)
    }

    func togglePlayPause() {
        guard let audioPlayer else {
            return
        }

        if audioPlayer.isPlaying {
            audioPlayer.pause()
            isPlaying = false
        } else {
            audioPlayer.play()
            isPlaying = true
        }
    }

    func isCurrentTrack(_ track: AudioTrack) -> Bool {
        currentTrack?.id == track.id
    }

    func clearError() {
        errorMessage = nil
    }

    private func play(_ track: AudioTrack) {
        do {
            try configureAudioSession()

            let audioPlayer = try AVAudioPlayer(contentsOf: track.fileURL)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            audioPlayer.play()

            self.audioPlayer = audioPlayer
            currentTrack = track
            isPlaying = true
            errorMessage = nil
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
}

extension AudioPlayerController: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        Task { @MainActor in
            self.isPlaying = false
            self.errorMessage = error?.localizedDescription ?? "Semiquaver couldn't decode that audio file."
        }
    }
}