import Foundation
import ChessKitEngine

/// Adapter that wraps ChessKitEngine's `Engine` (Stockfish 17) to conform
/// to our `ChessEngine` protocol. Works on both iOS and macOS.
///
/// ChessKitEngine handles the C++ bridge and in-process engine lifecycle,
/// so this works on iOS where subprocess spawning is not allowed.
///
/// ## NNUE Setup
/// Stockfish 17 requires neural network files for full-strength evaluation.
/// Without them it falls back to classical evaluation (still strong, ~3000 Elo).
/// To use NNUE:
/// 1. Download `nn-1111cefa1111.nnue` and `nn-37f18f62d772.nnue` from
///    https://tests.stockfishchess.org/nns
/// 2. Add them to your app bundle
/// 3. Call `configureNNUE()` after starting the engine
final class ChessKitStockfishEngine: ChessEngine, @unchecked Sendable {
    private var engine: Engine?
    private let queue = DispatchQueue(label: "com.chesscoach.chesskitengine", qos: .userInitiated)

    func start() async throws {
        let engine = Engine(type: .stockfish)
        self.engine = engine

        // Wait for engine to be ready
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task {
                guard let stream = await engine.responseStream else {
                    continuation.resume()
                    return
                }
                await engine.start()
                for await response in stream {
                    if case .readyok = response {
                        continuation.resume()
                        return
                    }
                }
                continuation.resume()
            }
        }

        // Configure for mobile: single thread, small hash
        await engine.send(command: .setoption(id: "Threads", value: "1"))
        await engine.send(command: .setoption(id: "Hash", value: "64"))

        // Try to configure NNUE files from app bundle
        await configureNNUE()

        await engine.send(command: .isready)
    }

    func evaluate(fen: String, depth: Int = kDefaultEngineDepth) async throws -> StockfishResult {
        guard let engine = engine else {
            throw StockfishError.notReady
        }

        // Set up position
        await engine.send(command: .position(.fen(fen)))
        await engine.send(command: .go(depth: depth))

        // Collect responses until we get bestmove
        return await withCheckedContinuation { continuation in
            Task {
                var lastScore: Double = 0
                var lastMate: Int? = nil
                var lastPV: [String] = []

                guard let stream = await engine.responseStream else {
                    continuation.resume(returning: StockfishResult(score: 0, bestLine: [], mate: nil))
                    return
                }

                for await response in stream {
                    switch response {
                    case .info(let info):
                        // Update score from the latest info line
                        if let score = info.score {
                            if let cp = score.cp {
                                lastScore = Double(cp)
                                lastMate = nil
                            }
                            if let mate = score.mate {
                                lastMate = mate
                                lastScore = mate > 0 ? StockfishResult.mateScore : -StockfishResult.mateScore
                            }
                        }
                        if let pv = info.pv {
                            lastPV = pv
                        }

                    case .bestmove:
                        // Done — return accumulated result
                        continuation.resume(returning: StockfishResult(
                            score: lastScore,
                            bestLine: lastPV,
                            mate: lastMate
                        ))
                        return

                    default:
                        break
                    }
                }

                // Stream ended without bestmove
                continuation.resume(returning: StockfishResult(
                    score: lastScore,
                    bestLine: lastPV,
                    mate: lastMate
                ))
            }
        }
    }

    func quit() async {
        guard let engine = engine else { return }
        await engine.stop()
        self.engine = nil
    }

    // MARK: - NNUE Configuration

    /// Attempt to configure NNUE eval files from the app bundle.
    /// If not found, Stockfish falls back to classical evaluation.
    private func configureNNUE() async {
        guard let engine = engine else { return }

        // Look for the large NNUE file
        if let bigNNUE = Bundle.main.url(forResource: "nn-1111cefa1111", withExtension: "nnue") {
            await engine.send(command: .setoption(id: "EvalFile", value: bigNNUE.path))
        }

        // Look for the small NNUE file
        if let smallNNUE = Bundle.main.url(forResource: "nn-37f18f62d772", withExtension: "nnue") {
            await engine.send(command: .setoption(id: "EvalFileSmall", value: smallNNUE.path))
        }
    }
}
