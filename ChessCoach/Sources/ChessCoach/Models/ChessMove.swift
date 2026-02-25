import Foundation

extension String {
    /// Strips the leading piece letter (K, Q, R, B, N) from a SAN string.
    /// Pawn moves (e.g. "e4") and castling ("O-O") are returned unchanged.
    func dropPiecePrefix() -> String {
        guard let first = first, "KQRBN".contains(first) else { return self }
        return String(dropFirst())
    }
}

/// Represents a single chess move
struct ChessMove: Identifiable, Equatable, Codable {
    let id: UUID
    /// The standard algebraic notation for this move (e.g. "Nf3", "e4", "O-O")
    let san: String
    /// The starting square
    let from: Square
    /// The destination square
    let to: Square
    /// The piece that moved
    let piece: ChessPiece
    /// Captured piece, if any
    let captured: ChessPiece?
    /// Promotion piece type, if pawn promoted
    let promotion: PieceType?
    /// Whether this move is a castle
    let isCastle: Bool
    /// Whether this move gives check
    let isCheck: Bool
    /// Whether this move gives checkmate
    let isCheckmate: Bool
    /// Whether this is an en passant capture
    let isEnPassant: Bool
    /// Move number (1-based, e.g. move 1 for both 1.e4 and 1...e5)
    let moveNumber: Int
    /// Which color made this move
    let color: PieceColor

    /// SAN text with the leading piece letter removed (for use alongside a piece icon).
    /// Pawn moves and castling are returned unchanged.
    var sanWithoutPiecePrefix: String {
        san.dropPiecePrefix()
    }

    init(
        id: UUID = UUID(),
        san: String,
        from: Square,
        to: Square,
        piece: ChessPiece,
        captured: ChessPiece? = nil,
        promotion: PieceType? = nil,
        isCastle: Bool = false,
        isCheck: Bool = false,
        isCheckmate: Bool = false,
        isEnPassant: Bool = false,
        moveNumber: Int,
        color: PieceColor
    ) {
        self.id = id
        self.san = san
        self.from = from
        self.to = to
        self.piece = piece
        self.captured = captured
        self.promotion = promotion
        self.isCastle = isCastle
        self.isCheck = isCheck
        self.isCheckmate = isCheckmate
        self.isEnPassant = isEnPassant
        self.moveNumber = moveNumber
        self.color = color
    }
}
