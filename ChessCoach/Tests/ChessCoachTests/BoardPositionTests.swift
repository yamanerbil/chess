import Testing
@testable import ChessCoach

@Suite("BoardPosition Tests")
struct BoardPositionTests {

    @Test("Initial position has correct piece placement")
    func initialPosition() {
        let pos = BoardPosition.initial

        // White pieces on rank 1
        #expect(pos.piece(at: Square(file: 0, rank: 0))?.type == .rook)
        #expect(pos.piece(at: Square(file: 0, rank: 0))?.color == .white)
        #expect(pos.piece(at: Square(file: 1, rank: 0))?.type == .knight)
        #expect(pos.piece(at: Square(file: 4, rank: 0))?.type == .king)
        #expect(pos.piece(at: Square(file: 3, rank: 0))?.type == .queen)

        // White pawns on rank 2
        for file in 0..<8 {
            #expect(pos.piece(at: Square(file: file, rank: 1))?.type == .pawn)
            #expect(pos.piece(at: Square(file: file, rank: 1))?.color == .white)
        }

        // Empty squares in middle
        for rank in 2..<6 {
            for file in 0..<8 {
                #expect(pos.piece(at: Square(file: file, rank: rank)) == nil)
            }
        }

        // Black pawns on rank 7
        for file in 0..<8 {
            #expect(pos.piece(at: Square(file: file, rank: 6))?.type == .pawn)
            #expect(pos.piece(at: Square(file: file, rank: 6))?.color == .black)
        }

        // Black pieces on rank 8
        #expect(pos.piece(at: Square(file: 4, rank: 7))?.type == .king)
        #expect(pos.piece(at: Square(file: 4, rank: 7))?.color == .black)

        #expect(pos.activeColor == .white)
    }

    @Test("FEN parsing works for starting position")
    func fenStartingPosition() {
        let fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        let pos = BoardPosition.fromFEN(fen)

        #expect(pos != nil)
        #expect(pos?.activeColor == .white)
        #expect(pos?.castlingRights == .initial)
        #expect(pos?.piece(at: Square(file: 4, rank: 0))?.type == .king)
        #expect(pos?.piece(at: Square(file: 4, rank: 0))?.color == .white)
    }

    @Test("FEN parsing works for a mid-game position")
    func fenMidGame() {
        let fen = "r1bqkb1r/pppppppp/2n2n2/8/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3"
        let pos = BoardPosition.fromFEN(fen)

        #expect(pos != nil)
        #expect(pos?.piece(at: Square(file: 4, rank: 3))?.type == .pawn) // e4
        #expect(pos?.piece(at: Square(file: 5, rank: 2))?.type == .knight) // Nf3
        #expect(pos?.piece(at: Square(file: 2, rank: 5))?.type == .knight) // Nc6
        #expect(pos?.piece(at: Square(file: 5, rank: 5))?.type == .knight) // Nf6
        #expect(pos?.halfmoveClock == 2)
        #expect(pos?.fullmoveNumber == 3)
    }

    @Test("Applying e4 move updates position correctly")
    func applyE4() {
        let pos = BoardPosition.initial
        let move = ChessMove(
            san: "e4",
            from: Square(file: 4, rank: 1),
            to: Square(file: 4, rank: 3),
            piece: ChessPiece(color: .white, type: .pawn),
            moveNumber: 1,
            color: .white
        )

        let newPos = pos.applyingMove(move)
        #expect(newPos.piece(at: Square(file: 4, rank: 1)) == nil) // e2 empty
        #expect(newPos.piece(at: Square(file: 4, rank: 3))?.type == .pawn) // e4 has pawn
        #expect(newPos.activeColor == .black)
        #expect(newPos.enPassantTarget == Square(file: 4, rank: 2)) // e3 en passant
    }

    @Test("Kingside castling moves rook correctly")
    func kingsideCastle() {
        let fen = "r1bqk2r/ppppbppp/2n2n2/4p3/4P3/5N2/PPPPBPPP/RNBQK2R w KQkq - 4 4"
        guard let pos = BoardPosition.fromFEN(fen) else {
            Issue.record("Failed to parse FEN")
            return
        }

        let move = ChessMove(
            san: "O-O",
            from: Square(file: 4, rank: 0),
            to: Square(file: 6, rank: 0),
            piece: ChessPiece(color: .white, type: .king),
            isCastle: true,
            moveNumber: 4,
            color: .white
        )

        let newPos = pos.applyingMove(move)
        #expect(newPos.piece(at: Square(file: 6, rank: 0))?.type == .king) // King on g1
        #expect(newPos.piece(at: Square(file: 5, rank: 0))?.type == .rook) // Rook on f1
        #expect(newPos.piece(at: Square(file: 4, rank: 0)) == nil) // e1 empty
        #expect(newPos.piece(at: Square(file: 7, rank: 0)) == nil) // h1 empty
        #expect(newPos.castlingRights.whiteKingside == false)
        #expect(newPos.castlingRights.whiteQueenside == false)
    }

    @Test("Sample game has correct number of positions")
    func sampleGamePositions() {
        let game = SampleData.sampleGame
        #expect(game.moves.count == 27) // 14 white moves + 13 black moves
        #expect(game.positions.count == 28) // initial + 27 moves
        #expect(game.positions[0] == BoardPosition.initial)
    }
}

@Suite("Square Tests")
struct SquareTests {

    @Test("Square algebraic notation")
    func notation() {
        #expect(Square(file: 0, rank: 0).notation == "a1")
        #expect(Square(file: 4, rank: 3).notation == "e4")
        #expect(Square(file: 7, rank: 7).notation == "h8")
    }

    @Test("Square from notation")
    func fromNotation() {
        #expect(Square("e4") == Square(file: 4, rank: 3))
        #expect(Square("a1") == Square(file: 0, rank: 0))
        #expect(Square("h8") == Square(file: 7, rank: 7))
        #expect(Square("z9") == nil)
    }

    @Test("Square light/dark detection")
    func lightDark() {
        // a1 is dark (file 0 + rank 0 = even)
        #expect(Square(file: 0, rank: 0).isLight == false)
        // b1 is light
        #expect(Square(file: 1, rank: 0).isLight == true)
        // h1 is light
        #expect(Square(file: 7, rank: 0).isLight == true)
    }
}

@Suite("ChessPiece Tests")
struct ChessPieceTests {

    @Test("FEN character parsing")
    func fenParsing() {
        let whiteKing = ChessPiece(fenChar: "K")
        #expect(whiteKing?.color == .white)
        #expect(whiteKing?.type == .king)

        let blackPawn = ChessPiece(fenChar: "p")
        #expect(blackPawn?.color == .black)
        #expect(blackPawn?.type == .pawn)

        #expect(ChessPiece(fenChar: "x") == nil)
    }

    @Test("Piece symbols")
    func symbols() {
        let wk = ChessPiece(color: .white, type: .king)
        #expect(wk.symbol == "♔")

        let bn = ChessPiece(color: .black, type: .knight)
        #expect(bn.symbol == "♞")
    }
}
