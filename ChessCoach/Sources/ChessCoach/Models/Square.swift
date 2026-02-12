import Foundation

/// Represents a square on the chess board (0-63)
struct Square: Hashable, Codable, Equatable {
    /// File index (0 = a, 7 = h)
    let file: Int
    /// Rank index (0 = 1, 7 = 8)
    let rank: Int

    var isValid: Bool {
        file >= 0 && file < 8 && rank >= 0 && rank < 8
    }

    /// Algebraic notation, e.g. "e4"
    var notation: String {
        let fileChar = Character(UnicodeScalar(Int(("a" as Character).asciiValue!) + file)!)
        return "\(fileChar)\(rank + 1)"
    }

    /// Whether this is a light square
    var isLight: Bool {
        (file + rank) % 2 != 0
    }

    init(file: Int, rank: Int) {
        self.file = file
        self.rank = rank
    }

    /// Initialize from algebraic notation like "e4"
    init?(_ notation: String) {
        guard notation.count == 2 else { return nil }
        let chars = Array(notation)
        guard let fileAscii = chars[0].asciiValue,
              let rankChar = chars[1].wholeNumberValue else { return nil }
        let file = Int(fileAscii) - Int(("a" as Character).asciiValue!)
        let rank = rankChar - 1
        guard file >= 0, file < 8, rank >= 0, rank < 8 else { return nil }
        self.file = file
        self.rank = rank
    }
}
