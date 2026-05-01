import Foundation
import AVFoundation
import MediaPlayer
import Combine

final class PlayerService: NSObject, ObservableObject {
    static let shared = PlayerService()

    @Published private(set) var currentBook: Book?
    @Published private(set) var currentChapter: Chapter?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var progress: Double = 0.0

    private let synthesizer = AVSpeechSynthesizer()
    private var spokenCharacterCount: Int = 0
    private var totalCharacterCount: Int = 1

    var onChapterChange: ((Book, Chapter) -> Void)?

    override private init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
        configureRemoteCommands()
    }

    func play(book: Book, chapter: Chapter) {
        if currentChapter?.id == chapter.id, synthesizer.isPaused {
            synthesizer.continueSpeaking()
            isPlaying = true
            updateNowPlaying()
            return
        }

        synthesizer.stopSpeaking(at: .immediate)
        currentBook = book
        currentChapter = chapter
        spokenCharacterCount = 0
        totalCharacterCount = max(chapter.summary.count, 1)
        progress = 0

        let utterance = AVSpeechUtterance(string: chapter.summary)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        synthesizer.speak(utterance)
        isPlaying = true
        updateNowPlaying()
        onChapterChange?(book, chapter)
    }

    func togglePlayPause() {
        if synthesizer.isSpeaking, !synthesizer.isPaused {
            synthesizer.pauseSpeaking(at: .word)
            isPlaying = false
        } else if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            isPlaying = true
        } else if let book = currentBook, let chapter = currentChapter {
            play(book: book, chapter: chapter)
        }
        updateNowPlaying()
    }

    func skipToNextChapter() {
        guard let book = currentBook, let chapter = currentChapter,
              let next = book.chapter(after: chapter) else { return }
        play(book: book, chapter: next)
    }

    func skipToPreviousChapter() {
        guard let book = currentBook, let chapter = currentChapter,
              let previous = book.chapter(before: chapter) else { return }
        play(book: book, chapter: previous)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        progress = 0
        spokenCharacterCount = 0
        currentBook = nil
        currentChapter = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [])
        try? session.setActive(true, options: [])
    }

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.skipToNextChapter()
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.skipToPreviousChapter()
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let book = currentBook, let chapter = currentChapter else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: chapter.title,
            MPMediaItemPropertyArtist: book.author,
            MPMediaItemPropertyAlbumTitle: book.title,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyPlaybackProgress: Float(progress)
        ]
        info[MPMediaItemPropertyPlaybackDuration] = TimeInterval(chapter.estimatedDurationMinutes * 60)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

extension PlayerService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           willSpeakRangeOfSpeechString characterRange: NSRange,
                           utterance: AVSpeechUtterance) {
        spokenCharacterCount = characterRange.location
        progress = Double(spokenCharacterCount) / Double(totalCharacterCount)
        updateNowPlaying()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {
        progress = 1.0
        isPlaying = false
        updateNowPlaying()
        skipToNextChapter()
    }
}
