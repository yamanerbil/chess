import Foundation

/// Represents a chess piece color
enum PieceColor: String, Codable, Equatable {
    case white
    case black

    var opposite: PieceColor {
        self == .white ? .black : .white
    }
}

/// Represents a chess piece type
enum PieceType: String, Codable, Equatable {
    case king
    case queen
    case rook
    case bishop
    case knight
    case pawn

    /// Standard algebraic notation letter (empty for pawn)
    var notation: String {
        switch self {
        case .king: return "K"
        case .queen: return "Q"
        case .rook: return "R"
        case .bishop: return "B"
        case .knight: return "N"
        case .pawn: return ""
        }
    }

    /// Unicode chess piece character for white
    var whiteSymbol: String {
        switch self {
        case .king: return "♔"
        case .queen: return "♕"
        case .rook: return "♖"
        case .bishop: return "♗"
        case .knight: return "♘"
        case .pawn: return "♙"
        }
    }

    /// Unicode chess piece character for black
    var blackSymbol: String {
        switch self {
        case .king: return "♚"
        case .queen: return "♛"
        case .rook: return "♜"
        case .bishop: return "♝"
        case .knight: return "♞"
        case .pawn: return "♟"
        }
    }
}

/// Represents a chess piece with its color and type
struct ChessPiece: Equatable, Codable {
    let color: PieceColor
    let type: PieceType

    var symbol: String {
        color == .white ? type.whiteSymbol : type.blackSymbol
    }

    /// Image asset name following standard naming: "wK", "bQ", etc.
    var imageName: String {
        let colorPrefix = color == .white ? "w" : "b"
        let typeChar: String
        switch type {
        case .king: typeChar = "K"
        case .queen: typeChar = "Q"
        case .rook: typeChar = "R"
        case .bishop: typeChar = "B"
        case .knight: typeChar = "N"
        case .pawn: typeChar = "P"
        }
        return "\(colorPrefix)\(typeChar)"
    }

    /// FEN character representation
    var fenChar: Character {
        let base: Character
        switch type {
        case .king: base = "k"
        case .queen: base = "q"
        case .rook: base = "r"
        case .bishop: base = "b"
        case .knight: base = "n"
        case .pawn: base = "p"
        }
        return color == .white ? Character(base.uppercased()) : base
    }

    init(color: PieceColor, type: PieceType) {
        self.color = color
        self.type = type
    }

    init?(fenChar: Character) {
        let color: PieceColor = fenChar.isUppercase ? .white : .black
        switch fenChar.lowercased() {
        case "k": self.init(color: color, type: .king)
        case "q": self.init(color: color, type: .queen)
        case "r": self.init(color: color, type: .rook)
        case "b": self.init(color: color, type: .bishop)
        case "n": self.init(color: color, type: .knight)
        case "p": self.init(color: color, type: .pawn)
        default: return nil
        }
    }
}
