# Chess Coach App — Technical Specification for Claude Code

## Project Overview

Build an iOS app (Swift/SwiftUI) that helps kids in chess tournaments:
1. Record game notation (manual input or photo scan of scoresheet)
2. Replay games move-by-move on an interactive board
3. Get AI-powered coaching feedback — natural language explanations, not raw engine lines

The core differentiator: Stockfish provides positional truth, an LLM translates it into age-appropriate coaching.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Swift / SwiftUI (iOS 17+) |
| Chess Engine | Stockfish (via C++ bridge or `ChessKit` Swift package) |
| Chess Logic | `chess` Swift package for PGN parsing, move validation, board state |
| AI Coaching | Anthropic Claude API (claude-sonnet-4-5-20250929) |
| OCR / Scoresheet Scan | Apple Vision framework (VNRecognizeTextRequest) |
| Local Storage | SwiftData (game history, player profile) |
| Backend (optional) | None initially — all on-device + direct API calls |

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│                   SwiftUI Frontend               │
│  ┌───────────┐  ┌──────────┐  ┌──────────────┐  │
│  │ Game Input │  │ Replay   │  │ AI Coach     │  │
│  │ Screen     │  │ Board    │  │ Chat Panel   │  │
│  └─────┬─────┘  └────┬─────┘  └──────┬───────┘  │
│        │              │               │          │
│  ┌─────▼──────────────▼───────────────▼───────┐  │
│  │           GameAnalysisService               │  │
│  │  (Orchestrator — the core of the app)       │  │
│  └──────┬─────────────┬───────────────┬───────┘  │
│         │             │               │          │
│  ┌──────▼──────┐ ┌────▼─────┐ ┌───────▼───────┐ │
│  │ StockfishBridge │ │ PGNParser │ │ ClaudeService│ │
│  │ (C++ engine)    │ │ (chess pkg)│ │ (API client) │ │
│  └─────────────┘ └──────────┘ └───────────────┘ │
│                                                  │
│  ┌──────────────────────────────────────────┐    │
│  │ SwiftData: GameStore / PlayerProfile     │    │
│  └──────────────────────────────────────────┘    │
└─────────────────────────────────────────────────┘
```

---

## Data Models

### Game
```swift
@Model
class Game {
    var id: UUID
    var pgn: String                    // Full PGN string
    var playerWhite: String
    var playerBlack: String
    var playerColor: PieceColor        // Which side is the kid
    var result: GameResult             // win/loss/draw
    var tournamentName: String?
    var roundNumber: Int?
    var date: Date
    var moves: [AnnotatedMove]         // Parsed moves with analysis
    var overallAnalysis: String?       // AI-generated game summary
    var playerRating: Int?             // Kid's rating at time of game
    var opponentRating: Int?
    var createdAt: Date
}

enum GameResult: String, Codable {
    case whiteWins = "1-0"
    case blackWins = "0-1"
    case draw = "1/2-1/2"
    case unknown = "*"
}
```

### AnnotatedMove
```swift
struct AnnotatedMove: Codable {
    var moveNumber: Int
    var whiteMove: String              // SAN notation e.g. "Nf3"
    var blackMove: String?
    var fen: String                    // Board position after this move
    var evalBefore: Double?            // Stockfish eval before move (centipawns)
    var evalAfter: Double?             // Stockfish eval after move
    var bestMove: String?              // Stockfish's recommended move
    var classification: MoveClassification
    var aiExplanation: String?         // Claude's natural language explanation
    var isKeyMoment: Bool              // Flagged for review
}

enum MoveClassification: String, Codable {
    case brilliant    // Eval gain > 100cp, only move or sacrifice
    case great        // Best or near-best move
    case good         // Within 30cp of best
    case inaccuracy   // 30-100cp loss
    case mistake      // 100-300cp loss
    case blunder      // > 300cp loss
}
```

### PlayerProfile
```swift
@Model
class PlayerProfile {
    var name: String
    var rating: Int
    var age: Int                       // Used to calibrate AI explanation depth
    var skillLevel: SkillLevel         // beginner/intermediate/advanced
    var commonMistakePatterns: [String] // AI-identified recurring issues
    var gamesPlayed: Int
    var favoriteOpenings: [String]     // Auto-detected from game history
}

enum SkillLevel: String, Codable {
    case beginner     // Under 600
    case elementary   // 600-1000
    case intermediate // 1000-1400
    case advanced     // 1400+
}
```

---

## Core Services — Implementation Details

### 1. PGN Parser Service

Use the `swift-chess` or `ChessKit` package. Parse PGN into individual moves with FEN positions.

```swift
class PGNParserService {
    /// Parse a PGN string into an array of moves with board positions
    func parse(pgn: String) -> [ParsedMove]
    
    /// Validate that a PGN is well-formed and all moves are legal
    func validate(pgn: String) -> Result<Bool, PGNError>
    
    /// Convert manual move entry to PGN
    func buildPGN(from moves: [(white: String, black: String?)],
                  metadata: GameMetadata) -> String
}
```

### 2. Stockfish Bridge

Embed Stockfish as a C++ library. Communicate via UCI protocol.

```swift
class StockfishBridge {
    /// Evaluate a position. Returns centipawn score from white's perspective.
    /// Use depth 18 for analysis (good balance of speed vs accuracy on mobile)
    func evaluate(fen: String, depth: Int = 18) async -> StockfishResult
    
    /// Get the best move for a position
    func bestMove(fen: String, depth: Int = 18) async -> String
    
    /// Analyze an entire game — returns eval for every position
    func analyzeGame(moves: [ParsedMove]) async -> [PositionEval]
}

struct StockfishResult {
    var score: Double          // Centipawns (positive = white advantage)
    var bestLine: [String]     // Principal variation (best continuation)
    var mate: Int?             // Mate in N moves (nil if no forced mate)
}
```

### 3. Claude AI Coaching Service (THE DIFFERENTIATOR)

This is the most important service. It takes Stockfish's raw analysis and produces kid-friendly coaching.

```swift
class ClaudeCoachService {
    private let apiKey: String
    private let model = "claude-sonnet-4-5-20250929"
    
    // MARK: - Core Analysis Methods
    
    /// Analyze a single move — called when kid taps a move during replay
    func explainMove(
        move: AnnotatedMove,
        context: GameContext,
        playerProfile: PlayerProfile
    ) async -> MoveExplanation
    
    /// Generate full game summary with key lessons
    func analyzeFullGame(
        game: Game,
        stockfishAnalysis: [PositionEval],
        playerProfile: PlayerProfile
    ) async -> GameAnalysis
    
    /// Answer a kid's freeform question about a position
    func answerQuestion(
        question: String,
        position: AnnotatedMove,
        gameContext: GameContext,
        playerProfile: PlayerProfile
    ) async -> String
    
    /// Identify patterns across multiple games
    func identifyPatterns(
        recentGames: [Game],
        playerProfile: PlayerProfile
    ) async -> [PatternInsight]
}
```

#### System Prompt for Claude (CRITICAL — this is the product's voice)

```swift
let coachSystemPrompt = """
You are a friendly, encouraging chess coach for kids. Your student's name 
is \(profile.name), they are \(profile.age) years old, rated 
\(profile.rating), and at a \(profile.skillLevel.rawValue) level.

RULES FOR YOUR RESPONSES:

1. LANGUAGE LEVEL: 
   - For beginners (under 800): Use simple words. No chess jargon beyond 
     basic piece names. Explain like talking to a smart 7-year-old.
   - For intermediate (800-1200): Can use terms like "pin", "fork", 
     "development", "center control". Explain concepts briefly.
   - For advanced (1200+): Can use full chess vocabulary. Be more 
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
   
5. TECHNICAL CONTEXT (do not show this to the kid):
   You will receive Stockfish evaluation data including centipawn scores 
   and best lines. TRANSLATE these into human concepts. Never mention 
   centipawns, evaluation numbers, or engine lines in your response.
   Instead of "-2.3", say "your opponent has a big advantage here."
   Instead of "Stockfish recommends Bd7", say "moving your bishop to d7 
   would have been stronger because..."

6. PATTERN IDENTIFICATION:
   When analyzing multiple games, look for:
   - Recurring tactical misses (forks, pins, skewers)
   - Opening mistakes (early queen moves, not developing, not castling)
   - Endgame patterns (king activity, pawn promotion awareness)
   - Time management issues (if move timestamps available)
   Frame patterns as growth opportunities, not criticisms.
"""
```

#### Claude API Call Structure

```swift
func explainMove(move: AnnotatedMove, context: GameContext, 
                 playerProfile: PlayerProfile) async -> MoveExplanation {
    
    let userMessage = """
    POSITION CONTEXT:
    - Move \(move.moveNumber): \(move.whiteMove) \(move.blackMove ?? "")
    - FEN: \(move.fen)
    - Player is playing \(context.playerColor)
    - Eval before move: \(move.evalBefore ?? 0) centipawns
    - Eval after move: \(move.evalAfter ?? 0) centipawns
    - Eval change: \((move.evalAfter ?? 0) - (move.evalBefore ?? 0)) centipawns
    - Best move was: \(move.bestMove ?? "N/A")
    - Classification: \(move.classification.rawValue)
    
    GAME CONTEXT:
    - Opening played: \(context.opening ?? "Unknown")
    - Game phase: \(context.phase) (opening/middlegame/endgame)
    - Material balance: \(context.materialBalance)
    - Move \(move.moveNumber) of \(context.totalMoves)
    
    Explain this move to the student. Follow your coaching rules.
    Respond in JSON format:
    {
        "explanation": "your 3-5 sentence explanation",
        "wasGood": true/false,
        "takeaway": "one memorable rule or tip",
        "encouragement": "short positive note (only if move was bad)"
    }
    """
    
    // Make API call to Claude
    let response = try await anthropicClient.message(
        model: model,
        system: coachSystemPrompt,
        messages: [.user(userMessage)],
        maxTokens: 300
    )
    
    // Parse JSON response into MoveExplanation
    return try JSONDecoder().decode(MoveExplanation.self, from: response)
}
```

#### Full Game Analysis Prompt

```swift
func analyzeFullGame(game: Game, stockfishAnalysis: [PositionEval],
                     playerProfile: PlayerProfile) async -> GameAnalysis {
    
    let userMessage = """
    FULL GAME PGN:
    \(game.pgn)
    
    STOCKFISH ANALYSIS (move: eval_change, classification):
    \(stockfishAnalysis.map { 
        "Move \($0.moveNumber): \($0.evalChange)cp (\($0.classification))" 
    }.joined(separator: "\n"))
    
    KEY MOMENTS (moves with eval swing > 100cp):
    \(stockfishAnalysis.filter { abs($0.evalChange) > 100 }.map {
        "Move \($0.moveNumber): \($0.san) — eval went from \($0.evalBefore) to \($0.evalAfter). Best was \($0.bestMove)"
    }.joined(separator: "\n"))
    
    PLAYER INFO:
    - Playing as: \(game.playerColor)
    - Result: \(game.result.rawValue)
    - Rating: \(playerProfile.rating)
    - Known patterns to watch for: \(playerProfile.commonMistakePatterns.joined(separator: ", "))
    
    Generate a complete game review. Respond in JSON:
    {
        "summary": "2-3 sentence game overview, lead with something positive",
        "keyMoments": [
            {
                "moveNumber": 14,
                "title": "The Turning Point",
                "explanation": "explanation here",
                "betterAlternative": "what they should have played"
            }
        ],
        "strengths": ["things the player did well"],
        "homework": "ONE specific thing to focus on in next game",
        "encouragement": "motivational closing message",
        "patternUpdate": "any new recurring pattern detected (null if none)"
    }
    """
    
    let response = try await anthropicClient.message(
        model: model,
        system: coachSystemPrompt,
        messages: [.user(userMessage)],
        maxTokens: 1000
    )
    
    return try JSONDecoder().decode(GameAnalysis.self, from: response)
}
```

### 4. Scoresheet OCR Service

Use Apple Vision framework to scan handwritten notation sheets.

```swift
class ScoresheetScannerService {
    /// Scan a photo of a scoresheet and extract moves
    func scanScoresheet(image: UIImage) async -> ScanResult
    
    /// Post-process OCR text into valid algebraic notation
    /// Handle common kid handwriting issues:
    ///   - "0-0" vs "O-O" (castling)
    ///   - Ambiguous characters: 1/l, 0/O, 5/S, B/8
    ///   - Missing piece identifiers (kids often write "e4" not "1.e4")
    func postProcessOCR(rawText: String) -> [String]
    
    /// Validate extracted moves against legal chess moves
    /// Return moves with confidence scores and flag uncertain ones for manual review
    func validateMoves(extractedMoves: [String]) -> [ValidatedMove]
}

struct ScanResult {
    var moves: [ValidatedMove]
    var confidence: Double           // Overall scan confidence
    var needsReview: [Int]           // Move numbers that need manual verification
    var rawOCRText: String           // For debugging
}

struct ValidatedMove {
    var moveNumber: Int
    var notation: String
    var confidence: Double           // 0.0 - 1.0
    var alternatives: [String]       // Other possible readings of the handwriting
    var isValid: Bool                // Does this move make legal sense on the board?
}
```

**Implementation approach for OCR:**
```swift
func scanScoresheet(image: UIImage) async -> ScanResult {
    guard let cgImage = image.cgImage else { throw ScanError.invalidImage }
    
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["en-US"]
    request.usesLanguageCorrection = false  // Chess notation isn't natural language
    
    // Custom word list for chess notation to improve accuracy
    request.customWords = [
        "Nf3", "Nc3", "Bc4", "Bb5", "Qd1", "Ke1",
        "O-O", "O-O-O",  // Castling
        "e4", "d4", "c4", "Nf6", "e5", "d5",  // Common moves
        // Add more common notation patterns
    ]
    
    let handler = VNImageRequestHandler(cgImage: cgImage)
    try handler.perform([request])
    
    // Process VNRecognizedText observations
    // Group into columns (white moves / black moves)
    // Parse move numbers and notation
    // Run through move validator
}
```

---

## Screen Flow & UI

### Screen 1: Home / Game List
```
┌─────────────────────────┐
│  ♟ ChessCoach           │
│  Hi [Name]! 👋          │
│                         │
│  ┌─────────────────┐    │
│  │ + New Game       │    │
│  └─────────────────┘    │
│                         │
│  Recent Games           │
│  ┌─────────────────┐    │
│  │ vs. Alex (W) ✓  │    │
│  │ Feb 22 · R3     │    │
│  │ ⭐ 2 key moments │    │
│  └─────────────────┘    │
│  ┌─────────────────┐    │
│  │ vs. Sarah (L) ✗ │    │
│  │ Feb 22 · R2     │    │
│  └─────────────────┘    │
│                         │
│  📊 My Progress         │
│  "Focus on: Check for   │
│   hanging pieces!"      │
│                         │
│  [Home] [Games] [Me]    │
└─────────────────────────┘
```

### Screen 2: Game Input (Two Modes)

**Mode A: Manual Entry**
- Interactive chessboard — tap piece, tap destination square
- Move list builds on the side
- Undo button
- Supports drag-and-drop for older kids

**Mode B: Scan Scoresheet**  
- Camera view with guide overlay showing scoresheet alignment
- After scan: show extracted moves with confidence highlighting
- Yellow = uncertain (tap to correct)
- Red = invalid move (must fix)
- Green = confident and valid

### Screen 3: Game Replay (THE MAIN EXPERIENCE)
```
┌─────────────────────────┐
│  vs. Alex · Round 3     │
│                         │
│  ┌─────────────────┐    │
│  │                 │    │
│  │   Chess Board   │    │
│  │   (interactive) │    │
│  │                 │    │
│  └─────────────────┘    │
│                         │
│  ◀ Move 14. Nxd4 ▶     │
│  ■■■■■■■□□□□□ (14/32)  │
│                         │
│  ┌─────────────────┐    │
│  │ 🟡 Inaccuracy   │    │
│  │                 │    │
│  │ "You captured   │    │
│  │  the knight, but│    │
│  │  Bd7 was better │    │
│  │  because..."    │    │
│  │                 │    │
│  │ 💡 Tip: Before  │    │
│  │ capturing, ask  │    │
│  │ "what can my    │    │
│  │ opponent do     │    │
│  │ next?"          │    │
│  └─────────────────┘    │
│                         │
│  [Ask Coach 💬]         │
│                         │
└─────────────────────────┘
```

Color coding for moves:
- 🟢 Green border = good/great move
- 🟡 Yellow border = inaccuracy  
- 🔴 Red border = mistake/blunder
- ⭐ Star = key moment (biggest eval swings)

### Screen 4: AI Chat (Ask Coach)
```
┌─────────────────────────┐
│  💬 Ask Coach           │
│  Position: Move 14      │
│                         │
│  ┌─ You ────────────┐   │
│  │ Why was my move  │   │
│  │ bad?             │   │
│  └──────────────────┘   │
│                         │
│  ┌─ Coach ──────────┐   │
│  │ Good question!   │   │
│  │ Your knight      │   │
│  │ capture looked   │   │
│  │ tempting but...  │   │
│  └──────────────────┘   │
│                         │
│  Suggested questions:   │
│  [What should I do?]    │
│  [What was the plan?]   │
│  [Show me the trick]    │
│                         │
│  ┌──────────────┐ [Send]│
│  │ Type question │       │
│  └──────────────┘       │
└─────────────────────────┘
```

### Screen 5: Game Summary
```
┌─────────────────────────┐
│  📋 Game Review         │
│                         │
│  "Great fighting game!  │
│   You played a solid    │
│   opening and found a   │
│   nice tactic on move   │
│   8!"                   │
│                         │
│  ⭐ Key Moments (tap    │
│     to replay)          │
│  ┌─────────────────┐    │
│  │ Move 8: Your    │    │
│  │ fork! ✓         │    │
│  └─────────────────┘    │
│  ┌─────────────────┐    │
│  │ Move 14: The    │    │
│  │ turning point ✗ │    │
│  └─────────────────┘    │
│                         │
│  📝 Homework:           │
│  "Before capturing,     │
│   count attackers and   │
│   defenders!"           │
│                         │
│  [Share with Coach 📤]  │
│  [Replay Game ▶]        │
└─────────────────────────┘
```

---

## Implementation Order (for Claude Code)

Build in this sequence — each phase is independently testable:

### Phase 1: Chess Board & PGN (Week 1)
1. Set up SwiftUI project with basic navigation
2. Build interactive chessboard view (pieces, legal move highlighting)
3. Integrate chess logic package for move validation
4. Build PGN parser — input a PGN string, get board positions
5. Build move-by-move replay with forward/back controls
6. Test with sample PGN games

### Phase 2: Stockfish Integration (Week 2)  
1. Embed Stockfish binary via C++ bridge (SPM package if available)
2. Implement UCI protocol communication
3. Build position evaluation (single position → eval score)
4. Build full game analysis (iterate all positions, classify moves)
5. Add eval bar visualization to replay board
6. Test: analyze a known game, verify classifications match expectations

### Phase 3: AI Coaching Layer (Week 3)
1. Set up Anthropic API client (simple HTTP, no SDK needed)
2. Implement the system prompt and move explanation prompt
3. Build the coaching card UI that appears below the board during replay
4. Wire up: tap a move → show Stockfish eval + Claude explanation
5. Build full game summary generation
6. Add the "Ask Coach" chat interface
7. Test: replay a kid's game, verify explanations are age-appropriate

### Phase 4: Game Input (Week 4)
1. Build manual move entry (tap-to-move on board)
2. Build scoresheet camera scanner (Apple Vision OCR)
3. Build post-scan review/correction UI
4. Wire scan → PGN → analysis pipeline
5. Test with real kid scoresheets (messy handwriting!)

### Phase 5: Player Profile & Patterns (Week 5)
1. SwiftData models for game history and player profile
2. Auto-detect openings played
3. Cross-game pattern analysis (Claude batch analysis)
4. Progress tracking (accuracy %, blunder rate over time)
5. "Homework" feature that persists between sessions

### Phase 6: Polish (Week 6)
1. Onboarding flow (name, age, rating)
2. Animations and transitions
3. Share game analysis with coach (export PDF or link)
4. App Store assets and submission

---

## API Cost Estimates

Per game analyzed (assuming ~40 moves):
- Stockfish: Free (on-device)
- Claude move explanations (only for inaccuracies/mistakes/blunders, ~8-12 per game):
  - Input: ~500 tokens × 10 moves = 5,000 tokens
  - Output: ~150 tokens × 10 moves = 1,500 tokens
  - Cost: ~$0.02 per game
- Claude game summary: ~$0.01 per game
- Claude chat Q&A: ~$0.005 per question

**Total per game: ~$0.03-0.05**
**Monthly cost per active user (4 tournament games/month + some chat): ~$0.20-0.50**

This is very sustainable at a $4.99-9.99/month subscription price point.

---

## Key Technical Decisions

1. **On-device Stockfish, cloud Claude** — Stockfish runs fast on-device with no latency. Claude needs cloud but only for the coaching layer. This means the board replay works offline; AI explanations load when connected.

2. **Lazy AI analysis** — Don't analyze all 40 moves with Claude upfront. Only call Claude when:
   - The kid navigates to that specific move during replay
   - The move is classified as inaccuracy/mistake/blunder
   - The kid asks a question
   This keeps API costs low and response times fast.

3. **Cache Claude responses** — Once a move is explained, cache it in SwiftData. Never re-analyze the same position for the same game.

4. **Pre-generate game summary** — When a game is first imported, run Stockfish on all positions (takes ~10-30 seconds), then call Claude once for the full game summary. Individual move explanations are generated on-demand.

5. **No engine lines shown to kids** — The board should show the "best move" as an arrow overlay (like Chess.com) but never show the full principal variation. Kids can't process "Bd7 Nxe5 Qf6 Rfe1 Bxe5 Rxe5 Qd6" — that's not coaching.

---

## File Structure

```
ChessCoach/
├── App/
│   ├── ChessCoachApp.swift
│   └── ContentView.swift
├── Models/
│   ├── Game.swift
│   ├── AnnotatedMove.swift
│   ├── PlayerProfile.swift
│   └── GameAnalysis.swift
├── Services/
│   ├── PGNParserService.swift
│   ├── StockfishBridge.swift
│   ├── ClaudeCoachService.swift
│   ├── ScoresheetScannerService.swift
│   └── GameAnalysisService.swift      // Orchestrator
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── GameListRow.swift
│   ├── GameInput/
│   │   ├── ManualEntryView.swift
│   │   ├── ScoresheetScanView.swift
│   │   └── ScanReviewView.swift
│   ├── Replay/
│   │   ├── GameReplayView.swift
│   │   ├── ChessBoardView.swift
│   │   ├── MoveListView.swift
│   │   └── CoachingCardView.swift
│   ├── Coach/
│   │   ├── AskCoachView.swift
│   │   └── ChatBubbleView.swift
│   ├── Summary/
│   │   └── GameSummaryView.swift
│   └── Profile/
│       ├── PlayerProfileView.swift
│       └── ProgressView.swift
├── Components/
│   ├── ChessPiece.swift
│   ├── EvalBar.swift
│   └── MoveClassificationBadge.swift
├── Stockfish/
│   ├── StockfishWrapper.mm            // Obj-C++ bridge
│   ├── StockfishWrapper.h
│   └── stockfish/                     // C++ source
└── Resources/
    ├── Assets.xcassets
    └── piece-images/
```

---

## Testing Checklist

Before shipping, verify:
- [ ] PGN parser handles castling (O-O, O-O-O), en passant, promotion (e8=Q)
- [ ] Stockfish gives consistent evals (test with known positions)
- [ ] Claude explanations never mention centipawns or engine eval numbers
- [ ] Claude explanations adjust language complexity based on player age/rating
- [ ] Claude always finds something positive to say, even for blunders
- [ ] OCR correctly handles messy handwriting (test with 10+ real scoresheets)
- [ ] Game replay works fully offline (cached analysis)
- [ ] API calls are lazy-loaded and cached — no duplicate calls
- [ ] App handles API failures gracefully (show Stockfish classification without Claude text)
