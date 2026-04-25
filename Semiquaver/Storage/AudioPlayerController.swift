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
    @Published var repeatMode: RepeatMode = .off
    @Published var shuffleByDefault = false

    @Published var playbackQueue: [AudioTrack] = []
    @Published var playbackContext: PlaybackContext = .library
    @Published var playbackHistory: [AudioTrack] = []

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

    func play(track: AudioTrack, in queue: [AudioTrack], context: PlaybackContext) {
        playbackContext = context
        playbackHistory = []

        // Rotate queue so the tapped track is first
        if let index = queue.firstIndex(where: { $0.id == track.id }) {
            var reordered = Array(queue[index...]) + Array(queue[..<index])
            if shuffleByDefault {
                let tail = Array(reordered.dropFirst())
                let shuffledTail = tail.shuffled()
                reordered = [reordered[0]] + shuffledTail
            }
            playbackQueue = reordered
        } else {
            playbackQueue = [track]
        }

        play(track)
    }

    func addToQueue(_ track: AudioTrack) {
        playbackQueue.append(track)
    }

    func removeFromQueue(at index: Int) {
        guard index >= 0, index < playbackQueue.count else { return }
        playbackQueue.remove(at: index)
    }

    func moveQueueItem(from source: IndexSet, to destination: Int) {
        playbackQueue.move(fromOffsets: source, toOffset: destination)
    }

    func addToHistory(_ track: AudioTrack) {
        playbackHistory.append(track)
    }

    func togglePlayback(for track: AudioTrack) {
        if currentTrack?.id == track.id {
            togglePlayPause()
            return
        }
        // If no explicit queue/context, default to library
        play(track: track, in: playbackQueue.isEmpty ? [track] : playbackQueue, context: playbackContext)
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

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentTrack = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        playbackQueue = []
        playbackHistory = []
        stopProgressTimer()
        updateNowPlayingInfo()
        updateRemoteCommandAvailability()
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

    func playPrevious() {
        guard let current = currentTrack else { return }

        if currentTime > 3 {
            setCurrentTime(0)
            return
        }

        if let lastHistoryTrack = playbackHistory.popLast() {
            // Rotate queue so the history track is placed at front, current at position 1
            let reordered = [lastHistoryTrack, current] + playbackQueue.filter { $0.id != lastHistoryTrack.id && $0.id != current.id }
            playbackQueue = reordered
            play(lastHistoryTrack)
        }
    }

    func playNext() {
        guard let current = currentTrack else { return }

        // Check if current track is still at the front of queue and remove it
        if let first = playbackQueue.first, first.id == current.id {
            _ = playbackQueue.removeFirst()
        }

        // Next track logic
        if repeatMode == .one {
            self.play(current)
            return
        }

        if !playbackQueue.isEmpty {
            play(playbackQueue[0])
        } else if repeatMode == .all {
            // Rebuild queue from history, keep original order
            playbackQueue = playbackHistory + [current]
            playbackHistory = []
            play(playbackQueue[0])
        }
    }

    func shuffleQueue() {
        guard let current = currentTrack else { return }

        if let first = playbackQueue.first, first.id == current.id {
            let tail = Array(playbackQueue.dropFirst())
            playbackQueue = [current] + tail.shuffled()
        } else {
            // If current is not first, just shuffle what we have
            playbackQueue = playbackQueue.shuffled()
        }
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
            self.playNext()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.playPrevious()
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
        commandCenter.nextTrackCommand.isEnabled = hasTrack && !playbackQueue.isEmpty
        commandCenter.previousTrackCommand.isEnabled = hasTrack && !playbackHistory.isEmpty
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
        Task { @MainActor [self] in
            self.isPlaying = false
            self.stopProgressTimer()

            if let track = self.currentTrack {
                self.playbackHistory.append(track)
            }

            self.updateNowPlayingInfo()
            self.playNext()
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        Task { @MainActor [self] in
            self.isPlaying = false
            self.stopProgressTimer()
            self.errorMessage = error?.localizedDescription ?? "Semiquaver couldn't decode that audio file."
        }
    }
}
