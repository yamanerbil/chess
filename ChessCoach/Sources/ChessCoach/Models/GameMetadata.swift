import Foundation

/// Data collected from the game metadata form
struct GameMetadata {
    let playerColor: PieceColor
    let result: GameResult
    let opponentName: String
    let tournament: String?
    let round: String?
    let playerRating: Int?
    let opponentRating: Int?
}
