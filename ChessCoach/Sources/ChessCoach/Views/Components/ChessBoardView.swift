import SwiftUI

/// The main chess board rendering view
struct ChessBoardView: View {
    let position: BoardPosition
    let playerColor: PieceColor
    let lastMoveFrom: Square?
    let lastMoveTo: Square?

    /// Whether the board is flipped (showing from black's perspective)
    private var isFlipped: Bool {
        playerColor == .black
    }

    var body: some View {
        GeometryReader { geometry in
            let boardSize = min(geometry.size.width, geometry.size.height)
            let coordWidth: CGFloat = 18
            let effectiveBoardSize = boardSize - coordWidth
            let squareSize = effectiveBoardSize / 8

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    // Left coordinate labels (ranks)
                    VStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { row in
                            let rank = isFlipped ? row : (7 - row)
                            Text("\(rank + 1)")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .frame(width: coordWidth, height: squareSize)
                        }
                    }

                    // Board squares and pieces
                    VStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<8, id: \.self) { col in
                                    let file = isFlipped ? (7 - col) : col
                                    let rank = isFlipped ? row : (7 - row)
                                    let square = Square(file: file, rank: rank)

                                    squareView(
                                        square: square,
                                        size: squareSize
                                    )
                                }
                            }
                        }

                        // Bottom coordinate labels (files)
                        HStack(spacing: 0) {
                            ForEach(0..<8, id: \.self) { col in
                                let file = isFlipped ? (7 - col) : col
                                let fileChar = String(Character(UnicodeScalar(97 + file)!))
                                Text(fileChar)
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .frame(width: squareSize, height: coordWidth)
                            }
                        }
                    }
                }
            }
            .frame(width: boardSize, height: boardSize)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func squareView(square: Square, size: CGFloat) -> some View {
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
