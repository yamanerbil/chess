import Foundation
import AVFoundation
import Observation

/// Service that synthesizes coaching text to speech via ElevenLabs
/// and plays it back using AVAudioPlayer.
@Observable
final class VoiceCoachService {
    private let client: ElevenLabsClient
    private var audioPlayer: AVAudioPlayer?

    /// Whether audio is currently playing
    private(set) var isSpeaking: Bool = false

    /// Whether the service is fetching audio from the API
    private(set) var isLoading: Bool = false

    /// Last error message
    private(set) var lastError: String?

    /// Whether the ElevenLabs API is configured (has API key)
    var isConfigured: Bool {
        // We need to check this synchronously for UI binding,
        // so we check the env var directly
        let key = ProcessInfo.processInfo.environment["ELEVENLABS_API_KEY"] ?? ""
        return !key.isEmpty
    }

    init(client: ElevenLabsClient = ElevenLabsClient()) {
        self.client = client
        configureAudioSession()
    }

    /// Synthesize and play coaching text aloud.
    /// If already speaking, stops current playback first.
    func speak(text: String) async {
        stop()

        // Trim and truncate to avoid hitting API limits
        let cleanText = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(5000))
        guard !cleanText.isEmpty else {
            lastError = "No text to speak"
            return
        }

        isLoading = true
        lastError = nil

        do {
            let audioData = try await client.synthesize(text: cleanText)
            isLoading = false

            // Play the MP3 data
            let player = try AVAudioPlayer(data: audioData)
            self.audioPlayer = player
            player.delegate = AudioPlayerDelegate.shared
            AudioPlayerDelegate.shared.onFinish = { [weak self] in
                self?.isSpeaking = false
            }

            isSpeaking = true
            player.play()
        } catch {
            isLoading = false
            lastError = error.localizedDescription
            print("[VoiceCoach] TTS error: \(error)")
        }
    }

    /// Stop any current playback
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
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

/// Helper delegate to detect when audio playback finishes.
/// Uses a shared instance since AVAudioPlayerDelegate requires NSObject.
private class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioPlayerDelegate()
    var onFinish: (() -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.onFinish?()
        }
    }
}
