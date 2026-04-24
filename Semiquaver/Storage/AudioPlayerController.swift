import AVFoundation
import Combine
import Foundation
import MediaPlayer
import SwiftUI

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
    private var wasPlayingBeforeInterruption = false
    private var interruptionObserver: NSObjectProtocol?

    // MARK: - Lifecycle

    override init() {
        super.init()
        registerRemoteCommands()
        observeAudioInterruptions()
    }

    deinit {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

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
            pause()
        } else {
            resume()
        }
    }

    func pause() {
        guard let audioPlayer else { return }
        audioPlayer.pause()
        isPlaying = false
        stopProgressTimer()
        updateNowPlayingInfo()
    }

    func resume() {
        guard let audioPlayer else { return }
        audioPlayer.play()
        isPlaying = true
        startProgressTimer()
        updateNowPlayingInfo()
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
        updateNowPlayingInfo()
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
        updateNowPlayingInfo()
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
            updateNowPlayingInfo()
            updateRemoteCommandAvailability()
        } catch {
            errorMessage = error.localizedDescription
            isPlaying = false
        }
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
    }

    // MARK: - Timer

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if !self.isDraggingSlider {
                    self.currentTime = self.audioPlayer?.currentTime ?? 0
                }
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    // MARK: - Audio Interruptions

    private func observeAudioInterruptions() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleInterruption(notification)
            }
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            wasPlayingBeforeInterruption = isPlaying
            if isPlaying {
                audioPlayer?.pause()
                isPlaying = false
                stopProgressTimer()
                updateNowPlayingInfo()
            }
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume), wasPlayingBeforeInterruption {
                    resume()
                }
            }
            wasPlayingBeforeInterruption = false
        @unknown default:
            break
        }
    }

    // MARK: - Remote Commands

    private func registerRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.resume()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.pause()
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.togglePlayPause()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.playNext(from: self.libraryTracks)
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.playPrevious(from: self.libraryTracks)
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.setCurrentTime(positionEvent.positionTime)
            self.updateNowPlayingInfo()
            return .success
        }

        updateRemoteCommandAvailability()
    }

    private func updateRemoteCommandAvailability() {
        let commandCenter = MPRemoteCommandCenter.shared()
        let hasTrack = currentTrack != nil
        commandCenter.playCommand.isEnabled = hasTrack
        commandCenter.pauseCommand.isEnabled = hasTrack
        commandCenter.togglePlayPauseCommand.isEnabled = hasTrack
        commandCenter.nextTrackCommand.isEnabled = hasTrack && !libraryTracks.isEmpty
        commandCenter.previousTrackCommand.isEnabled = hasTrack && !libraryTracks.isEmpty
        commandCenter.changePlaybackPositionCommand.isEnabled = hasTrack
    }

    // MARK: - Now Playing Info Center

    private func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist == AudioMetadataFallbacks.artist ? "Unknown Artist" : track.artist,
            MPMediaItemPropertyAlbumTitle: track.album,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyIsLiveStream: false
        ]

        if let artworkData = track.artworkData,
           let image = UIImage(data: artworkData) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerController: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.stopProgressTimer()
            self.updateNowPlayingInfo()

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
