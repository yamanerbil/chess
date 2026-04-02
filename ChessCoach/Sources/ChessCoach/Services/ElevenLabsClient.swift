import Foundation

/// Voice settings for ElevenLabs TTS — controls emotional tone
struct VoiceSettings {
    var stability: Double
    var similarityBoost: Double
    var style: Double
    var useSpeakerBoost: Bool

    /// Neutral default — tuned for natural, human-like delivery
    static let `default` = VoiceSettings(stability: 0.35, similarityBoost: 0.80, style: 0.45, useSpeakerBoost: true)

    // MARK: - Move-level presets

    /// Excited and expressive — for brilliant/great moves
    static let celebratory = VoiceSettings(stability: 0.20, similarityBoost: 0.85, style: 0.90, useSpeakerBoost: true)
    /// Warm and affirming — for good/solid moves
    static let encouraging = VoiceSettings(stability: 0.35, similarityBoost: 0.80, style: 0.55, useSpeakerBoost: true)
    /// Gentle and supportive — for inaccuracies/mistakes
    static let supportive = VoiceSettings(stability: 0.50, similarityBoost: 0.70, style: 0.35, useSpeakerBoost: true)
    /// Calm and reassuring — for blunders (don't pile on)
    static let reassuring = VoiceSettings(stability: 0.60, similarityBoost: 0.65, style: 0.20, useSpeakerBoost: true)

    /// Pick voice settings based on move classification
    static func forClassification(_ classification: MoveClassification) -> VoiceSettings {
        switch classification {
        case .brilliant, .great: return .celebratory
        case .good: return .encouraging
        case .inaccuracy, .mistake: return .supportive
        case .blunder: return .reassuring
        }
    }

    /// Shift settings based on game outcome — winners get a brighter tone, losses get warmer support
    func adjustedForOutcome(playerWon: Bool, playerLost: Bool) -> VoiceSettings {
        var adjusted = self
        if playerWon {
            // More expressive and upbeat for winners
            adjusted.style = min(1.0, adjusted.style + 0.15)
            adjusted.stability = max(0.0, adjusted.stability - 0.1)
        } else if playerLost {
            // Warmer, steadier, more encouraging after a loss
            adjusted.stability = min(1.0, adjusted.stability + 0.15)
            adjusted.style = max(0.0, adjusted.style - 0.1)
        }
        return adjusted
    }

    var asDictionary: [String: Any] {
        [
            "stability": stability,
            "similarity_boost": similarityBoost,
            "style": style,
            "use_speaker_boost": useSpeakerBoost
        ]
    }
}

/// Lightweight client for the ElevenLabs Text-to-Speech API.
/// Returns MP3 audio data for a given text string.
actor ElevenLabsClient {
    private let apiKey: String
    private let voiceId: String
    private let model: String
    private let baseURL: URL
    private let session: URLSession

    /// In-memory cache of synthesized audio keyed by text hash
    private var cache: [String: Data] = [:]

    init(
        apiKey: String? = nil,
        voiceId: String? = nil,
        model: String = "eleven_flash_v2_5"
    ) {
        self.apiKey = apiKey
            ?? ProcessInfo.processInfo.environment["ELEVENLABS_API_KEY"]
            ?? ""
        self.voiceId = voiceId
            ?? ProcessInfo.processInfo.environment["ELEVENLABS_VOICE_ID"]
            ?? "EXAVITQu4vr4xnSDxMaL" // Default: "Matilda" — warm, friendly voice
        self.model = model
        self.baseURL = URL(string: "https://api.elevenlabs.io")!

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    /// Whether the client has a valid API key configured
    var isConfigured: Bool { !apiKey.isEmpty }

    // MARK: - Public API

    /// Synthesize text to speech and return MP3 audio data.
    /// Results are cached in memory to avoid redundant API calls.
    func synthesize(text: String, voiceSettings: VoiceSettings = .default) async throws -> Data {
        // Check cache first (include settings in key so different tones aren't mixed up)
        let cacheKey = "\(text)|\(voiceSettings.stability)|\(voiceSettings.style)"
        if let cached = cache[cacheKey] {
            return cached
        }

        guard isConfigured else {
            throw ElevenLabsError.notConfigured
        }

        let url = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("text-to-speech")
            .appendingPathComponent(voiceId)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")

        let body: [String: Any] = [
            "text": text,
            "model_id": model,
            "voice_settings": voiceSettings.asDictionary
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("[ElevenLabs] POST \(url.absoluteString) (\(text.count) chars)")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ElevenLabsError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[ElevenLabs] Error \(httpResponse.statusCode): \(errorBody.prefix(200))")
            throw ElevenLabsError.httpError(statusCode: httpResponse.statusCode, body: errorBody)
        }

        print("[ElevenLabs] Success: \(data.count) bytes")

        // Cache the result
        cache[cacheKey] = data

        return data
    }

    /// Clear the audio cache
    func clearCache() {
        cache.removeAll()
    }
}

// MARK: - Errors

enum ElevenLabsError: LocalizedError {
    case notConfigured
    case invalidResponse
    case httpError(statusCode: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "ElevenLabs API key not configured. Set ELEVENLABS_API_KEY in your environment."
        case .invalidResponse:
            return "Invalid response from ElevenLabs API."
        case .httpError(let statusCode, let body):
            return "ElevenLabs API error (\(statusCode)): \(body)"
        }
    }
}
