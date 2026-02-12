import Foundation

/// Result of a chess game
enum GameResult: String, Codable {
    case whiteWins = "1-0"
    case blackWins = "0-1"
    case draw = "1/2-1/2"
    case ongoing = "*"

    var displayText: String {
        switch self {
        case .whiteWins: return "1-0"
        case .blackWins: return "0-1"
        case .draw: return "½-½"
        case .ongoing: return "*"
        }
    }
}

/// Represents a full chess game with moves and analysis
struct Game: Identifiable, Codable {
    let id: UUID
    /// Player names
    let white: String
    let black: String
    /// Tournament/event name
    let event: String?
    /// Round number
    let round: String?
    /// Date of game
    let date: Date?
    /// Game result
    let result: GameResult
    /// Opening name (from ECO or analysis)
    let opening: String?
    /// Which color the user played
    let playerColor: PieceColor
    /// The list of moves in order
    let moves: [ChessMove]
    /// Annotations for each move (indexed by move list position)
    let annotations: [Int: MoveAnnotation]
    /// Positions after each move (index 0 = initial position, index n = position after move n-1)
    let positions: [BoardPosition]

    /// Accuracy percentage (0-100) for the player
    var accuracy: Double? {
        let playerMoves = moves.enumerated().filter { $0.element.color == playerColor }
        guard !playerMoves.isEmpty else { return nil }
        let goodMoves = playerMoves.filter { index, _ in
            guard let annotation = annotations[index] else { return true }
            return annotation.classification == .brilliant ||
                   annotation.classification == .great ||
                   annotation.classification == .good
        }
        return Double(goodMoves.count) / Double(playerMoves.count) * 100.0
    }

    /// The opponent's name based on player color
    var opponentName: String {
        playerColor == .white ? black : white
    }

    /// Whether the player won
    var playerWon: Bool {
        (playerColor == .white && result == .whiteWins) ||
        (playerColor == .black && result == .blackWins)
    }

    /// Whether the player lost
    var playerLost: Bool {
        (playerColor == .white && result == .blackWins) ||
        (playerColor == .black && result == .whiteWins)
    }

    init(
        id: UUID = UUID(),
        white: String,
        black: String,
        event: String? = nil,
        round: String? = nil,
        date: Date? = nil,
        result: GameResult,
        opening: String? = nil,
        playerColor: PieceColor,
        moves: [ChessMove],
        annotations: [Int: MoveAnnotation] = [:],
        positions: [BoardPosition]
    ) {
        self.id = id
        self.white = white
        self.black = black
        self.event = event
        self.round = round
        self.date = date
        self.result = result
        self.opening = opening
        self.playerColor = playerColor
        self.moves = moves
        self.annotations = annotations
        self.positions = positions
    }
}
