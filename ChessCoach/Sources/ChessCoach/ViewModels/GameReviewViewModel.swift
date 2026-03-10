import SwiftUI
import Observation

/// View model for the Game Review screen
@Observable
final class GameReviewViewModel {
    private(set) var game: Game

    /// Current move index: 0 = starting position, 1 = after first move, etc.
    /// Uses a backing store to avoid infinite recursion with @Observable's didSet.
    var currentMoveIndex: Int {
        get { _currentMoveIndex }
        set { _currentMoveIndex = max(0, min(newValue, game.moves.count)) }
    }
    private var _currentMoveIndex: Int = 0

    /// Which tab is selected
    var selectedTab: ReviewTab = .board

    enum ReviewTab: String, CaseIterable {
        case board = "Board"
        case moves = "Moves"
        case report = "Report"
    }

    // MARK: - Analysis State

    /// The analysis service used for engine evaluation
    let analysisService: GameAnalysisService

    /// The coaching service for Claude API explanations
    let coachService: ClaudeCoachService

    /// Player profile for age/rating-calibrated coaching
    var playerProfile: CoachingProfile

    /// Live annotations — starts with the game's existing annotations,
    /// gets replaced when engine analysis completes
    private(set) var liveAnnotations: [Int: MoveAnnotation]

    /// Whether engine analysis is in progress
    var isAnalyzing: Bool { analysisService.isAnalyzing }

    /// Current analysis progress
    var analysisProgress: AnalysisProgress? { analysisService.progress }

    /// Error from the last analysis attempt
    var analysisError: String?

    /// Whether this game has been analyzed by the engine
    var hasEngineAnalysis: Bool = false

    /// Whether Claude coaching is loading for the current move
    var isLoadingCoaching: Bool { coachService.isLoading }

    /// Set of move indices that have received Claude coaching
    private(set) var coachedMoveIndices: Set<Int> = []

    /// Full game report from Claude
    private(set) var gameReport: GameReport?

    /// Whether a game report is being generated
    var isGeneratingReport: Bool = false

    // MARK: - Computed Properties

    /// The current board position
    var currentPosition: BoardPosition {
        game.positions[currentMoveIndex]
    }

    /// The last move played (nil at starting position)
    var lastMove: ChessMove? {
        currentMoveIndex > 0 ? game.moves[currentMoveIndex - 1] : nil
    }

    /// Annotation for the current move (uses live annotations)
    var currentAnnotation: MoveAnnotation? {
        guard currentMoveIndex > 0 else { return nil }
        return liveAnnotations[currentMoveIndex - 1]
    }

    /// Current evaluation
    var currentEval: Double {
        currentAnnotation?.evalAfter ?? 0.0
    }

    /// Whether we're at the starting position
    var isAtStart: Bool { currentMoveIndex == 0 }

    /// Whether we're at the last move
    var isAtEnd: Bool { currentMoveIndex >= game.moves.count }

    /// Navigation bar title (e.g. "Round 3 Analysis")
    var titleText: String {
        if let round = game.round {
            return "Round \(round) Analysis"
        }
        return "Game Analysis"
    }

    /// Navigation bar subtitle (e.g. "vs. Alex R. (1450)")
    var subtitleText: String {
        "vs. \(game.opponentName)"
    }

    /// Result display text
    var resultText: String {
        if game.playerWon {
            return "Won (\(game.result.displayText))"
        } else if game.playerLost {
            return "Lost (\(game.result.displayText))"
        } else {
            return "Draw (\(game.result.displayText))"
        }
    }

    /// Star prefix for wins
    var resultIcon: String {
        if game.playerWon { return "star.fill" }
        if game.playerLost { return "xmark.circle" }
        return "equal.circle"
    }

    var resultColor: Color {
        if game.playerWon { return DesignSystem.Colors.success }
        if game.playerLost { return DesignSystem.Colors.error }
        return DesignSystem.Colors.secondaryText
    }

    init(
        game: Game,
        analysisService: GameAnalysisService = GameAnalysisService(),
        coachService: ClaudeCoachService = ClaudeCoachService(),
        playerProfile: CoachingProfile = .default
    ) {
        self.game = game
        self.analysisService = analysisService
        self.coachService = coachService
        self.playerProfile = playerProfile
        self.liveAnnotations = game.annotations
    }

    // MARK: - Engine Analysis

    /// Run Stockfish analysis on the full game.
    /// Updates `liveAnnotations` as results come in.
    func runAnalysis() async {
        guard !isAnalyzing else { return }
        analysisError = nil

        do {
            let annotations = try await analysisService.analyzeGame(game)
            liveAnnotations = annotations
            hasEngineAnalysis = true

            // Update the game with new annotations
            game = Game(
                id: game.id,
                white: game.white,
                black: game.black,
                event: game.event,
                round: game.round,
                date: game.date,
                result: game.result,
                opening: game.opening,
                playerColor: game.playerColor,
                moves: game.moves,
                annotations: annotations,
                positions: game.positions
            )
        } catch {
            analysisError = error.localizedDescription
        }
    }

    // MARK: - Claude Coaching

    /// Request a Claude coaching explanation for the current move.
    /// Replaces the placeholder annotation with Claude's kid-friendly explanation.
    func requestCoaching() async {
        let moveIdx = currentMoveIndex - 1
        guard moveIdx >= 0,
              moveIdx < game.moves.count,
              let annotation = liveAnnotations[moveIdx],
              !coachedMoveIndices.contains(moveIdx) else { return }

        let move = game.moves[moveIdx]

        if let updated = await coachService.explainMove(
            move: move,
            annotation: annotation,
            game: game,
            moveIndex: moveIdx,
            profile: playerProfile
        ) {
            liveAnnotations[moveIdx] = updated
            coachedMoveIndices.insert(moveIdx)
        }

        if let error = coachService.lastError {
            analysisError = error
        }
    }

    /// Whether the current move has Claude coaching (not just placeholder)
    var currentMoveHasCoaching: Bool {
        currentMoveIndex > 0 && coachedMoveIndices.contains(currentMoveIndex - 1)
    }

    /// Generate a full game coaching report via Claude.
    func requestGameReport() async {
        guard !isGeneratingReport, gameReport == nil else { return }
        isGeneratingReport = true
        defer { isGeneratingReport = false }

        gameReport = await coachService.analyzeFullGame(
            game: game,
            profile: playerProfile
        )

        if let error = coachService.lastError {
            analysisError = error
        }
    }

    /// Analysis stats for the player
    var analysisStats: AnalysisStats {
        GameAnalysisService.computeStats(
            annotations: liveAnnotations,
            moves: game.moves,
            playerColor: game.playerColor
        )
    }

    // MARK: - Navigation

    func goToStart() {
        withAnimation(.easeInOut(duration: 0.15)) {
            currentMoveIndex = 0
        }
    }

    func goToEnd() {
        withAnimation(.easeInOut(duration: 0.15)) {
            currentMoveIndex = game.moves.count
        }
    }

    func goForward() {
        guard !isAtEnd else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            currentMoveIndex += 1
        }
    }

    func goBackward() {
        guard !isAtStart else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            currentMoveIndex -= 1
        }
    }

    func goToMove(_ index: Int) {
        withAnimation(.easeInOut(duration: 0.15)) {
            currentMoveIndex = index
        }
    }
}
