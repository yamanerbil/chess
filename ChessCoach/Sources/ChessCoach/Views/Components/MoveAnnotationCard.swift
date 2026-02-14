import SwiftUI

/// Card showing the annotation for the current move
struct MoveAnnotationCard: View {
    let move: ChessMove?
    let annotation: MoveAnnotation?
    let moveIndex: Int
    @State private var showEngineLines = false

    var body: some View {
        if let move = move, let annotation = annotation {
            VStack(alignment: .leading, spacing: 12) {
                // Header: move + classification badge
                HStack(spacing: 8) {
                    // Move number and SAN
                    Text(moveText(move))
                        .font(DesignSystem.Fonts.moveNotation(17))
                        .foregroundColor(.primary)

                    // Classification badge
                    classificationBadge(annotation.classification)

                    Spacer()
                }

                // Explanation
                Text(annotation.explanation)
                    .font(DesignSystem.Fonts.coaching())
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                // Best move comparison (if different from played move)
                if let bestMove = annotation.bestMove, bestMove != move.san {
                    HStack(spacing: 4) {
                        Text("Best was:")
                            .font(DesignSystem.Fonts.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        Text(bestMove)
                            .font(DesignSystem.Fonts.moveNotation(14))
                            .foregroundColor(DesignSystem.Colors.success)
                    }
                }

                // Engine lines (expandable)
                if !annotation.engineLines.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showEngineLines.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("See Engine Line")
                                .font(DesignSystem.Fonts.caption(14))
                            Image(systemName: showEngineLines ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(DesignSystem.Colors.primary)
                    }

                    if showEngineLines {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(annotation.engineLines.enumerated()), id: \.offset) { index, line in
                                Text("\(index + 1). \(line)")
                                    .font(DesignSystem.Fonts.moveNotation(13))
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                        }
                        .padding(.leading, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .padding(DesignSystem.Layout.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                    .fill(Color.gray.opacity(0.12))
            )
        } else {
            // No annotation available
            VStack(spacing: 8) {
                if move == nil {
                    Text("Starting position")
                        .font(DesignSystem.Fonts.coaching())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                } else {
                    Text("No analysis available for this move")
                        .font(DesignSystem.Fonts.coaching())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Layout.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                    .fill(Color.gray.opacity(0.12))
            )
        }
    }

    private func moveText(_ move: ChessMove) -> String {
        if move.color == .white {
            return "\(move.moveNumber). \(move.san)"
        } else {
            return "\(move.moveNumber)... \(move.san)"
        }
    }

    @ViewBuilder
    private func classificationBadge(_ classification: MoveClassification) -> some View {
        Text("\(classification.icon) \(classification.label)")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(classification.color)
            )
            .scaleEffect(1.0)
    }
}

#Preview {
    VStack(spacing: 16) {
        MoveAnnotationCard(
            move: ChessMove(
                san: "Nd5", from: Square(file: 5, rank: 2), to: Square(file: 3, rank: 4),
                piece: ChessPiece(color: .white, type: .knight),
                moveNumber: 14, color: .white
            ),
            annotation: MoveAnnotation(
                classification: .brilliant,
                explanation: "Your knight lands on a powerful central square where it can't be chased away by pawns. This creates threats all over the board!",
                bestMove: "Nd5",
                evalAfter: 1.3,
                engineLines: ["14...Nxd5 15.exd5 Nb6 16.Ng3", "14...c6 15.Nxf6+ Nxf6 16.Bg5"]
            ),
            moveIndex: 26
        )

        MoveAnnotationCard(
            move: ChessMove(
                san: "Nb8", from: Square(file: 2, rank: 5), to: Square(file: 1, rank: 7),
                piece: ChessPiece(color: .black, type: .knight),
                moveNumber: 9, color: .black
            ),
            annotation: MoveAnnotation(
                classification: .mistake,
                explanation: "Moving your knight backwards loses time. Better to reroute with Na5.",
                bestMove: "Na5",
                evalAfter: 0.7
            ),
            moveIndex: 17
        )
    }
    .padding()
}
