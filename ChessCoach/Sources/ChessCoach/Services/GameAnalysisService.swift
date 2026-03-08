import Foundation
import Observation

/// Per-position evaluation result from the engine
struct PositionEval {
    let moveIndex: Int
    let fen: String
    let san: String
    let evalBefore: Double
    let evalAfter: Double
    let bestMove: String?
    let bestLine: [String]
    let mate: Int?
    let classification: MoveClassification
    let color: PieceColor

    /// Centipawn loss from the moving side's perspective
    var evalChange: Double {
        let delta = evalAfter - evalBefore
        // For white, positive delta is good. For black, negative delta is good.
        return color == .white ? -delta : delta
    }
}

/// Progress reporting for game analysis
struct AnalysisProgress: Sendable {
    let currentMove: Int
    let totalMoves: Int
    let phase: AnalysisPhase

    var fraction: Double {
        guard totalMoves > 0 else { return 0 }
        return Double(currentMove) / Double(totalMoves)
    }

    enum AnalysisPhase: String, Sendable {
        case starting = "Starting analysis..."
        case evaluating = "Analyzing positions..."
        case classifying = "Classifying moves..."
        case complete = "Analysis complete"
    }
}

/// Orchestrates Stockfish analysis of a full game.
/// Takes a Game, evaluates every position, classifies each move, and
/// returns annotations ready to be stored.
@Observable
final class GameAnalysisService {
    private let engine: ChessEngine
    private let depth: Int

    /// Current analysis progress (observable for UI binding)
    var progress: AnalysisProgress?
    /// Whether an analysis is in progress
    var isAnalyzing: Bool = false

    /// Initialize with a chess engine and search depth.
    /// Defaults to ChessKitStockfishEngine (Stockfish 17, works on iOS and macOS).
    /// Falls back to MockChessEngine if no engine is provided explicitly.
    init(engine: ChessEngine? = nil, depth: Int = kDefaultEngineDepth) {
        self.engine = engine ?? ChessKitStockfishEngine()
        self.depth = depth
    }

    /// Analyze a full game and return annotations for every move.
    ///
    /// This evaluates every position in the game, computes eval deltas,
    /// and classifies each move (brilliant → blunder) based on centipawn loss.
    ///
    /// - Parameters:
    ///   - game: The game to analyze
    ///   - onProgress: Optional callback for progress updates
    /// - Returns: Dictionary mapping move index to annotation
    func analyzeGame(
        _ game: Game,
        onProgress: ((AnalysisProgress) -> Void)? = nil
    ) async throws -> [Int: MoveAnnotation] {
        isAnalyzing = true
        defer { isAnalyzing = false }

        let totalMoves = game.moves.count
        guard totalMoves > 0 else { return [:] }

        // Start the engine if it supports it
        if let stockfish = engine as? ChessKitStockfishEngine {
            try await stockfish.start()
        }
        defer {
            Task { await engine.quit() }
        }

        // Phase 1: Evaluate all positions
        updateProgress(.init(currentMove: 0, totalMoves: totalMoves, phase: .starting))
        onProgress?(progress!)

        var evals: [StockfishResult] = []

        // Evaluate the starting position and every position after each move
        for i in 0...totalMoves {
            let fen = game.positions[i].toFEN()
            let result = try await engine.evaluate(fen: fen, depth: depth)
            evals.append(result)

            let prog = AnalysisProgress(
                currentMove: i,
                totalMoves: totalMoves,
                phase: .evaluating
            )
            updateProgress(prog)
            onProgress?(prog)
        }

        // Phase 2: Classify each move based on eval delta
        updateProgress(.init(currentMove: totalMoves, totalMoves: totalMoves, phase: .classifying))
        onProgress?(progress!)

        var annotations: [Int: MoveAnnotation] = [:]

        for i in 0..<totalMoves {
            let move = game.moves[i]
            let evalBefore = evals[i]
            let evalAfter = evals[i + 1]

            let classification = classifyMove(
                evalBefore: evalBefore,
                evalAfter: evalAfter,
                move: move
            )

            // Convert best move from UCI to SAN if possible
            let bestMoveSAN = convertBestMove(
                uciMove: evalBefore.bestMove,
                position: game.positions[i]
            )

            annotations[i] = MoveAnnotation(
                classification: classification,
                explanation: generatePlaceholderExplanation(
                    classification: classification,
                    move: move,
                    bestMove: bestMoveSAN
                ),
                bestMove: bestMoveSAN,
                evalBefore: evalBefore.score / 100.0,
                evalAfter: evalAfter.score / 100.0,
                engineLines: evalBefore.bestLine
            )
        }

        updateProgress(.init(currentMove: totalMoves, totalMoves: totalMoves, phase: .complete))
        onProgress?(progress!)

        return annotations
    }

    /// Analyze a single position (for on-demand evaluation during replay)
    func evaluatePosition(fen: String) async throws -> StockfishResult {
        try await engine.evaluate(fen: fen, depth: depth)
    }

    // MARK: - Move Classification

    /// Classify a move based on the eval delta.
    ///
    /// Thresholds (centipawns from the moving side's perspective):
    /// - brilliant: eval improves by >100cp AND it's a sacrifice or only move
    /// - great: best or near-best move (within 10cp)
    /// - good: within 30cp of best
    /// - inaccuracy: 30-100cp loss
    /// - mistake: 100-300cp loss
    /// - blunder: >300cp loss
    func classifyMove(
        evalBefore: StockfishResult,
        evalAfter: StockfishResult,
        move: ChessMove
    ) -> MoveClassification {
        let before = evalBefore.score
        let after = evalAfter.score

        // Calculate centipawn loss from the moving side's perspective
        let delta: Double
        if move.color == .white {
            // For white, higher eval is better
            delta = before - after  // positive = move made things worse
        } else {
            // For black, lower eval is better
            delta = after - before  // positive = move made things worse
        }

        // Handle mate scenarios
        if let mateBefore = evalBefore.mate, let mateAfter = evalAfter.mate {
            // Was winning mate, still winning mate (but maybe shorter/longer)
            let beforeFavorable = (move.color == .white && mateBefore > 0) || (move.color == .black && mateBefore < 0)
            let afterFavorable = (move.color == .white && mateAfter > 0) || (move.color == .black && mateAfter < 0)

            if beforeFavorable && afterFavorable {
                return .great
            } else if beforeFavorable && !afterFavorable {
                return .blunder  // Lost a winning mate
            } else if !beforeFavorable && afterFavorable {
                return .brilliant  // Found a mate the opponent missed
            }
        }

        if evalAfter.mate != nil && evalBefore.mate == nil {
            // Found a new mate — check if it's for the mover
            let mateForMover = (move.color == .white && evalAfter.mate! > 0) ||
                               (move.color == .black && evalAfter.mate! < 0)
            if mateForMover { return .brilliant }
            return .blunder  // Allowed opponent to have forced mate
        }

        if evalBefore.mate != nil && evalAfter.mate == nil {
            // Lost a forced mate
            let wasOurMate = (move.color == .white && evalBefore.mate! > 0) ||
                             (move.color == .black && evalBefore.mate! < 0)
            if wasOurMate { return .mistake }
        }

        // Standard centipawn-based classification
        // Check for brilliant: significant improvement AND involves sacrifice
        if delta < -100 && move.captured != nil {
            // The position improved significantly despite material exchange
            // This is a heuristic — real brilliancy detection needs deeper analysis
            return .brilliant
        }

        switch delta {
        case ..<10:
            return .great       // Best or near-best move
        case 10..<30:
            return .good        // Slight imprecision
        case 30..<100:
            return .inaccuracy  // Noticeable slip
        case 100..<300:
            return .mistake     // Significant error
        default:
            return .blunder     // Game-changing error
        }
    }

    // MARK: - Helpers

    private func updateProgress(_ progress: AnalysisProgress) {
        self.progress = progress
    }

    /// Try to convert a UCI move (e.g. "e2e4") to SAN using the position's legal moves
    private func convertBestMove(uciMove: String?, position: BoardPosition) -> String? {
        guard let uci = uciMove, uci.count >= 4 else { return nil }

        let fromNotation = String(uci.prefix(2))
        let toNotation = String(uci.dropFirst(2).prefix(2))

        guard let from = Square(fromNotation), let to = Square(toNotation) else { return nil }

        // Find matching legal move
        let legalMoves = position.legalMoves()
        if let match = legalMoves.first(where: { $0.from == from && $0.to == to }) {
            return match.san
        }
        return nil
    }

    /// Generate a placeholder explanation until Claude API provides real coaching.
    /// This gives basic feedback based on classification and move context.
    private func generatePlaceholderExplanation(
        classification: MoveClassification,
        move: ChessMove,
        bestMove: String?
    ) -> String {
        switch classification {
        case .brilliant:
            return "Excellent find! \(move.san) is a strong move that really improves your position."
        case .great:
            return "\(move.san) is one of the best moves here. Well played!"
        case .good:
            return "\(move.san) is a solid choice. You're on the right track."
        case .inaccuracy:
            if let best = bestMove {
                return "\(move.san) is okay, but \(best) was a bit stronger here."
            }
            return "\(move.san) is okay, but there was a slightly better option."
        case .mistake:
            if let best = bestMove {
                return "\(move.san) lets your opponent improve their position. \(best) would have been better."
            }
            return "\(move.san) gives your opponent a chance to take advantage."
        case .blunder:
            if let best = bestMove {
                return "Careful! \(move.san) is a big slip. \(best) was much stronger here."
            }
            return "Careful! \(move.san) really changes the game. Take a closer look at what your opponent can do after this."
        }
    }

    // MARK: - Batch Analysis Stats

    /// Compute summary statistics from annotations
    static func computeStats(
        annotations: [Int: MoveAnnotation],
        moves: [ChessMove],
        playerColor: PieceColor
    ) -> AnalysisStats {
        let playerAnnotations = annotations.filter { index, _ in
            index < moves.count && moves[index].color == playerColor
        }

        var counts: [MoveClassification: Int] = [:]
        for classification in MoveClassification.allCases {
            counts[classification] = 0
        }
        for (_, annotation) in playerAnnotations {
            counts[annotation.classification, default: 0] += 1
        }

        let totalPlayerMoves = moves.filter { $0.color == playerColor }.count
        let goodMoves = (counts[.brilliant] ?? 0) + (counts[.great] ?? 0) + (counts[.good] ?? 0)
        let accuracy = totalPlayerMoves > 0
            ? Double(goodMoves) / Double(totalPlayerMoves) * 100.0
            : 0

        // Average centipawn loss
        let losses = playerAnnotations.compactMap { $0.value.cpLoss }
        let avgCPLoss = losses.isEmpty ? 0 : losses.reduce(0, +) / Double(losses.count)

        // Key moments (big eval swings)
        let keyMoments = playerAnnotations
            .filter { $0.value.isKeyMoment }
            .map { $0.key }
            .sorted()

        return AnalysisStats(
            accuracy: accuracy,
            averageCPLoss: avgCPLoss,
            classificationCounts: counts,
            keyMoments: keyMoments,
            totalPlayerMoves: totalPlayerMoves
        )
    }
}

/// Summary statistics from a game analysis
struct AnalysisStats {
    let accuracy: Double
    let averageCPLoss: Double
    let classificationCounts: [MoveClassification: Int]
    let keyMoments: [Int]
    let totalPlayerMoves: Int

    var brilliantCount: Int { classificationCounts[.brilliant] ?? 0 }
    var greatCount: Int { classificationCounts[.great] ?? 0 }
    var goodCount: Int { classificationCounts[.good] ?? 0 }
    var inaccuracyCount: Int { classificationCounts[.inaccuracy] ?? 0 }
    var mistakeCount: Int { classificationCounts[.mistake] ?? 0 }
    var blunderCount: Int { classificationCounts[.blunder] ?? 0 }
}
