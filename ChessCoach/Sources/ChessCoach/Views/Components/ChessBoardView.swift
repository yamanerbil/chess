import SwiftUI

/// The main chess board rendering view
struct ChessBoardView: View {
    let position: BoardPosition
    let playerColor: PieceColor
    let lastMoveFrom: Square?
    let lastMoveTo: Square?
    var bestMoveFrom: Square? = nil
    var bestMoveTo: Square? = nil
    var showCoordinates: Bool = true

    /// Whether the board is flipped (showing from black's perspective)
    private var isFlipped: Bool {
        playerColor == .black
    }

    var body: some View {
        GeometryReader { geometry in
            let boardSize = min(geometry.size.width, geometry.size.height)
            let squareSize = boardSize / 8

            ZStack {
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
                                    size: squareSize,
                                    row: row,
                                    col: col
                                )
                            }
                        }
                    }
                }

                // Best move arrow overlay
                if let from = bestMoveFrom, let to = bestMoveTo {
                    bestMoveArrow(from: from, to: to, squareSize: squareSize)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(width: boardSize, height: boardSize)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Best Move Arrow

    private func bestMoveArrow(from: Square, to: Square, squareSize: CGFloat) -> some View {
        let fromPoint = squareCenter(from, squareSize: squareSize)
        let toPoint = squareCenter(to, squareSize: squareSize)

        return Canvas { context, _ in
            let arrowWidth: CGFloat = squareSize * 0.18
            let headLength: CGFloat = squareSize * 0.4
            let headWidth: CGFloat = squareSize * 0.4

            // Direction vector
            let dx = toPoint.x - fromPoint.x
            let dy = toPoint.y - fromPoint.y
            let length = sqrt(dx * dx + dy * dy)
            guard length > 0 else { return }
            let ux = dx / length
            let uy = dy / length

            // Perpendicular
            let px = -uy
            let py = ux

            // Shaft end (where the head starts)
            let shaftEnd = CGPoint(x: toPoint.x - ux * headLength, y: toPoint.y - uy * headLength)

            // Build arrow path
            var path = Path()

            // Shaft (rectangle from fromPoint to shaftEnd)
            let shaftHalf = arrowWidth / 2
            path.move(to: CGPoint(x: fromPoint.x + px * shaftHalf, y: fromPoint.y + py * shaftHalf))
            path.addLine(to: CGPoint(x: shaftEnd.x + px * shaftHalf, y: shaftEnd.y + py * shaftHalf))

            // Head (triangle)
            path.addLine(to: CGPoint(x: shaftEnd.x + px * headWidth, y: shaftEnd.y + py * headWidth))
            path.addLine(to: toPoint)
            path.addLine(to: CGPoint(x: shaftEnd.x - px * headWidth, y: shaftEnd.y - py * headWidth))

            // Back to shaft
            path.addLine(to: CGPoint(x: shaftEnd.x - px * shaftHalf, y: shaftEnd.y - py * shaftHalf))
            path.addLine(to: CGPoint(x: fromPoint.x - px * shaftHalf, y: fromPoint.y - py * shaftHalf))
            path.closeSubpath()

            // Draw with semi-transparent green fill and white border
            context.fill(path, with: .color(DesignSystem.Colors.bestMoveArrow.opacity(0.8)))
            context.stroke(path, with: .color(.white.opacity(0.9)), lineWidth: 1.5)
        }
        .allowsHitTesting(false)
    }

    /// Convert a chess Square to a CGPoint center on the board
    private func squareCenter(_ square: Square, squareSize: CGFloat) -> CGPoint {
        let col: CGFloat
        let row: CGFloat
        if isFlipped {
            col = CGFloat(7 - square.file)
            row = CGFloat(square.rank)
        } else {
            col = CGFloat(square.file)
            row = CGFloat(7 - square.rank)
        }
        return CGPoint(
            x: col * squareSize + squareSize / 2,
            y: row * squareSize + squareSize / 2
        )
    }

    // MARK: - Square View

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
        PieceIconView(piece: piece, size: size * 0.85)
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
