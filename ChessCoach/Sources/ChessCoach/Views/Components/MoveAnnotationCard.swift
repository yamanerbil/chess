import SwiftUI

/// Card showing the annotation for the current move — coaching style with avatar
struct MoveAnnotationCard: View {
    let move: ChessMove?
    let annotation: MoveAnnotation?
    let moveIndex: Int
    @State private var showEngineLines = false

    var body: some View {
        if let move = move, let annotation = annotation {
            HStack(spacing: 0) {
                // Left accent border
                RoundedRectangle(cornerRadius: 2)
                    .fill(annotation.classification.color)
                    .frame(width: 4)

                HStack(alignment: .top, spacing: 12) {
                    // Coach avatar
                    coachAvatar

                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        // Title row: friendly title + category badge
                        HStack(spacing: 8) {
                            Text(annotation.classification.friendlyTitle)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            Text(annotation.classification.category.uppercased())
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(Color.gray.opacity(0.12))
                                )

                            Spacer()
                        }

                        // Explanation text with bold move notation
                        explanationText(move: move, explanation: annotation.explanation)
                            .font(DesignSystem.Fonts.coaching(15))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        // Best move comparison (if different from played move)
                        if let bestMove = annotation.bestMove, bestMove != move.san {
                            HStack(spacing: 4) {
                                Text("Best was")
                                    .font(DesignSystem.Fonts.caption())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                Text(bestMove)
                                    .font(DesignSystem.Fonts.moveNotation(14))
                                    .foregroundColor(DesignSystem.Colors.primary)
                                    .fontWeight(.bold)
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
                                    Text("Engine Line")
                                        .font(DesignSystem.Fonts.caption(13))
                                    Image(systemName: showEngineLines ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(DesignSystem.Colors.primary)
                            }

                            if showEngineLines {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(Array(annotation.engineLines.enumerated()), id: \.offset) { index, line in
                                        Text("\(index + 1). \(line)")
                                            .font(DesignSystem.Fonts.moveNotation(12))
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    }
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                }
                .padding(14)
            }
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius))
        } else {
            // No annotation available
            HStack(spacing: 12) {
                coachAvatar

                Text(move == nil ? "Starting position — ready to review!" : "No analysis for this move")
                    .font(DesignSystem.Fonts.coaching(15))
                    .foregroundColor(DesignSystem.Colors.secondaryText)

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            )
        }
    }

    // MARK: - Coach Avatar

    private var coachAvatar: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(DesignSystem.Colors.primary.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "cpu")
                        .font(.system(size: 18))
                        .foregroundColor(DesignSystem.Colors.primary)
                )

            // Status dot
            Circle()
                .fill(DesignSystem.Colors.success)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle().stroke(Color.white, lineWidth: 1.5)
                )
                .offset(x: 1, y: 1)
        }
    }

    // MARK: - Rich Text

    @ViewBuilder
    private func explanationText(move: ChessMove, explanation: String) -> some View {
        // Highlight the played move's SAN in the explanation if present
        let san = move.san
        if explanation.contains(san) {
            let parts = explanation.components(separatedBy: san)
            if parts.count >= 2 {
                (Text(parts[0]) +
                 Text(san)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.primary) +
                 Text(parts.dropFirst().joined(separator: san)))
            } else {
                Text(explanation)
            }
        } else {
            Text(explanation)
        }
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
                explanation: "Your knight lands on a powerful central square with Nd5 where it can't be chased away by pawns!",
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

        MoveAnnotationCard(
            move: nil,
            annotation: nil,
            moveIndex: 0
        )
    }
    .padding()
    .background(Color(red: 0.96, green: 0.97, blue: 0.98))
}
