import SwiftUI
import Observation

/// View model for the Game Review screen
@Observable
final class GameReviewViewModel {
    let game: Game

    /// Current move index: 0 = starting position, 1 = after first move, etc.
    var currentMoveIndex: Int = 0 {
        didSet {
            currentMoveIndex = max(0, min(currentMoveIndex, game.moves.count))
        }
    }

    /// Which tab is selected
    var selectedTab: ReviewTab = .board

    enum ReviewTab: String, CaseIterable {
        case board = "Board"
        case moves = "Moves"
        case report = "Report"
    }

    /// The current board position
    var currentPosition: BoardPosition {
        game.positions[currentMoveIndex]
    }

    /// The last move played (nil at starting position)
    var lastMove: ChessMove? {
        currentMoveIndex > 0 ? game.moves[currentMoveIndex - 1] : nil
    }

    /// Annotation for the current move
    var currentAnnotation: MoveAnnotation? {
        guard currentMoveIndex > 0 else { return nil }
        return game.annotations[currentMoveIndex - 1]
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

    init(game: Game) {
        self.game = game
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
