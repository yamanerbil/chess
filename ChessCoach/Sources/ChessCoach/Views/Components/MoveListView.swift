import SwiftUI

/// Two-column move list with classification icons and tap-to-jump
struct MoveListView: View {
    let moves: [ChessMove]
    let annotations: [Int: MoveAnnotation]
    let currentMoveIndex: Int
    let onSelectMove: (Int) -> Void

    /// Group moves into pairs (white move, optional black move)
    private var movePairs: [(moveNumber: Int, white: (Int, ChessMove)?, black: (Int, ChessMove)?)] {
        var pairs: [(moveNumber: Int, white: (Int, ChessMove)?, black: (Int, ChessMove)?)] = []
        var i = 0
        while i < moves.count {
            let move = moves[i]
            let moveNum = move.moveNumber

            var whitePart: (Int, ChessMove)?
            var blackPart: (Int, ChessMove)?

            if move.color == .white {
                whitePart = (i, move)
                if i + 1 < moves.count && moves[i + 1].color == .black {
                    blackPart = (i + 1, moves[i + 1])
                    i += 2
                } else {
                    i += 1
                }
            } else {
                blackPart = (i, move)
                i += 1
            }

            pairs.append((moveNumber: moveNum, white: whitePart, black: blackPart))
        }
        return pairs
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Header
                    HStack(spacing: 0) {
                        Text("#")
                            .frame(width: 32, alignment: .center)
                        Text("White")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Black")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .font(DesignSystem.Fonts.caption(12))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                    Divider()

                    ForEach(Array(movePairs.enumerated()), id: \.offset) { pairIndex, pair in
                        HStack(spacing: 0) {
                            // Move number
                            Text("\(pair.moveNumber).")
                                .font(DesignSystem.Fonts.moveNotation(13))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .frame(width: 32, alignment: .center)

                            // White move
                            if let (index, move) = pair.white {
                                moveCell(move: move, index: index)
                            } else {
                                Spacer().frame(maxWidth: .infinity)
                            }

                            // Black move
                            if let (index, move) = pair.black {
                                moveCell(move: move, index: index)
                            } else {
                                Spacer().frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .id(pairIndex)
                    }
                }
            }
            .onChange(of: currentMoveIndex) { _, newValue in
                // Scroll to keep current move visible
                let pairIndex = newValue > 0 ? (newValue - 1) / 2 : 0
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(pairIndex, anchor: .center)
                }
            }
        }
    }

    @ViewBuilder
    private func moveCell(move: ChessMove, index: Int) -> some View {
        let isSelected = index + 1 == currentMoveIndex
        let annotation = annotations[index]

        Button {
            onSelectMove(index + 1)
        } label: {
            HStack(spacing: 4) {
                // Classification icon
                if let annotation = annotation {
                    Text(annotation.classification.icon)
                        .font(.system(size: 12))
                }

                Text(move.san)
                    .font(DesignSystem.Fonts.moveNotation(14))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? DesignSystem.Colors.primary : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let game = SampleData.sampleGame
    MoveListView(
        moves: game.moves,
        annotations: game.annotations,
        currentMoveIndex: 5,
        onSelectMove: { _ in }
    )
    .frame(height: 400)
}
