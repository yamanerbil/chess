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

    /// Convert this position to a FEN string
    func toFEN() -> String {
        var parts: [String] = []

        // Piece placement (rank 8 to rank 1)
        var placement: [String] = []
        for rank in stride(from: 7, through: 0, by: -1) {
            var rankStr = ""
            var emptyCount = 0
            for file in 0..<8 {
                if let piece = board[rank][file] {
                    if emptyCount > 0 {
                        rankStr += "\(emptyCount)"
                        emptyCount = 0
                    }
                    rankStr += String(piece.fenChar)
                } else {
                    emptyCount += 1
                }
            }
            if emptyCount > 0 { rankStr += "\(emptyCount)" }
            placement.append(rankStr)
        }
        parts.append(placement.joined(separator: "/"))

        // Active color
        parts.append(activeColor == .white ? "w" : "b")

        // Castling
        var castling = ""
        if castlingRights.whiteKingside { castling += "K" }
        if castlingRights.whiteQueenside { castling += "Q" }
        if castlingRights.blackKingside { castling += "k" }
        if castlingRights.blackQueenside { castling += "q" }
        parts.append(castling.isEmpty ? "-" : castling)

        // En passant
        parts.append(enPassantTarget?.notation ?? "-")

        // Halfmove clock and fullmove number
        parts.append("\(halfmoveClock)")
        parts.append("\(fullmoveNumber)")

        return parts.joined(separator: " ")
    }

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

    // MARK: - Legal Move Generation

    /// Find the king square for a given color
    func findKing(_ color: PieceColor) -> Square? {
        for rank in 0..<8 {
            for file in 0..<8 {
                if let p = board[rank][file], p.type == .king, p.color == color {
                    return Square(file: file, rank: rank)
                }
            }
        }
        return nil
    }

    /// Check if a square is attacked by the given color
    func isSquareAttacked(_ square: Square, by attackerColor: PieceColor) -> Bool {
        // Pawn attacks
        let pawnDir = attackerColor == .white ? -1 : 1
        for df in [-1, 1] {
            let s = Square(file: square.file + df, rank: square.rank + pawnDir)
            if s.isValid, let p = piece(at: s), p.color == attackerColor, p.type == .pawn {
                return true
            }
        }

        // Knight attacks
        let knightOffsets = [(-2,-1),(-2,1),(-1,-2),(-1,2),(1,-2),(1,2),(2,-1),(2,1)]
        for (df, dr) in knightOffsets {
            let s = Square(file: square.file + df, rank: square.rank + dr)
            if s.isValid, let p = piece(at: s), p.color == attackerColor, p.type == .knight {
                return true
            }
        }

        // King attacks
        for df in -1...1 {
            for dr in -1...1 {
                if df == 0 && dr == 0 { continue }
                let s = Square(file: square.file + df, rank: square.rank + dr)
                if s.isValid, let p = piece(at: s), p.color == attackerColor, p.type == .king {
                    return true
                }
            }
        }

        // Sliding pieces: rook/queen on ranks and files
        let rookDirs = [(0,1),(0,-1),(1,0),(-1,0)]
        for (df, dr) in rookDirs {
            var f = square.file + df
            var r = square.rank + dr
            while f >= 0 && f < 8 && r >= 0 && r < 8 {
                if let p = board[r][f] {
                    if p.color == attackerColor && (p.type == .rook || p.type == .queen) {
                        return true
                    }
                    break
                }
                f += df
                r += dr
            }
        }

        // Sliding pieces: bishop/queen on diagonals
        let bishopDirs = [(1,1),(1,-1),(-1,1),(-1,-1)]
        for (df, dr) in bishopDirs {
            var f = square.file + df
            var r = square.rank + dr
            while f >= 0 && f < 8 && r >= 0 && r < 8 {
                if let p = board[r][f] {
                    if p.color == attackerColor && (p.type == .bishop || p.type == .queen) {
                        return true
                    }
                    break
                }
                f += df
                r += dr
            }
        }

        return false
    }

    /// Whether the given color's king is in check
    func isInCheck(_ color: PieceColor) -> Bool {
        guard let kingSquare = findKing(color) else { return false }
        return isSquareAttacked(kingSquare, by: color.opposite)
    }

    /// Generate all pseudo-legal moves (ignoring check) for a piece at a square
    private func pseudoLegalMoves(from square: Square) -> [(to: Square, promotion: PieceType?)] {
        guard let piece = piece(at: square), piece.color == activeColor else { return [] }
        var results: [(Square, PieceType?)] = []

        func addIfValid(file: Int, rank: Int) {
            let target = Square(file: file, rank: rank)
            guard target.isValid else { return }
            let dest = self.piece(at: target)
            if dest == nil || dest!.color != piece.color {
                results.append((target, nil))
            }
        }

        func addSliding(directions: [(Int, Int)]) {
            for (df, dr) in directions {
                var f = square.file + df
                var r = square.rank + dr
                while f >= 0 && f < 8 && r >= 0 && r < 8 {
                    let target = Square(file: f, rank: r)
                    if let dest = self.piece(at: target) {
                        if dest.color != piece.color {
                            results.append((target, nil))
                        }
                        break
                    }
                    results.append((target, nil))
                    f += df
                    r += dr
                }
            }
        }

        switch piece.type {
        case .pawn:
            let dir = piece.color == .white ? 1 : -1
            let startRank = piece.color == .white ? 1 : 6
            let promoRank = piece.color == .white ? 7 : 0
            let promoTypes: [PieceType] = [.queen, .rook, .bishop, .knight]

            // Forward one
            let oneStep = Square(file: square.file, rank: square.rank + dir)
            if oneStep.isValid && self.piece(at: oneStep) == nil {
                if oneStep.rank == promoRank {
                    for pt in promoTypes { results.append((oneStep, pt)) }
                } else {
                    results.append((oneStep, nil))
                }
                // Forward two from start
                if square.rank == startRank {
                    let twoStep = Square(file: square.file, rank: square.rank + 2 * dir)
                    if twoStep.isValid && self.piece(at: twoStep) == nil {
                        results.append((twoStep, nil))
                    }
                }
            }

            // Captures
            for df in [-1, 1] {
                let cap = Square(file: square.file + df, rank: square.rank + dir)
                guard cap.isValid else { continue }
                let atCap = self.piece(at: cap)
                let isEP = (enPassantTarget != nil && cap == enPassantTarget)
                if (atCap != nil && atCap!.color != piece.color) || isEP {
                    if cap.rank == promoRank {
                        for pt in promoTypes { results.append((cap, pt)) }
                    } else {
                        results.append((cap, nil))
                    }
                }
            }

        case .knight:
            let offsets = [(-2,-1),(-2,1),(-1,-2),(-1,2),(1,-2),(1,2),(2,-1),(2,1)]
            for (df, dr) in offsets {
                addIfValid(file: square.file + df, rank: square.rank + dr)
            }

        case .bishop:
            addSliding(directions: [(1,1),(1,-1),(-1,1),(-1,-1)])

        case .rook:
            addSliding(directions: [(0,1),(0,-1),(1,0),(-1,0)])

        case .queen:
            addSliding(directions: [(0,1),(0,-1),(1,0),(-1,0),(1,1),(1,-1),(-1,1),(-1,-1)])

        case .king:
            for df in -1...1 {
                for dr in -1...1 {
                    if df == 0 && dr == 0 { continue }
                    addIfValid(file: square.file + df, rank: square.rank + dr)
                }
            }

            // Castling
            let rank = piece.color == .white ? 0 : 7
            if square == Square(file: 4, rank: rank) && !isInCheck(piece.color) {
                // Kingside
                let canKingside = piece.color == .white ? castlingRights.whiteKingside : castlingRights.blackKingside
                if canKingside
                    && self.piece(at: Square(file: 5, rank: rank)) == nil
                    && self.piece(at: Square(file: 6, rank: rank)) == nil
                    && !isSquareAttacked(Square(file: 5, rank: rank), by: piece.color.opposite)
                    && !isSquareAttacked(Square(file: 6, rank: rank), by: piece.color.opposite) {
                    results.append((Square(file: 6, rank: rank), nil))
                }
                // Queenside
                let canQueenside = piece.color == .white ? castlingRights.whiteQueenside : castlingRights.blackQueenside
                if canQueenside
                    && self.piece(at: Square(file: 3, rank: rank)) == nil
                    && self.piece(at: Square(file: 2, rank: rank)) == nil
                    && self.piece(at: Square(file: 1, rank: rank)) == nil
                    && !isSquareAttacked(Square(file: 3, rank: rank), by: piece.color.opposite)
                    && !isSquareAttacked(Square(file: 2, rank: rank), by: piece.color.opposite) {
                    results.append((Square(file: 2, rank: rank), nil))
                }
            }
        }

        return results
    }

    /// Generate all legal moves for the active color, returned as ChessMove objects
    func legalMoves() -> [ChessMove] {
        var moves: [ChessMove] = []

        for rank in 0..<8 {
            for file in 0..<8 {
                let sq = Square(file: file, rank: rank)
                guard let p = piece(at: sq), p.color == activeColor else { continue }

                for (target, promo) in pseudoLegalMoves(from: sq) {
                    let captured = piece(at: target)
                    let isEP = p.type == .pawn && target == enPassantTarget
                    let isCastle = p.type == .king && abs(target.file - sq.file) == 2

                    // Build a temporary move to test legality
                    let testMove = ChessMove(
                        san: "",
                        from: sq, to: target, piece: p,
                        captured: isEP ? ChessPiece(color: activeColor.opposite, type: .pawn) : captured,
                        promotion: promo,
                        isCastle: isCastle,
                        isEnPassant: isEP,
                        moveNumber: fullmoveNumber,
                        color: activeColor
                    )

                    let resultPos = applyingMove(testMove)
                    // The move is legal only if our king is NOT in check after the move
                    if !resultPos.isInCheck(activeColor) {
                        // Generate proper SAN
                        let san = generateSAN(piece: p, from: sq, to: target, captured: captured, isEP: isEP, isCastle: isCastle, promotion: promo, resultPos: resultPos)

                        let isCheck = resultPos.isInCheck(activeColor.opposite)
                        let isCheckmate = isCheck && resultPos.legalMoves().isEmpty

                        let move = ChessMove(
                            san: san,
                            from: sq, to: target, piece: p,
                            captured: isEP ? ChessPiece(color: activeColor.opposite, type: .pawn) : captured,
                            promotion: promo,
                            isCastle: isCastle,
                            isCheck: isCheck,
                            isCheckmate: isCheckmate,
                            isEnPassant: isEP,
                            moveNumber: fullmoveNumber,
                            color: activeColor
                        )
                        moves.append(move)
                    }
                }
            }
        }
        return moves
    }

    /// Generate the SAN string for a move
    private func generateSAN(piece p: ChessPiece, from: Square, to: Square, captured: ChessPiece?, isEP: Bool, isCastle: Bool, promotion: PieceType?, resultPos: BoardPosition) -> String {
        if isCastle {
            return to.file == 6 ? "O-O" : "O-O-O"
        }

        var san = ""
        let isCapture = captured != nil || isEP

        if p.type == .pawn {
            if isCapture {
                san += String(Character(UnicodeScalar(Int(("a" as Character).asciiValue!) + from.file)!))
                san += "x"
            }
            san += to.notation
            if let promo = promotion {
                san += "=\(promo.notation)"
            }
        } else {
            san += p.type.notation

            // Disambiguation: check if other pieces of same type can reach same square
            var sameTypeMoves: [(from: Square, to: Square)] = []
            for rank in 0..<8 {
                for file in 0..<8 {
                    let sq = Square(file: file, rank: rank)
                    if sq == from { continue }
                    guard let other = piece(at: sq), other == p else { continue }
                    for (t, _) in pseudoLegalMoves(from: sq) {
                        if t == to {
                            // Check legality
                            let testMove = ChessMove(san: "", from: sq, to: t, piece: other,
                                                     captured: piece(at: t), moveNumber: fullmoveNumber, color: activeColor)
                            let testPos = applyingMove(testMove)
                            if !testPos.isInCheck(activeColor) {
                                sameTypeMoves.append((sq, t))
                            }
                        }
                    }
                }
            }
            if !sameTypeMoves.isEmpty {
                let sameFile = sameTypeMoves.contains { $0.from.file == from.file }
                let sameRank = sameTypeMoves.contains { $0.from.rank == from.rank }
                if !sameFile {
                    san += String(Character(UnicodeScalar(Int(("a" as Character).asciiValue!) + from.file)!))
                } else if !sameRank {
                    san += "\(from.rank + 1)"
                } else {
                    san += String(Character(UnicodeScalar(Int(("a" as Character).asciiValue!) + from.file)!))
                    san += "\(from.rank + 1)"
                }
            }

            if isCapture { san += "x" }
            san += to.notation
        }

        if resultPos.isInCheck(activeColor.opposite) {
            if resultPos.legalMoves().isEmpty {
                san += "#"
            } else {
                san += "+"
            }
        }

        return san
    }

    /// Get SAN strings for all legal moves from this position
    func legalMoveSANs() -> [String] {
        legalMoves().map { $0.san }
    }

    /// Check if a SAN string represents a legal move in this position
    func isLegalMove(san: String) -> Bool {
        let cleaned = san.replacingOccurrences(of: "+", with: "").replacingOccurrences(of: "#", with: "")
        return legalMoves().contains { move in
            let moveCleaned = move.san.replacingOccurrences(of: "+", with: "").replacingOccurrences(of: "#", with: "")
            return moveCleaned == cleaned
        }
    }

    /// Find the legal move matching a SAN string, if any
    func legalMove(forSAN san: String) -> ChessMove? {
        let cleaned = san.replacingOccurrences(of: "+", with: "").replacingOccurrences(of: "#", with: "")
        return legalMoves().first { move in
            let moveCleaned = move.san.replacingOccurrences(of: "+", with: "").replacingOccurrences(of: "#", with: "")
            return moveCleaned == cleaned
        }
    }

    /// Find legal moves that are visually similar to the given SAN string
    /// Used for suggesting corrections to OCR results
    func similarLegalMoves(to san: String, maxResults: Int = 5) -> [ChessMove] {
        let cleaned = san.replacingOccurrences(of: "+", with: "").replacingOccurrences(of: "#", with: "")
        let allMoves = legalMoves()

        // Score each legal move by similarity to the input
        let scored = allMoves.map { move -> (ChessMove, Int) in
            let moveSAN = move.san.replacingOccurrences(of: "+", with: "").replacingOccurrences(of: "#", with: "")
            let score = sanSimilarity(cleaned, moveSAN)
            return (move, score)
        }

        return scored
            .sorted { $0.1 > $1.1 }
            .prefix(maxResults)
            .map { $0.0 }
    }

    /// Simple character-level similarity score between two SAN strings
    private func sanSimilarity(_ a: String, _ b: String) -> Int {
        let aChars = Array(a)
        let bChars = Array(b)
        var score = 0

        // Bonus for same piece type (first char if uppercase)
        if let af = aChars.first, let bf = bChars.first, af == bf {
            score += 3
        }

        // Bonus for same destination square (last 2 chars typically)
        if a.count >= 2 && b.count >= 2 {
            let aTail = String(a.suffix(2))
            let bTail = String(b.suffix(2))
            if aTail == bTail { score += 4 }
        }

        // Bonus for same length
        if a.count == b.count { score += 1 }

        // Common characters
        let aSet = Set(aChars)
        let bSet = Set(bChars)
        score += aSet.intersection(bSet).count

        // Penalty for edit distance
        let distance = editDistance(a, b)
        score -= distance

        return score
    }

    /// Levenshtein edit distance
    private func editDistance(_ a: String, _ b: String) -> Int {
        let aArr = Array(a)
        let bArr = Array(b)
        let m = aArr.count
        let n = bArr.count
        var dp = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)
        for i in 0...m { dp[i][0] = i }
        for j in 0...n { dp[0][j] = j }
        for i in 1...m {
            for j in 1...n {
                if aArr[i-1] == bArr[j-1] {
                    dp[i][j] = dp[i-1][j-1]
                } else {
                    dp[i][j] = 1 + min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1])
                }
            }
        }
        return dp[m][n]
    }
}
