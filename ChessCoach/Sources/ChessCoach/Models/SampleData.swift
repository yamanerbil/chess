import Foundation

/// Provides sample game data for previews and testing
enum SampleData {

    /// A sample Ruy Lopez game: 1.e4 e5 2.Nf3 Nc6 3.Bb5 a6 4.Ba4 Nf6 5.O-O Be7
    /// 6.Re1 b5 7.Bb3 d6 8.c3 O-O 9.h3 Nb8 10.d4 Nbd7 11.Nbd2 Bb7 12.Bc2 Re8
    /// 13.Nf1 Bf8 14.Ng3
    static let sampleGame: Game = {
        var positions: [BoardPosition] = [.initial]
        var moves: [ChessMove] = []
        var pos = BoardPosition.initial

        // Helper to add a move and track position
        func addMove(
            san: String,
            from: Square, to: Square,
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
            let move = ChessMove(
                san: san, from: from, to: to, piece: piece,
                captured: captured, promotion: promotion,
                isCastle: isCastle, isCheck: isCheck,
                isCheckmate: isCheckmate, isEnPassant: isEnPassant,
                moveNumber: moveNumber, color: color
            )
            moves.append(move)
            pos = pos.applyingMove(move)
            positions.append(pos)
        }

        let W = PieceColor.white
        let B = PieceColor.black

        // 1. e4
        addMove(san: "e4", from: Square(file: 4, rank: 1), to: Square(file: 4, rank: 3),
                piece: ChessPiece(color: W, type: .pawn), moveNumber: 1, color: W)
        // 1... e5
        addMove(san: "e5", from: Square(file: 4, rank: 6), to: Square(file: 4, rank: 4),
                piece: ChessPiece(color: B, type: .pawn), moveNumber: 1, color: B)
        // 2. Nf3
        addMove(san: "Nf3", from: Square(file: 6, rank: 0), to: Square(file: 5, rank: 2),
                piece: ChessPiece(color: W, type: .knight), moveNumber: 2, color: W)
        // 2... Nc6
        addMove(san: "Nc6", from: Square(file: 1, rank: 7), to: Square(file: 2, rank: 5),
                piece: ChessPiece(color: B, type: .knight), moveNumber: 2, color: B)
        // 3. Bb5
        addMove(san: "Bb5", from: Square(file: 5, rank: 0), to: Square(file: 1, rank: 4),
                piece: ChessPiece(color: W, type: .bishop), moveNumber: 3, color: W)
        // 3... a6
        addMove(san: "a6", from: Square(file: 0, rank: 6), to: Square(file: 0, rank: 5),
                piece: ChessPiece(color: B, type: .pawn), moveNumber: 3, color: B)
        // 4. Ba4
        addMove(san: "Ba4", from: Square(file: 1, rank: 4), to: Square(file: 0, rank: 3),
                piece: ChessPiece(color: W, type: .bishop), moveNumber: 4, color: W)
        // 4... Nf6
        addMove(san: "Nf6", from: Square(file: 6, rank: 7), to: Square(file: 5, rank: 5),
                piece: ChessPiece(color: B, type: .knight), moveNumber: 4, color: B)
        // 5. O-O
        addMove(san: "O-O", from: Square(file: 4, rank: 0), to: Square(file: 6, rank: 0),
                piece: ChessPiece(color: W, type: .king), isCastle: true, moveNumber: 5, color: W)
        // 5... Be7
        addMove(san: "Be7", from: Square(file: 5, rank: 7), to: Square(file: 4, rank: 6),
                piece: ChessPiece(color: B, type: .bishop), moveNumber: 5, color: B)
        // 6. Re1
        addMove(san: "Re1", from: Square(file: 5, rank: 0), to: Square(file: 4, rank: 0),
                piece: ChessPiece(color: W, type: .rook), moveNumber: 6, color: W)
        // 6... b5
        addMove(san: "b5", from: Square(file: 1, rank: 6), to: Square(file: 1, rank: 4),
                piece: ChessPiece(color: B, type: .pawn), moveNumber: 6, color: B)
        // 7. Bb3
        addMove(san: "Bb3", from: Square(file: 0, rank: 3), to: Square(file: 1, rank: 2),
                piece: ChessPiece(color: W, type: .bishop), moveNumber: 7, color: W)
        // 7... d6
        addMove(san: "d6", from: Square(file: 3, rank: 6), to: Square(file: 3, rank: 5),
                piece: ChessPiece(color: B, type: .pawn), moveNumber: 7, color: B)
        // 8. c3
        addMove(san: "c3", from: Square(file: 2, rank: 1), to: Square(file: 2, rank: 2),
                piece: ChessPiece(color: W, type: .pawn), moveNumber: 8, color: W)
        // 8... O-O
        addMove(san: "O-O", from: Square(file: 4, rank: 7), to: Square(file: 6, rank: 7),
                piece: ChessPiece(color: B, type: .king), isCastle: true, moveNumber: 8, color: B)
        // 9. h3
        addMove(san: "h3", from: Square(file: 7, rank: 1), to: Square(file: 7, rank: 2),
                piece: ChessPiece(color: W, type: .pawn), moveNumber: 9, color: W)
        // 9... Nb8
        addMove(san: "Nb8", from: Square(file: 2, rank: 5), to: Square(file: 1, rank: 7),
                piece: ChessPiece(color: B, type: .knight), moveNumber: 9, color: B)
        // 10. d4
        addMove(san: "d4", from: Square(file: 3, rank: 1), to: Square(file: 3, rank: 3),
                piece: ChessPiece(color: W, type: .pawn), moveNumber: 10, color: W)
        // 10... Nbd7
        addMove(san: "Nbd7", from: Square(file: 1, rank: 7), to: Square(file: 3, rank: 6),
                piece: ChessPiece(color: B, type: .knight), moveNumber: 10, color: B)
        // 11. Nbd2
        addMove(san: "Nbd2", from: Square(file: 1, rank: 0), to: Square(file: 3, rank: 1),
                piece: ChessPiece(color: W, type: .knight), moveNumber: 11, color: W)
        // 11... Bb7
        addMove(san: "Bb7", from: Square(file: 2, rank: 7), to: Square(file: 1, rank: 6),
                piece: ChessPiece(color: B, type: .bishop), moveNumber: 11, color: B)
        // 12. Bc2
        addMove(san: "Bc2", from: Square(file: 1, rank: 2), to: Square(file: 2, rank: 1),
                piece: ChessPiece(color: W, type: .bishop), moveNumber: 12, color: W)
        // 12... Re8
        addMove(san: "Re8", from: Square(file: 5, rank: 7), to: Square(file: 4, rank: 7),
                piece: ChessPiece(color: B, type: .rook), moveNumber: 12, color: B)
        // 13. Nf1
        addMove(san: "Nf1", from: Square(file: 3, rank: 1), to: Square(file: 5, rank: 0),
                piece: ChessPiece(color: W, type: .knight), moveNumber: 13, color: W)
        // 13... Bf8
        addMove(san: "Bf8", from: Square(file: 4, rank: 6), to: Square(file: 5, rank: 7),
                piece: ChessPiece(color: B, type: .bishop), moveNumber: 13, color: B)
        // 14. Ng3
        addMove(san: "Ng3", from: Square(file: 5, rank: 0), to: Square(file: 6, rank: 2),
                piece: ChessPiece(color: W, type: .knight), moveNumber: 14, color: W)

        // Sample annotations
        var annotations: [Int: MoveAnnotation] = [:]

        // 1. e4 - Great
        annotations[0] = MoveAnnotation(
            classification: .great, explanation: "Perfect start! Controlling the center with your pawn.",
            evalAfter: 0.2)
        // 1... e5 - Great
        annotations[1] = MoveAnnotation(
            classification: .great, explanation: "Fighting for the center right away — nice!",
            evalAfter: 0.2)
        // 2. Nf3 - Great
        annotations[2] = MoveAnnotation(
            classification: .great, explanation: "Developing your knight and attacking the e5 pawn.",
            evalAfter: 0.3)
        // 2... Nc6 - Great
        annotations[3] = MoveAnnotation(
            classification: .great, explanation: "Defending the e5 pawn while developing — great move!",
            evalAfter: 0.3)
        // 3. Bb5 - Great (Ruy Lopez)
        annotations[4] = MoveAnnotation(
            classification: .great, explanation: "The Ruy Lopez! One of the most classic openings.",
            evalAfter: 0.3)
        // 3... a6 - Good (Morphy Defense)
        annotations[5] = MoveAnnotation(
            classification: .good,
            explanation: "The Morphy Defense — asking the bishop what it wants to do.",
            bestMove: "a6", evalAfter: 0.25)
        // 4. Ba4 - Great
        annotations[6] = MoveAnnotation(
            classification: .great, explanation: "Keeping the pin on the knight. Good choice!",
            evalAfter: 0.3)
        // 4... Nf6 - Great
        annotations[7] = MoveAnnotation(
            classification: .great, explanation: "Developing and putting pressure on e4.",
            evalAfter: 0.2)
        // 5. O-O - Great
        annotations[8] = MoveAnnotation(
            classification: .great,
            explanation: "Castling early to keep your king safe. Excellent!",
            evalAfter: 0.3)
        // 5... Be7 - Great
        annotations[9] = MoveAnnotation(
            classification: .great, explanation: "Getting ready to castle yourself. Solid play!",
            evalAfter: 0.25)
        // 6. Re1 - Great
        annotations[10] = MoveAnnotation(
            classification: .great, explanation: "Supporting the e4 pawn with your rook. Strong!",
            evalAfter: 0.35)
        // 6... b5 - Inaccuracy
        annotations[11] = MoveAnnotation(
            classification: .inaccuracy,
            explanation: "This pushes the bishop back but weakens your queenside pawns a little. Castling first (O-O) was safer.",
            bestMove: "O-O", evalAfter: 0.55)
        // 7. Bb3 - Great
        annotations[12] = MoveAnnotation(
            classification: .great, explanation: "Retreating the bishop to a good diagonal aimed at f7.",
            evalAfter: 0.5)
        // 7... d6 - Great
        annotations[13] = MoveAnnotation(
            classification: .great, explanation: "Solid — supporting e5 and giving your bishop room.",
            evalAfter: 0.45)
        // 8. c3 - Good
        annotations[14] = MoveAnnotation(
            classification: .good, explanation: "Preparing d4 to take over the center.",
            evalAfter: 0.4)
        // 8... O-O - Great
        annotations[15] = MoveAnnotation(
            classification: .great, explanation: "Getting your king safe — well done!",
            evalAfter: 0.35)
        // 9. h3 - Good
        annotations[16] = MoveAnnotation(
            classification: .good,
            explanation: "Preventing any pins on g4. A useful waiting move.",
            evalAfter: 0.35)
        // 9... Nb8 - Mistake
        annotations[17] = MoveAnnotation(
            classification: .mistake,
            explanation: "Moving your knight backwards loses time. Better to reroute with Na5 to challenge the bishop, or play Bb7.",
            bestMove: "Na5", evalAfter: 0.7)
        // 10. d4 - Great
        annotations[18] = MoveAnnotation(
            classification: .great,
            explanation: "Now you grab the center! White has a strong position.",
            evalAfter: 0.8)
        // 10... Nbd7 - Good
        annotations[19] = MoveAnnotation(
            classification: .good,
            explanation: "Bringing the knight back into the game — but you lost some time.",
            evalAfter: 0.7)
        // 11. Nbd2 - Great
        annotations[20] = MoveAnnotation(
            classification: .great, explanation: "Rerouting the knight toward better squares.",
            evalAfter: 0.75)
        // 11... Bb7 - Good
        annotations[21] = MoveAnnotation(
            classification: .good, explanation: "Developing the bishop to a nice long diagonal.",
            evalAfter: 0.65)
        // 12. Bc2 - Great
        annotations[22] = MoveAnnotation(
            classification: .great,
            explanation: "Pointing the bishop at the kingside — setting up an attack!",
            evalAfter: 0.8)
        // 12... Re8 - Good
        annotations[23] = MoveAnnotation(
            classification: .good, explanation: "Getting your rook to the open e-file. Solid!",
            evalAfter: 0.7)
        // 13. Nf1 - Great
        annotations[24] = MoveAnnotation(
            classification: .great,
            explanation: "The famous Breyer maneuver — this knight is headed to g3!",
            evalAfter: 0.85)
        // 13... Bf8 - Good
        annotations[25] = MoveAnnotation(
            classification: .good,
            explanation: "Flexible — keeping the bishop ready to redeploy.",
            evalAfter: 0.75)
        // 14. Ng3 - Brilliant!
        annotations[26] = MoveAnnotation(
            classification: .brilliant,
            explanation: "The knight completes its journey to g3 — perfectly positioned to launch a kingside attack! From here it eyes f5 and h5.",
            bestMove: "Ng3",
            evalAfter: 1.3,
            engineLines: ["14...g6 15.Nh5 Bg7 16.Bg5", "14...Nb6 15.Nf5 Na4 16.Rb1"])

        return Game(
            white: "You",
            black: "Emma W.",
            event: "Spring Open",
            round: "3",
            date: Date(),
            result: .whiteWins,
            opening: "Ruy Lopez, Morphy Defense",
            playerColor: .white,
            moves: moves,
            annotations: annotations,
            positions: positions
        )
    }()

    // MARK: - Additional sample games for Home screen

    static let sampleGame2: Game = {
        // A shorter Sicilian game where the player (Black) lost
        var positions: [BoardPosition] = [.initial]
        var moves: [ChessMove] = []
        var pos = BoardPosition.initial

        func addMove(
            san: String, from: Square, to: Square, piece: ChessPiece,
            captured: ChessPiece? = nil, isCastle: Bool = false,
            moveNumber: Int, color: PieceColor
        ) {
            let move = ChessMove(
                san: san, from: from, to: to, piece: piece,
                captured: captured, isCastle: isCastle,
                moveNumber: moveNumber, color: color
            )
            moves.append(move)
            pos = pos.applyingMove(move)
            positions.append(pos)
        }

        let W = PieceColor.white
        let B = PieceColor.black

        // 1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6
        addMove(san: "e4", from: Square(file: 4, rank: 1), to: Square(file: 4, rank: 3),
                piece: ChessPiece(color: W, type: .pawn), moveNumber: 1, color: W)
        addMove(san: "c5", from: Square(file: 2, rank: 6), to: Square(file: 2, rank: 4),
                piece: ChessPiece(color: B, type: .pawn), moveNumber: 1, color: B)
        addMove(san: "Nf3", from: Square(file: 6, rank: 0), to: Square(file: 5, rank: 2),
                piece: ChessPiece(color: W, type: .knight), moveNumber: 2, color: W)
        addMove(san: "d6", from: Square(file: 3, rank: 6), to: Square(file: 3, rank: 5),
                piece: ChessPiece(color: B, type: .pawn), moveNumber: 2, color: B)
        addMove(san: "d4", from: Square(file: 3, rank: 1), to: Square(file: 3, rank: 3),
                piece: ChessPiece(color: W, type: .pawn), moveNumber: 3, color: W)
        addMove(san: "cxd4", from: Square(file: 2, rank: 4), to: Square(file: 3, rank: 3),
                piece: ChessPiece(color: B, type: .pawn),
                captured: ChessPiece(color: W, type: .pawn), moveNumber: 3, color: B)
        addMove(san: "Nxd4", from: Square(file: 5, rank: 2), to: Square(file: 3, rank: 3),
                piece: ChessPiece(color: W, type: .knight),
                captured: ChessPiece(color: B, type: .pawn), moveNumber: 4, color: W)
        addMove(san: "Nf6", from: Square(file: 6, rank: 7), to: Square(file: 5, rank: 5),
                piece: ChessPiece(color: B, type: .knight), moveNumber: 4, color: B)
        addMove(san: "Nc3", from: Square(file: 1, rank: 0), to: Square(file: 2, rank: 2),
                piece: ChessPiece(color: W, type: .knight), moveNumber: 5, color: W)
        addMove(san: "a6", from: Square(file: 0, rank: 6), to: Square(file: 0, rank: 5),
                piece: ChessPiece(color: B, type: .pawn), moveNumber: 5, color: B)

        var annotations: [Int: MoveAnnotation] = [:]
        annotations[0] = MoveAnnotation(classification: .great, explanation: "Standard opening move.", evalAfter: 0.3)
        annotations[1] = MoveAnnotation(classification: .great, explanation: "The Sicilian Defense — fighting for the center asymmetrically!", evalAfter: 0.3)
        annotations[2] = MoveAnnotation(classification: .great, explanation: "Developing the knight naturally.", evalAfter: 0.3)
        annotations[3] = MoveAnnotation(classification: .good, explanation: "Preparing to support e5 later.", evalAfter: 0.35)
        annotations[4] = MoveAnnotation(classification: .great, explanation: "Opening the center.", evalAfter: 0.4)
        annotations[5] = MoveAnnotation(classification: .great, explanation: "Good exchange — you open the c-file for your rook later.", evalAfter: 0.3)
        annotations[6] = MoveAnnotation(classification: .great, explanation: "Recapturing with the knight in the center.", evalAfter: 0.4)
        annotations[7] = MoveAnnotation(classification: .great, explanation: "Developing and attacking e4.", evalAfter: 0.3)
        annotations[8] = MoveAnnotation(classification: .great, explanation: "Developing another piece.", evalAfter: 0.35)
        annotations[9] = MoveAnnotation(classification: .inaccuracy,
                                        explanation: "a6 is playable but e5 was more active here, fighting for the center right away.",
                                        bestMove: "e5", evalAfter: 0.5)

        let cal = Calendar.current
        let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: Date())

        return Game(
            white: "Jake M.",
            black: "You",
            event: "Spring Open",
            round: "2",
            date: twoDaysAgo,
            result: .whiteWins,
            opening: "Sicilian, Najdorf",
            playerColor: .black,
            moves: moves,
            annotations: annotations,
            positions: positions
        )
    }()

    static let sampleGame3: Game = {
        // A short Italian Game draw
        var positions: [BoardPosition] = [.initial]
        var moves: [ChessMove] = []
        var pos = BoardPosition.initial

        func addMove(
            san: String, from: Square, to: Square, piece: ChessPiece,
            captured: ChessPiece? = nil, isCastle: Bool = false,
            moveNumber: Int, color: PieceColor
        ) {
            let move = ChessMove(
                san: san, from: from, to: to, piece: piece,
                captured: captured, isCastle: isCastle,
                moveNumber: moveNumber, color: color
            )
            moves.append(move)
            pos = pos.applyingMove(move)
            positions.append(pos)
        }

        let W = PieceColor.white
        let B = PieceColor.black

        // 1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 4. c3 Nf6 5. d4 exd4 6. cxd4 Bb4+
        addMove(san: "e4", from: Square(file: 4, rank: 1), to: Square(file: 4, rank: 3),
                piece: ChessPiece(color: W, type: .pawn), moveNumber: 1, color: W)
        addMove(san: "e5", from: Square(file: 4, rank: 6), to: Square(file: 4, rank: 4),
                piece: ChessPiece(color: B, type: .pawn), moveNumber: 1, color: B)
        addMove(san: "Nf3", from: Square(file: 6, rank: 0), to: Square(file: 5, rank: 2),
                piece: ChessPiece(color: W, type: .knight), moveNumber: 2, color: W)
        addMove(san: "Nc6", from: Square(file: 1, rank: 7), to: Square(file: 2, rank: 5),
                piece: ChessPiece(color: B, type: .knight), moveNumber: 2, color: B)
        addMove(san: "Bc4", from: Square(file: 5, rank: 0), to: Square(file: 2, rank: 3),
                piece: ChessPiece(color: W, type: .bishop), moveNumber: 3, color: W)
        addMove(san: "Bc5", from: Square(file: 5, rank: 7), to: Square(file: 2, rank: 4),
                piece: ChessPiece(color: B, type: .bishop), moveNumber: 3, color: B)
        addMove(san: "c3", from: Square(file: 2, rank: 1), to: Square(file: 2, rank: 2),
                piece: ChessPiece(color: W, type: .pawn), moveNumber: 4, color: W)
        addMove(san: "Nf6", from: Square(file: 6, rank: 7), to: Square(file: 5, rank: 5),
                piece: ChessPiece(color: B, type: .knight), moveNumber: 4, color: B)

        var annotations: [Int: MoveAnnotation] = [:]
        annotations[0] = MoveAnnotation(classification: .great, explanation: "Classic center control.", evalAfter: 0.2)
        annotations[1] = MoveAnnotation(classification: .great, explanation: "Matching in the center.", evalAfter: 0.2)
        annotations[2] = MoveAnnotation(classification: .great, explanation: "Knight development.", evalAfter: 0.3)
        annotations[3] = MoveAnnotation(classification: .great, explanation: "Defending e5.", evalAfter: 0.3)
        annotations[4] = MoveAnnotation(classification: .great, explanation: "The Italian Game! Targeting f7.", evalAfter: 0.3)
        annotations[5] = MoveAnnotation(classification: .great, explanation: "Mirror development — solid!", evalAfter: 0.2)
        annotations[6] = MoveAnnotation(classification: .good, explanation: "Preparing d4.", evalAfter: 0.25)
        annotations[7] = MoveAnnotation(classification: .great, explanation: "Attacking e4 while developing.", evalAfter: 0.2)

        let cal = Calendar.current
        let oneWeekAgo = cal.date(byAdding: .day, value: -7, to: Date())

        return Game(
            white: "You",
            black: "Sofia R.",
            event: "State Championship",
            round: "1",
            date: oneWeekAgo,
            result: .draw,
            opening: "Italian Game",
            playerColor: .white,
            moves: moves,
            annotations: annotations,
            positions: positions
        )
    }()

    static let sampleGame4: Game = {
        // A Queen's Gambit game where the player won as Black
        var positions: [BoardPosition] = [.initial]
        var moves: [ChessMove] = []
        var pos = BoardPosition.initial

        func addMove(
            san: String, from: Square, to: Square, piece: ChessPiece,
            captured: ChessPiece? = nil, isCastle: Bool = false,
            moveNumber: Int, color: PieceColor
        ) {
            let move = ChessMove(
                san: san, from: from, to: to, piece: piece,
                captured: captured, isCastle: isCastle,
                moveNumber: moveNumber, color: color
            )
            moves.append(move)
            pos = pos.applyingMove(move)
            positions.append(pos)
        }

        let W = PieceColor.white
        let B = PieceColor.black

        // 1. d4 d5 2. c4 e6 3. Nc3 Nf6 4. Bg5 Be7 5. Nf3 O-O
        addMove(san: "d4", from: Square(file: 3, rank: 1), to: Square(file: 3, rank: 3),
                piece: ChessPiece(color: W, type: .pawn), moveNumber: 1, color: W)
        addMove(san: "d5", from: Square(file: 3, rank: 6), to: Square(file: 3, rank: 4),
                piece: ChessPiece(color: B, type: .pawn), moveNumber: 1, color: B)
        addMove(san: "c4", from: Square(file: 2, rank: 1), to: Square(file: 2, rank: 3),
                piece: ChessPiece(color: W, type: .pawn), moveNumber: 2, color: W)
        addMove(san: "e6", from: Square(file: 4, rank: 6), to: Square(file: 4, rank: 5),
                piece: ChessPiece(color: B, type: .pawn), moveNumber: 2, color: B)
        addMove(san: "Nc3", from: Square(file: 1, rank: 0), to: Square(file: 2, rank: 2),
                piece: ChessPiece(color: W, type: .knight), moveNumber: 3, color: W)
        addMove(san: "Nf6", from: Square(file: 6, rank: 7), to: Square(file: 5, rank: 5),
                piece: ChessPiece(color: B, type: .knight), moveNumber: 3, color: B)
        addMove(san: "Bg5", from: Square(file: 2, rank: 0), to: Square(file: 6, rank: 4),
                piece: ChessPiece(color: W, type: .bishop), moveNumber: 4, color: W)
        addMove(san: "Be7", from: Square(file: 5, rank: 7), to: Square(file: 4, rank: 6),
                piece: ChessPiece(color: B, type: .bishop), moveNumber: 4, color: B)
        addMove(san: "Nf3", from: Square(file: 6, rank: 0), to: Square(file: 5, rank: 2),
                piece: ChessPiece(color: W, type: .knight), moveNumber: 5, color: W)
        addMove(san: "O-O", from: Square(file: 4, rank: 7), to: Square(file: 6, rank: 7),
                piece: ChessPiece(color: B, type: .king), isCastle: true, moveNumber: 5, color: B)

        var annotations: [Int: MoveAnnotation] = [:]
        annotations[0] = MoveAnnotation(classification: .great, explanation: "Controlling the center with d4.", evalAfter: 0.2)
        annotations[1] = MoveAnnotation(classification: .great, explanation: "Meeting d4 with d5 — solid!", evalAfter: 0.2)
        annotations[2] = MoveAnnotation(classification: .great, explanation: "The Queen's Gambit!", evalAfter: 0.3)
        annotations[3] = MoveAnnotation(classification: .great, explanation: "The Queen's Gambit Declined — very solid choice.", evalAfter: 0.25)
        annotations[4] = MoveAnnotation(classification: .great, explanation: "Developing the knight.", evalAfter: 0.3)
        annotations[5] = MoveAnnotation(classification: .great, explanation: "Natural development.", evalAfter: 0.25)
        annotations[6] = MoveAnnotation(classification: .good, explanation: "Pinning the knight.", evalAfter: 0.3)
        annotations[7] = MoveAnnotation(classification: .great, explanation: "Breaking the pin and preparing to castle.", evalAfter: 0.2)
        annotations[8] = MoveAnnotation(classification: .great, explanation: "Developing the last minor piece.", evalAfter: 0.25)
        annotations[9] = MoveAnnotation(classification: .brilliant,
                                        explanation: "Castling at just the right moment! Your king is safe and your rook joins the fight.",
                                        evalAfter: 0.1)

        let cal = Calendar.current
        let oneWeekAgo = cal.date(byAdding: .day, value: -8, to: Date())

        return Game(
            white: "Liam T.",
            black: "You",
            event: "State Championship",
            round: "2",
            date: oneWeekAgo,
            result: .blackWins,
            opening: "Queen's Gambit Declined",
            playerColor: .black,
            moves: moves,
            annotations: annotations,
            positions: positions
        )
    }()

    /// All sample games for the Home screen
    static let allGames: [Game] = [sampleGame, sampleGame2, sampleGame3, sampleGame4]

    /// Unique tournament names from sample data
    static let tournaments: [String] = {
        let events = allGames.compactMap { $0.event }
        return Array(Set(events)).sorted()
    }()
}
