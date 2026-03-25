import Foundation

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
    func synthesize(text: String) async throws -> Data {
        // Check cache first
        let cacheKey = text
        if let cached = cache[cacheKey] {
            return cached
        }

        guard isConfigured else {
            throw ElevenLabsError.notConfigured
        }

        let url = baseURL
            .appendingPathComponent("/v1/text-to-speech/\(voiceId)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")

        let body: [String: Any] = [
            "text": text,
            "model_id": model,
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75,
                "style": 0.3,
                "use_speaker_boost": true
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ElevenLabsError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ElevenLabsError.httpError(statusCode: httpResponse.statusCode, body: errorBody)
        }

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
