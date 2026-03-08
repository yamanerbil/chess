import Foundation
import Observation

/// Response from Claude for a single move explanation
struct MoveExplanation: Codable {
    let explanation: String
    let wasGood: Bool
    let takeaway: String
    let encouragement: String?
}

/// Response from Claude for a full game analysis
struct GameReport: Codable {
    let summary: String
    let keyMoments: [KeyMoment]
    let strengths: [String]
    let homework: String
    let encouragement: String

    struct KeyMoment: Codable {
        let moveNumber: Int
        let title: String
        let explanation: String
        let betterAlternative: String?
    }
}

/// Player profile for age/rating-calibrated coaching
struct PlayerProfile {
    let name: String
    let age: Int
    let rating: Int

    var skillLevel: String {
        switch rating {
        case ..<800: return "beginner"
        case 800..<1200: return "intermediate"
        default: return "advanced"
        }
    }

    /// Default profile for when no profile is configured
    static let `default` = PlayerProfile(name: "Player", age: 10, rating: 1000)
}

/// Orchestrates Claude API calls for chess coaching feedback.
/// Generates kid-friendly, age-calibrated move explanations and game reports.
@Observable
final class ClaudeCoachService {
    private let client: ClaudeAPIClient

    /// Whether a coaching request is in progress
    private(set) var isLoading: Bool = false

    /// Last error from a coaching request
    var lastError: String?

    init(client: ClaudeAPIClient = ClaudeAPIClient()) {
        self.client = client
    }

    /// Whether the Claude API is configured and ready to use
    var isAvailable: Bool {
        get async { await client.isConfigured }
    }

    // MARK: - System Prompt

    private func systemPrompt(for profile: PlayerProfile) -> String {
        """
        You are a friendly, encouraging chess coach for kids. Your student's name \
        is \(profile.name), they are \(profile.age) years old, rated \
        \(profile.rating), and at a \(profile.skillLevel) level.

        RULES FOR YOUR RESPONSES:

        1. LANGUAGE LEVEL:
           - For beginners (under 800): Use simple words. No chess jargon beyond \
        basic piece names. Explain like talking to a smart 7-year-old.
           - For intermediate (800-1200): Can use terms like "pin", "fork", \
        "development", "center control". Explain concepts briefly.
           - For advanced (1200+): Can use full chess vocabulary. Be more \
        analytical but still encouraging.

        2. STRUCTURE (for move explanations):
           - Start with what the player DID (1 sentence)
           - Explain WHY it was good/bad (1-2 sentences)
           - If bad: what they SHOULD have done instead (1 sentence + the move)
           - End with a TAKEAWAY RULE they can remember (1 sentence, memorable)

        3. TONE:
           - Always find something positive first, even in blunders
           - Use encouraging language: "Nice try!", "Almost!", "Great idea but..."
           - Never say "terrible move" or "this is wrong"
           - Use analogies kids relate to (sports, games, everyday life)
           - Keep explanations SHORT — 3-5 sentences max per move

        4. GAME SUMMARIES:
           - Open with the best thing the player did in the game
           - Identify the 2-3 most important moments (turning points)
           - Give exactly ONE homework focus for next game
           - End with encouragement

        5. TECHNICAL CONTEXT (do not reveal to the student):
           You will receive Stockfish evaluation data including centipawn scores \
        and best lines. TRANSLATE these into human concepts. Never mention \
        centipawns, evaluation numbers, or engine lines in your response.
           Instead of "-2.3", say "your opponent has a big advantage here."
           Instead of "Stockfish recommends Bd7", say "moving your bishop to d7 \
        would have been stronger because..."

        6. PATTERN IDENTIFICATION:
           When you notice patterns, frame them as growth opportunities, not criticisms.
        """
    }

    // MARK: - Move Explanation

    /// Generate a coaching explanation for a single move.
    ///
    /// - Parameters:
    ///   - move: The move that was played
    ///   - annotation: The engine's analysis of the move
    ///   - game: The game context
    ///   - moveIndex: Zero-based index of the move
    ///   - profile: The student's profile for calibration
    /// - Returns: Updated annotation with Claude's explanation, or nil on failure
    func explainMove(
        move: ChessMove,
        annotation: MoveAnnotation,
        game: Game,
        moveIndex: Int,
        profile: PlayerProfile = .default
    ) async -> MoveAnnotation? {
        isLoading = true
        defer { isLoading = false }
        lastError = nil

        let phase = gamePhase(moveIndex: moveIndex, totalMoves: game.moves.count)

        let userMessage = """
        POSITION CONTEXT:
        - Move \(move.moveNumber): \(move.san) (\(move.color == .white ? "White" : "Black"))
        - Player is playing \(game.playerColor == .white ? "White" : "Black")
        - Classification: \(annotation.classification.rawValue)
        \(annotation.evalBefore.map { "- Eval before: \($0) pawns" } ?? "")
        - Eval after: \(annotation.evalAfter) pawns
        \(annotation.bestMove.map { "- Best move was: \($0)" } ?? "")

        GAME CONTEXT:
        - Opening: \(game.opening ?? "Unknown")
        - Game phase: \(phase)
        - Move \(move.moveNumber) of \(game.moves.count / 2)
        - Result: \(game.result.rawValue)
        \(!annotation.engineLines.isEmpty ? "- Engine continuation: \(annotation.engineLines.joined(separator: " "))" : "")

        Explain this move to the student. Follow your coaching rules.
        Respond ONLY with valid JSON (no markdown, no code fences):
        {
            "explanation": "your 3-5 sentence explanation",
            "wasGood": true or false,
            "takeaway": "one memorable rule or tip",
            "encouragement": "short positive note (include even if move was good)"
        }
        """

        let cacheKey = "\(game.id):\(moveIndex)"

        do {
            let response = try await client.sendMessage(
                system: systemPrompt(for: profile),
                userMessage: userMessage,
                maxTokens: 400,
                cacheKey: cacheKey
            )

            let moveExplanation = try parseJSON(MoveExplanation.self, from: response)

            // Combine Claude's explanation with the takeaway
            var fullExplanation = moveExplanation.explanation
            if !moveExplanation.takeaway.isEmpty {
                fullExplanation += " \(moveExplanation.takeaway)"
            }

            return MoveAnnotation(
                id: annotation.id,
                classification: annotation.classification,
                explanation: fullExplanation,
                bestMove: annotation.bestMove,
                evalBefore: annotation.evalBefore,
                evalAfter: annotation.evalAfter,
                engineLines: annotation.engineLines
            )
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    // MARK: - Full Game Report

    /// Generate a full game coaching report.
    ///
    /// - Parameters:
    ///   - game: The analyzed game (must have annotations)
    ///   - profile: The student's profile for calibration
    /// - Returns: A GameReport with summary, key moments, and homework
    func analyzeFullGame(
        game: Game,
        profile: PlayerProfile = .default
    ) async -> GameReport? {
        isLoading = true
        defer { isLoading = false }
        lastError = nil

        let annotations = game.annotations

        // Build move-by-move summary for Claude
        let moveSummaries = game.moves.enumerated().map { index, move in
            let ann = annotations[index]
            let classLabel = ann?.classification.rawValue ?? "unknown"
            let eval = ann.map { String(format: "%.1f", $0.evalAfter) } ?? "?"
            return "Move \(move.moveNumber)\(move.color == .white ? "." : "...")\(move.san): \(eval) pawns (\(classLabel))"
        }.joined(separator: "\n")

        // Key moments — significant eval swings
        let keyMomentSummaries = annotations
            .filter { $0.value.isKeyMoment }
            .sorted { $0.key < $1.key }
            .prefix(5)
            .map { index, ann in
                let move = game.moves[index]
                return "Move \(move.moveNumber)\(move.color == .white ? "." : "...")\(move.san) — \(ann.classification.rawValue). Best was \(ann.bestMove ?? "unknown")."
            }
            .joined(separator: "\n")

        let userMessage = """
        GAME OVERVIEW:
        \(game.white) vs \(game.black)
        Result: \(game.result.rawValue)
        Opening: \(game.opening ?? "Unknown")
        Player was: \(game.playerColor == .white ? "White" : "Black")

        MOVE-BY-MOVE ANALYSIS:
        \(moveSummaries)

        KEY MOMENTS:
        \(keyMomentSummaries.isEmpty ? "No major turning points" : keyMomentSummaries)

        Generate a complete game review for the student. Follow your coaching rules.
        Respond ONLY with valid JSON (no markdown, no code fences):
        {
            "summary": "2-3 sentence overview, lead with something positive",
            "keyMoments": [
                {
                    "moveNumber": 14,
                    "title": "short title",
                    "explanation": "what happened and why",
                    "betterAlternative": "what they should have played (or null)"
                }
            ],
            "strengths": ["things the player did well"],
            "homework": "ONE specific thing to focus on in next game",
            "encouragement": "motivational closing message"
        }
        """

        let cacheKey = "report:\(game.id)"

        do {
            let response = try await client.sendMessage(
                system: systemPrompt(for: profile),
                userMessage: userMessage,
                maxTokens: 1000,
                cacheKey: cacheKey
            )

            return try parseJSON(GameReport.self, from: response)
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    // MARK: - Helpers

    /// Determine game phase from move index
    private func gamePhase(moveIndex: Int, totalMoves: Int) -> String {
        let fullMoveNumber = moveIndex / 2 + 1
        if fullMoveNumber <= 10 { return "opening" }
        if fullMoveNumber <= 25 || moveIndex < totalMoves - 10 { return "middlegame" }
        return "endgame"
    }

    /// Parse JSON from Claude's response, handling common formatting issues
    private func parseJSON<T: Decodable>(_ type: T.Type, from text: String) throws -> T {
        // Strip markdown code fences if Claude included them despite instructions
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw ClaudeAPIError.decodingFailed("Response is not valid UTF-8")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            throw ClaudeAPIError.decodingFailed(error.localizedDescription)
        }
    }
}
