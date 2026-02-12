import Foundation

/// Represents a full chess board position
struct BoardPosition: Equatable, Codable {
    /// 8x8 board array. board[rank][file], where rank 0 = rank 1, file 0 = a-file
    var board: [[ChessPiece?]]
    /// Whose turn it is to move
    var activeColor: PieceColor
    /// Castling rights
    var castlingRights: CastlingRights
    /// En passant target square, if any
    var enPassantTarget: Square?
    /// Halfmove clock (for 50-move rule)
    var halfmoveClock: Int
    /// Fullmove number
    var fullmoveNumber: Int

    struct CastlingRights: Equatable, Codable {
        var whiteKingside: Bool
        var whiteQueenside: Bool
        var blackKingside: Bool
        var blackQueenside: Bool

        static let initial = CastlingRights(
            whiteKingside: true,
            whiteQueenside: true,
            blackKingside: true,
            blackQueenside: true
        )

        static let none = CastlingRights(
            whiteKingside: false,
            whiteQueenside: false,
            blackKingside: false,
            blackQueenside: false
        )
    }

    /// Get the piece at a given square
    func piece(at square: Square) -> ChessPiece? {
        guard square.isValid else { return nil }
        return board[square.rank][square.file]
    }

    /// Set a piece at a given square
    mutating func setPiece(_ piece: ChessPiece?, at square: Square) {
        guard square.isValid else { return }
        board[square.rank][square.file] = piece
    }

    /// The standard starting position
    static let initial: BoardPosition = {
        var board = [[ChessPiece?]](repeating: [ChessPiece?](repeating: nil, count: 8), count: 8)

        // White pieces (rank 0 = rank 1)
        board[0][0] = ChessPiece(color: .white, type: .rook)
        board[0][1] = ChessPiece(color: .white, type: .knight)
        board[0][2] = ChessPiece(color: .white, type: .bishop)
        board[0][3] = ChessPiece(color: .white, type: .queen)
        board[0][4] = ChessPiece(color: .white, type: .king)
        board[0][5] = ChessPiece(color: .white, type: .bishop)
        board[0][6] = ChessPiece(color: .white, type: .knight)
        board[0][7] = ChessPiece(color: .white, type: .rook)
        for file in 0..<8 {
            board[1][file] = ChessPiece(color: .white, type: .pawn)
        }

        // Black pieces (rank 7 = rank 8)
        board[7][0] = ChessPiece(color: .black, type: .rook)
        board[7][1] = ChessPiece(color: .black, type: .knight)
        board[7][2] = ChessPiece(color: .black, type: .bishop)
        board[7][3] = ChessPiece(color: .black, type: .queen)
        board[7][4] = ChessPiece(color: .black, type: .king)
        board[7][5] = ChessPiece(color: .black, type: .bishop)
        board[7][6] = ChessPiece(color: .black, type: .knight)
        board[7][7] = ChessPiece(color: .black, type: .rook)
        for file in 0..<8 {
            board[6][file] = ChessPiece(color: .black, type: .pawn)
        }

        return BoardPosition(
            board: board,
            activeColor: .white,
            castlingRights: .initial,
            enPassantTarget: nil,
            halfmoveClock: 0,
            fullmoveNumber: 1
        )
    }()

    /// Parse a FEN string into a BoardPosition
    static func fromFEN(_ fen: String) -> BoardPosition? {
        let parts = fen.split(separator: " ")
        guard parts.count >= 4 else { return nil }

        // Parse piece placement
        var board = [[ChessPiece?]](repeating: [ChessPiece?](repeating: nil, count: 8), count: 8)
        let ranks = parts[0].split(separator: "/")
        guard ranks.count == 8 else { return nil }

        for (index, rankStr) in ranks.enumerated() {
            let rank = 7 - index // FEN starts from rank 8
            var file = 0
            for char in rankStr {
                if let emptyCount = char.wholeNumberValue {
                    file += emptyCount
                } else if let piece = ChessPiece(fenChar: char) {
                    guard file < 8 else { return nil }
                    board[rank][file] = piece
                    file += 1
                } else {
                    return nil
                }
            }
        }

        // Parse active color
        let activeColor: PieceColor = String(parts[1]) == "w" ? .white : .black

        // Parse castling
        let castlingStr = String(parts[2])
        let castling = CastlingRights(
            whiteKingside: castlingStr.contains("K"),
            whiteQueenside: castlingStr.contains("Q"),
            blackKingside: castlingStr.contains("k"),
            blackQueenside: castlingStr.contains("q")
        )

        // Parse en passant
        let epStr = String(parts[3])
        let enPassant = epStr == "-" ? nil : Square(epStr)

        // Parse clocks (optional)
        let halfmove = parts.count > 4 ? Int(parts[4]) ?? 0 : 0
        let fullmove = parts.count > 5 ? Int(parts[5]) ?? 1 : 1

        return BoardPosition(
            board: board,
            activeColor: activeColor,
            castlingRights: castling,
            enPassantTarget: enPassant,
            halfmoveClock: halfmove,
            fullmoveNumber: fullmove
        )
    }

    /// Apply a move to this position and return the resulting position.
    /// This is a simplified version that works with pre-parsed ChessMove objects.
    func applyingMove(_ move: ChessMove) -> BoardPosition {
        var newPosition = self

        // Remove piece from source
        newPosition.setPiece(nil, at: move.from)

        // Handle en passant capture
        if move.isEnPassant {
            let capturedPawnRank = move.color == .white ? move.to.rank - 1 : move.to.rank + 1
            newPosition.setPiece(nil, at: Square(file: move.to.file, rank: capturedPawnRank))
        }

        // Place piece at destination (or promoted piece)
        if let promotion = move.promotion {
            newPosition.setPiece(ChessPiece(color: move.color, type: promotion), at: move.to)
        } else {
            newPosition.setPiece(move.piece, at: move.to)
        }

        // Handle castling rook movement
        if move.isCastle {
            let rank = move.color == .white ? 0 : 7
            if move.to.file == 6 { // Kingside
                newPosition.setPiece(nil, at: Square(file: 7, rank: rank))
                newPosition.setPiece(ChessPiece(color: move.color, type: .rook), at: Square(file: 5, rank: rank))
            } else if move.to.file == 2 { // Queenside
                newPosition.setPiece(nil, at: Square(file: 0, rank: rank))
                newPosition.setPiece(ChessPiece(color: move.color, type: .rook), at: Square(file: 3, rank: rank))
            }
        }

        // Update castling rights
        if move.piece.type == .king {
            if move.color == .white {
                newPosition.castlingRights.whiteKingside = false
                newPosition.castlingRights.whiteQueenside = false
            } else {
                newPosition.castlingRights.blackKingside = false
                newPosition.castlingRights.blackQueenside = false
            }
        }
        if move.piece.type == .rook {
            if move.from == Square(file: 0, rank: 0) { newPosition.castlingRights.whiteQueenside = false }
            if move.from == Square(file: 7, rank: 0) { newPosition.castlingRights.whiteKingside = false }
            if move.from == Square(file: 0, rank: 7) { newPosition.castlingRights.blackQueenside = false }
            if move.from == Square(file: 7, rank: 7) { newPosition.castlingRights.blackKingside = false }
        }

        // Update en passant target
        if move.piece.type == .pawn && abs(move.to.rank - move.from.rank) == 2 {
            let epRank = (move.from.rank + move.to.rank) / 2
            newPosition.enPassantTarget = Square(file: move.to.file, rank: epRank)
        } else {
            newPosition.enPassantTarget = nil
        }

        // Update clocks
        if move.piece.type == .pawn || move.captured != nil {
            newPosition.halfmoveClock = 0
        } else {
            newPosition.halfmoveClock = halfmoveClock + 1
        }
        if move.color == .black {
            newPosition.fullmoveNumber = fullmoveNumber + 1
        }

        newPosition.activeColor = activeColor.opposite
        return newPosition
    }
}
