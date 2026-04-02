import Foundation
import AVFoundation
import Observation
import os

private let logger = Logger(subsystem: "com.evaschesscoach.app", category: "VoiceCoach")

/// Service that synthesizes coaching text to speech via ElevenLabs
/// and plays it back using AVAudioPlayer.
@MainActor
@Observable
final class VoiceCoachService {
    private let client: ElevenLabsClient
    private var audioPlayer: AVAudioPlayer?
    private var playerDelegate: PlaybackDelegate?

    /// Whether audio is currently playing
    private(set) var isSpeaking: Bool = false

    /// Whether the service is fetching audio from the API
    private(set) var isLoading: Bool = false

    /// Last error message
    private(set) var lastError: String?

    /// Whether the ElevenLabs API is configured (has API key)
    var isConfigured: Bool {
        let key = ProcessInfo.processInfo.environment["ELEVENLABS_API_KEY"] ?? ""
        return !key.isEmpty
    }

    init(client: ElevenLabsClient = ElevenLabsClient()) {
        self.client = client
        configureAudioSession()
    }

    /// Synthesize and play coaching text aloud.
    /// If already speaking, stops current playback first.
    /// Voice settings control the emotional tone (excited, supportive, etc.)
    func speak(text: String, voiceSettings: VoiceSettings = .default) async {
        stop()

        // Trim and truncate to avoid hitting API limits
        let cleanText = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(5000))
        guard !cleanText.isEmpty else {
            lastError = "No text to speak"
            return
        }

        isLoading = true
        lastError = nil

        logger.notice("[VoiceCoach] speak() called, text length: \(text.count)")
        logger.notice("[VoiceCoach] isConfigured: \(self.isConfigured)")

        do {
            let audioData = try await client.synthesize(text: cleanText, voiceSettings: voiceSettings)
            logger.notice("[VoiceCoach] got audio data: \(audioData.count) bytes")

            let player = try AVAudioPlayer(data: audioData, fileTypeHint: "mp3")
            player.prepareToPlay()
            logger.notice("[VoiceCoach] player created, duration: \(player.duration)s")

            // Keep a strong reference to both player and delegate
            let delegate = PlaybackDelegate { [weak self] in
                Task { @MainActor in
                    logger.notice("[VoiceCoach] playback finished")
                    self?.isSpeaking = false
                    self?.audioPlayer = nil
                    self?.playerDelegate = nil
                }
            }
            player.delegate = delegate
            self.playerDelegate = delegate
            self.audioPlayer = player

            isLoading = false
            isSpeaking = true
            let success = player.play()
            logger.notice("[VoiceCoach] player.play() returned: \(success)")
        } catch {
            logger.error("[VoiceCoach] ERROR: \(error.localizedDescription)")
            isLoading = false
            isSpeaking = false
            lastError = error.localizedDescription
            print("[VoiceCoach] TTS error: \(error)")
        }
    }

    /// Stop any current playback
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        playerDelegate = nil
        isSpeaking = false
        isLoading = false
    }

    private func configureAudioSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
        } catch {
            // Non-fatal — audio will still work, just might not
            // respect silent mode correctly
        }
        #endif
    }
}

/// Per-instance delegate so each playback has its own completion handler.
/// Avoids the shared singleton problem where a new playback overwrites
/// the previous callback.
private class PlaybackDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}
