import Foundation

/// Lightweight client for the Anthropic Messages API.
/// Uses raw URLSession — no external SDK needed for iOS/Swift.
actor ClaudeAPIClient {
    private let apiKey: String
    private let model: String
    private let baseURL: URL
    private let session: URLSession

    /// Cache of move explanations keyed by "\(gameId):\(moveIndex)"
    private var cache: [String: Data] = [:]

    init(
        apiKey: String? = nil,
        model: String = "claude-haiku-4-5",
        baseURL: URL = URL(string: "https://api.anthropic.com")!
    ) {
        self.apiKey = apiKey
            ?? ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
            ?? ""
        self.model = model
        self.baseURL = baseURL

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    /// Whether the client has a valid API key configured
    var isConfigured: Bool { !apiKey.isEmpty }

    // MARK: - Public API

    /// Send a message to Claude and return the text response.
    func sendMessage(
        system: String,
        userMessage: String,
        maxTokens: Int = 512,
        cacheKey: String? = nil
    ) async throws -> String {
        // Check cache first
        if let key = cacheKey, let cached = cache[key] {
            return String(data: cached, encoding: .utf8) ?? ""
        }

        guard isConfigured else {
            throw ClaudeAPIError.notConfigured
        }

        let url = baseURL.appendingPathComponent("/v1/messages")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": system,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ClaudeAPIError.httpError(statusCode: httpResponse.statusCode, body: errorBody)
        }

        // Parse the Messages API response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            throw ClaudeAPIError.unexpectedFormat
        }

        // Cache the response
        if let key = cacheKey {
            cache[key] = text.data(using: .utf8)
        }

        return text
    }

    /// Clear all cached responses
    func clearCache() {
        cache.removeAll()
    }
}

// MARK: - Errors

enum ClaudeAPIError: LocalizedError {
    case notConfigured
    case invalidResponse
    case httpError(statusCode: Int, body: String)
    case unexpectedFormat
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Claude API key not configured. Set ANTHROPIC_API_KEY in your environment or app settings."
        case .invalidResponse:
            return "Invalid response from Claude API."
        case .httpError(let code, let body):
            switch code {
            case 401: return "Invalid API key. Check your Anthropic API key."
            case 429: return "Rate limited. Try again in a moment."
            case 500...599: return "Claude API is temporarily unavailable. Try again later."
            default: return "Claude API error (\(code)): \(body)"
            }
        case .unexpectedFormat:
            return "Unexpected response format from Claude API."
        case .decodingFailed(let detail):
            return "Failed to parse coaching response: \(detail)"
        }
    }
}
