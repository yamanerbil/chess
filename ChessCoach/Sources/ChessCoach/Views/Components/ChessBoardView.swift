import SwiftUI

/// The main chess board rendering view
struct ChessBoardView: View {
    let position: BoardPosition
    let playerColor: PieceColor
    let lastMoveFrom: Square?
    let lastMoveTo: Square?
    var showCoordinates: Bool = true

    /// Whether the board is flipped (showing from black's perspective)
    private var isFlipped: Bool {
        playerColor == .black
    }

    var body: some View {
        GeometryReader { geometry in
            let boardSize = min(geometry.size.width, geometry.size.height)
            let squareSize = boardSize / 8

            VStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { col in
                            let file = isFlipped ? (7 - col) : col
                            let rank = isFlipped ? row : (7 - row)
                            let square = Square(file: file, rank: rank)

                            squareView(
                                square: square,
                                size: squareSize,
                                row: row,
                                col: col
                            )
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(width: boardSize, height: boardSize)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func squareView(square: Square, size: CGFloat, row: Int, col: Int) -> some View {
        let isLight = square.isLight
        let isHighlighted = square == lastMoveFrom || square == lastMoveTo
        let piece = position.piece(at: square)

        ZStack {
            // Square color
            Rectangle()
                .fill(squareColor(isLight: isLight, isHighlighted: isHighlighted))

            // Piece
            if let piece = piece {
                pieceView(piece: piece, size: size)
            }

            // Coordinate labels embedded in squares
            if showCoordinates {
                // File label on bottom row
                if row == 7 {
                    let file = isFlipped ? (7 - col) : col
                    let fileChar = String(Character(UnicodeScalar(97 + file)!))
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(fileChar)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(isLight ? DesignSystem.Colors.boardDark : DesignSystem.Colors.boardLight)
                                .padding(2)
                        }
                    }
                }
                // Rank label on left column
                if col == 0 {
                    let rank = isFlipped ? row : (7 - row)
                    VStack {
                        HStack {
                            Text("\(rank + 1)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(isLight ? DesignSystem.Colors.boardDark : DesignSystem.Colors.boardLight)
                                .padding(2)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }

    private func squareColor(isLight: Bool, isHighlighted: Bool) -> Color {
        if isHighlighted {
            return isLight
                ? DesignSystem.Colors.lastMoveHighlightLight
                : DesignSystem.Colors.lastMoveHighlightDark
        }
        return isLight ? DesignSystem.Colors.boardLight : DesignSystem.Colors.boardDark
    }

    @ViewBuilder
    private func pieceView(piece: ChessPiece, size: CGFloat) -> some View {
        Text(piece.symbol)
            .font(.system(size: size * 0.75))
            .minimumScaleFactor(0.5)
            .shadow(color: .black.opacity(0.3), radius: 1, x: 0.5, y: 0.5)
    }
}

#Preview {
    ChessBoardView(
        position: .initial,
        playerColor: .white,
        lastMoveFrom: nil,
        lastMoveTo: nil
    )
    .padding()
}
