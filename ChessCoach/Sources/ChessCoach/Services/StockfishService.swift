import Foundation

/// Result from a Stockfish position evaluation
struct StockfishResult: Sendable {
    /// Centipawn score from white's perspective. Positive = white advantage.
    let score: Double
    /// Principal variation — the best continuation found
    let bestLine: [String]
    /// Mate in N moves (positive = white mates, negative = black mates). Nil if no forced mate.
    let mate: Int?
    /// The best move in the position (SAN or UCI notation)
    var bestMove: String? { bestLine.first }

    /// Score normalized from the perspective of the given color
    func score(for color: PieceColor) -> Double {
        color == .white ? score : -score
    }

    /// Whether the position has a forced mate
    var isMate: Bool { mate != nil }

    /// A large absolute score representing mate for classification purposes
    static let mateScore: Double = 10000.0
}

/// Protocol for chess engine evaluation — allows swapping implementations
/// (e.g., real Stockfish binary vs. mock for testing)
protocol ChessEngine: Sendable {
    /// Evaluate a single position at the given depth
    func evaluate(fen: String, depth: Int) async throws -> StockfishResult

    /// Shut down the engine and release resources
    func quit() async
}

/// Default analysis depth — 18 is a good balance of speed vs. accuracy on mobile
let kDefaultEngineDepth = 18

/// Errors from the Stockfish engine
enum StockfishError: Error, LocalizedError {
    case engineNotFound
    case engineCrashed
    case parseError(String)
    case timeout
    case notReady

    var errorDescription: String? {
        switch self {
        case .engineNotFound: return "Stockfish engine not found"
        case .engineCrashed: return "Stockfish engine crashed"
        case .parseError(let detail): return "Failed to parse engine output: \(detail)"
        case .timeout: return "Engine evaluation timed out"
        case .notReady: return "Engine is not ready"
        }
    }
}

/// Stockfish engine communicating via UCI protocol over stdin/stdout pipes.
///
/// On macOS this launches the Stockfish binary as a subprocess.
/// On iOS, replace this with a C++ bridge that calls Stockfish functions
/// directly in-process (iOS doesn't allow subprocess spawning).
///
/// Usage:
/// ```swift
/// let engine = StockfishUCIEngine()
/// try await engine.start()
/// let result = try await engine.evaluate(fen: "startpos", depth: 18)
/// await engine.quit()
/// ```
#if os(macOS)
final class StockfishUCIEngine: ChessEngine, @unchecked Sendable {
    private let enginePath: String
    private let queue = DispatchQueue(label: "com.chesscoach.stockfish", qos: .userInitiated)
    private var process: Process?
    private var stdinPipe: Pipe?
    private var stdoutPipe: Pipe?
    private var isRunning = false

    /// Default search depth — 18 is a good balance of speed vs. accuracy on mobile
    static let defaultDepth = 18

    /// Initialize with path to Stockfish binary.
    /// Pass nil to auto-detect from the app bundle or common install locations.
    init(enginePath: String? = nil) {
        if let path = enginePath {
            self.enginePath = path
        } else {
            // Look for Stockfish in common locations
            let candidates = [
                Bundle.main.path(forResource: "stockfish", ofType: nil),
                "/usr/local/bin/stockfish",
                "/opt/homebrew/bin/stockfish",
                "/usr/bin/stockfish"
            ]
            self.enginePath = candidates.compactMap { $0 }.first(where: {
                FileManager.default.isExecutableFile(atPath: $0)
            }) ?? "stockfish"
        }
    }

    /// Start the Stockfish engine process
    func start() async throws {
        guard !isRunning else { return }
        guard FileManager.default.isExecutableFile(atPath: enginePath) else {
            throw StockfishError.engineNotFound
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: enginePath)

        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = FileHandle.nullDevice

        try process.run()

        self.process = process
        self.stdinPipe = stdinPipe
        self.stdoutPipe = stdoutPipe
        self.isRunning = true

        // Initialize UCI protocol
        try await sendCommand("uci")
        _ = try await readUntil("uciok")

        // Set reasonable defaults for mobile
        try await sendCommand("setoption name Threads value 1")
        try await sendCommand("setoption name Hash value 64")
        try await sendCommand("isready")
        _ = try await readUntil("readyok")
    }

    func evaluate(fen: String, depth: Int = kDefaultEngineDepth) async throws -> StockfishResult {
        guard isRunning else { throw StockfishError.notReady }

        try await sendCommand("position fen \(fen)")
        try await sendCommand("go depth \(depth)")

        let output = try await readUntil("bestmove")
        return try parseSearchOutput(output)
    }

    func quit() async {
        guard isRunning else { return }
        try? await sendCommand("quit")
        process?.waitUntilExit()
        process = nil
        stdinPipe = nil
        stdoutPipe = nil
        isRunning = false
    }

    // MARK: - UCI Communication

    private func sendCommand(_ command: String) async throws {
        guard let pipe = stdinPipe else { throw StockfishError.notReady }
        let data = Data((command + "\n").utf8)
        pipe.fileHandleForWriting.write(data)
    }

    private func readUntil(_ terminator: String, timeout: TimeInterval = 30) async throws -> String {
        guard let pipe = stdoutPipe else { throw StockfishError.notReady }

        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                var accumulated = ""
                let handle = pipe.fileHandleForReading
                let deadline = Date().addingTimeInterval(timeout)

                while Date() < deadline {
                    let data = handle.availableData
                    guard !data.isEmpty else {
                        Thread.sleep(forTimeInterval: 0.01)
                        continue
                    }
                    if let text = String(data: data, encoding: .utf8) {
                        accumulated += text
                        if text.contains(terminator) {
                            continuation.resume(returning: accumulated)
                            return
                        }
                    }
                }
                continuation.resume(throwing: StockfishError.timeout)
            }
        }
    }

    // MARK: - Output Parsing

    /// Parse the UCI search output into a StockfishResult.
    /// Extracts the last "info depth" line and the "bestmove" line.
    private func parseSearchOutput(_ output: String) throws -> StockfishResult {
        let lines = output.components(separatedBy: .newlines)

        // Find the deepest info line with a score
        var lastScore: Double = 0
        var lastMate: Int? = nil
        var lastPV: [String] = []

        for line in lines {
            guard line.hasPrefix("info") && line.contains(" score ") else { continue }

            // Parse score
            if let mateRange = line.range(of: "score mate ") {
                let afterMate = line[mateRange.upperBound...]
                if let mateVal = Int(afterMate.prefix(while: { $0 == "-" || $0.isNumber })) {
                    lastMate = mateVal
                    lastScore = mateVal > 0 ? StockfishResult.mateScore : -StockfishResult.mateScore
                }
            } else if let cpRange = line.range(of: "score cp ") {
                let afterCP = line[cpRange.upperBound...]
                if let cp = Int(afterCP.prefix(while: { $0 == "-" || $0.isNumber })) {
                    lastScore = Double(cp)
                    lastMate = nil
                }
            }

            // Parse principal variation
            if let pvRange = line.range(of: " pv ") {
                let pvString = String(line[pvRange.upperBound...])
                lastPV = pvString.components(separatedBy: " ").filter { !$0.isEmpty }
            }
        }

        return StockfishResult(
            score: lastScore,
            bestLine: lastPV,
            mate: lastMate
        )
    }
}
#endif

// MARK: - Mock Engine for Testing & Previews

/// A mock chess engine that returns plausible-looking evaluations without Stockfish.
/// Uses simple material counting and basic heuristics for classification testing.
final class MockChessEngine: ChessEngine, @unchecked Sendable {

    func evaluate(fen: String, depth: Int = 18) async throws -> StockfishResult {
        guard let position = BoardPosition.fromFEN(fen) else {
            throw StockfishError.parseError("Invalid FEN: \(fen)")
        }

        let score = evaluateMaterial(position)
        return StockfishResult(score: score, bestLine: [], mate: nil)
    }

    func quit() async {}

    /// Simple material-based evaluation in centipawns
    private func evaluateMaterial(_ position: BoardPosition) -> Double {
        var score = 0.0
        let values: [PieceType: Double] = [
            .pawn: 100, .knight: 320, .bishop: 330,
            .rook: 500, .queen: 900, .king: 0
        ]

        for rank in 0..<8 {
            for file in 0..<8 {
                guard let piece = position.board[rank][file] else { continue }
                let value = values[piece.type] ?? 0
                score += piece.color == .white ? value : -value
            }
        }

        // Small positional bonuses
        // Center control bonus for pawns and knights
        let centerFiles = 2...5
        let centerRanks = 2...5
        for rank in centerRanks {
            for file in centerFiles {
                if let piece = position.board[rank][file] {
                    let bonus: Double = (piece.type == .pawn || piece.type == .knight) ? 10 : 5
                    score += piece.color == .white ? bonus : -bonus
                }
            }
        }

        return score
    }
}
