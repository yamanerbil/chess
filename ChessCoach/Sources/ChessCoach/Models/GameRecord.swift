import Foundation
import SwiftData

/// SwiftData model for persisting chess games.
/// Complex value types (moves, positions, annotations) are stored as JSON-encoded Data.
@Model
final class GameRecord {
    @Attribute(.unique) var id: UUID
    var white: String
    var black: String
    var event: String?
    var round: String?
    var date: Date?
    var resultRaw: String
    var opening: String?
    var playerColorRaw: String
    var movesData: Data
    var annotationsData: Data
    var positionsData: Data
    var createdAt: Date

    init(
        id: UUID = UUID(),
        white: String,
        black: String,
        event: String? = nil,
        round: String? = nil,
        date: Date? = nil,
        resultRaw: String,
        opening: String? = nil,
        playerColorRaw: String,
        movesData: Data,
        annotationsData: Data,
        positionsData: Data,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.white = white
        self.black = black
        self.event = event
        self.round = round
        self.date = date
        self.resultRaw = resultRaw
        self.opening = opening
        self.playerColorRaw = playerColorRaw
        self.movesData = movesData
        self.annotationsData = annotationsData
        self.positionsData = positionsData
        self.createdAt = createdAt
    }

    /// Create a GameRecord from a Game value type
    convenience init(game: Game) {
        let encoder = JSONEncoder()
        let movesData = (try? encoder.encode(game.moves)) ?? Data()
        let annotationsData = (try? encoder.encode(game.annotations)) ?? Data()
        let positionsData = (try? encoder.encode(game.positions)) ?? Data()

        self.init(
            id: game.id,
            white: game.white,
            black: game.black,
            event: game.event,
            round: game.round,
            date: game.date,
            resultRaw: game.result.rawValue,
            opening: game.opening,
            playerColorRaw: game.playerColor.rawValue,
            movesData: movesData,
            annotationsData: annotationsData,
            positionsData: positionsData
        )
    }

    /// Convert back to a Game value type for use in views
    func toGame() -> Game? {
        let decoder = JSONDecoder()
        guard let result = GameResult(rawValue: resultRaw),
              let playerColor = PieceColor(rawValue: playerColorRaw),
              let moves = try? decoder.decode([ChessMove].self, from: movesData),
              let positions = try? decoder.decode([BoardPosition].self, from: positionsData)
        else { return nil }

        let annotations = (try? decoder.decode([Int: MoveAnnotation].self, from: annotationsData)) ?? [:]

        return Game(
            id: id,
            white: white,
            black: black,
            event: event,
            round: round,
            date: date,
            result: result,
            opening: opening,
            playerColor: playerColor,
            moves: moves,
            annotations: annotations,
            positions: positions
        )
    }
}
