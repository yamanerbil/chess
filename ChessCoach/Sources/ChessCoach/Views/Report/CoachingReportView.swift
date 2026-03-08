import SwiftUI

/// Full coaching report view with opening, middlegame, endgame sections and key takeaways
struct CoachingReportView: View {
    let game: Game
    /// Claude-generated game report (nil = use heuristic takeaways)
    var gameReport: GameReport?
    /// Whether a Claude report is currently loading
    var isGeneratingReport: Bool = false
    /// Callback to request a Claude report
    var onRequestReport: (() -> Void)?
    let onJumpToMove: (Int) -> Void

    private var playerMoves: [(offset: Int, element: ChessMove)] {
        Array(game.moves.enumerated().filter { $0.element.color == game.playerColor })
    }

    // MARK: - Phase analysis

    private var openingMoves: [(offset: Int, element: ChessMove)] {
        Array(playerMoves.prefix(5))
    }
    private var middlegameMoves: [(offset: Int, element: ChessMove)] {
        Array(playerMoves.dropFirst(5).prefix(10))
    }
    private var endgameMoves: [(offset: Int, element: ChessMove)] {
        Array(playerMoves.dropFirst(15))
    }

    private func phaseAccuracy(_ moves: [(offset: Int, element: ChessMove)]) -> Double? {
        guard !moves.isEmpty else { return nil }
        let good = moves.filter { idx, _ in
            guard let ann = game.annotations[idx] else { return true }
            return ann.classification == .brilliant || ann.classification == .great || ann.classification == .good
        }
        return Double(good.count) / Double(moves.count) * 100
    }

    private func phaseBestMove(_ moves: [(offset: Int, element: ChessMove)]) -> (index: Int, annotation: MoveAnnotation)? {
        var best: (index: Int, annotation: MoveAnnotation)?
        for (idx, _) in moves {
            if let ann = game.annotations[idx] {
                if ann.classification == .brilliant || ann.classification == .great {
                    if best == nil || ann.classification == .brilliant {
                        best = (idx, ann)
                    }
                }
            }
        }
        return best
    }

    private func phaseWorstMove(_ moves: [(offset: Int, element: ChessMove)]) -> (index: Int, annotation: MoveAnnotation)? {
        var worst: (index: Int, annotation: MoveAnnotation)?
        let badClassifications: [MoveClassification] = [.blunder, .mistake, .inaccuracy]
        for (idx, _) in moves {
            if let ann = game.annotations[idx], badClassifications.contains(ann.classification) {
                if worst == nil {
                    worst = (idx, ann)
                } else if let current = worst, badClassifications.firstIndex(of: ann.classification)! < badClassifications.firstIndex(of: current.annotation.classification)! {
                    worst = (idx, ann)
                }
            }
        }
        return worst
    }

    private var keyTakeaways: [String] {
        var takeaways: [String] = []

        // Find positives
        let brilliantCount = game.annotations.values.filter { $0.classification == .brilliant }.count
        let greatCount = game.annotations.values.filter { $0.classification == .great }.count

        if brilliantCount > 0 {
            takeaways.append("You found \(brilliantCount) brilliant move\(brilliantCount > 1 ? "s" : "") — amazing!")
        }
        if greatCount >= 5 {
            takeaways.append("Solid play with \(greatCount) great moves — keep it up!")
        }

        // Check castling
        let castled = game.moves.contains { $0.color == game.playerColor && $0.isCastle }
        if castled {
            takeaways.append("Great job castling to keep your king safe!")
        } else {
            takeaways.append("Try to castle early in your games to protect your king.")
        }

        // Check for mistakes/blunders
        let mistakeCount = game.annotations.values.filter { $0.classification == .mistake }.count
        let blunderCount = game.annotations.values.filter { $0.classification == .blunder }.count
        if blunderCount > 0 {
            takeaways.append("Before each move, ask: \"Is my piece safe on that square?\" This can help avoid blunders.")
        } else if mistakeCount > 0 {
            takeaways.append("Only \(mistakeCount) mistake\(mistakeCount > 1 ? "s" : "") — you're playing carefully!")
        } else {
            takeaways.append("No mistakes or blunders — outstanding game!")
        }

        return takeaways
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Game summary header
                summaryCard

                // Opening section
                if !openingMoves.isEmpty {
                    phaseCard(
                        title: "Opening",
                        icon: "book.fill",
                        moves: openingMoves,
                        openingName: game.opening
                    )
                }

                // Middlegame section
                if !middlegameMoves.isEmpty {
                    phaseCard(
                        title: "Middlegame",
                        icon: "flame.fill",
                        moves: middlegameMoves,
                        openingName: nil
                    )
                }

                // Endgame section
                if !endgameMoves.isEmpty {
                    phaseCard(
                        title: "Endgame",
                        icon: "flag.checkered",
                        moves: endgameMoves,
                        openingName: nil
                    )
                }

                // Claude AI coaching report (if available)
                if let report = gameReport {
                    claudeReportCard(report)
                } else {
                    // Heuristic takeaways
                    takeawaysCard

                    // Generate AI report button
                    if let onRequest = onRequestReport {
                        Button {
                            onRequest()
                        } label: {
                            HStack(spacing: 8) {
                                if isGeneratingReport {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(isGeneratingReport ? "Generating AI report..." : "Get AI Coaching Report")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                                    .fill(DesignSystem.Colors.primary)
                            )
                        }
                        .disabled(isGeneratingReport)
                        .padding(.horizontal, 16)
                    }
                }

                // Export buttons
                exportButtons

                Spacer(minLength: 16)
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: resultIcon)
                    .foregroundColor(resultColor)
                Text("vs. \(game.opponentName)")
                    .font(DesignSystem.Fonts.headline(18))
                Spacer()
                Text(resultText)
                    .font(DesignSystem.Fonts.body(15))
                    .foregroundColor(resultColor)
            }

            if let event = game.event {
                HStack {
                    Text(event)
                    if let round = game.round {
                        Text("Round \(round)")
                    }
                }
                .font(DesignSystem.Fonts.caption())
                .foregroundColor(DesignSystem.Colors.secondaryText)
            }

            Divider()

            if let accuracy = game.accuracy {
                HStack {
                    Text("Accuracy")
                        .font(DesignSystem.Fonts.body(15))
                    Spacer()
                    // Accuracy bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(accuracyColor(accuracy))
                                .frame(width: geo.size.width * CGFloat(accuracy / 100.0))
                        }
                    }
                    .frame(width: 100, height: 10)

                    Text("\(Int(accuracy))%")
                        .font(DesignSystem.Fonts.headline(15))
                        .foregroundColor(accuracyColor(accuracy))
                }
            }

            // Move quality summary row
            let counts = moveCounts
            HStack(spacing: 16) {
                qualityBadge("Best", count: counts.best, color: DesignSystem.Colors.success)
                qualityBadge("Good", count: counts.good, color: Color(red: 0.55, green: 0.76, blue: 0.29))
                qualityBadge("Inaccuracy", count: counts.inaccuracy, color: DesignSystem.Colors.warning)
                qualityBadge("Mistake", count: counts.mistake, color: .orange)
                qualityBadge("Blunder", count: counts.blunder, color: DesignSystem.Colors.error)
            }
            .font(DesignSystem.Fonts.caption(11))
        }
        .padding(DesignSystem.Layout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                .fill(Color.gray.opacity(0.08))
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Phase Card

    @ViewBuilder
    private func phaseCard(title: String, icon: String, moves: [(offset: Int, element: ChessMove)], openingName: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(DesignSystem.Colors.accent)
                Text(title)
                    .font(DesignSystem.Fonts.headline(16))
            }

            if let name = openingName {
                Text(name)
                    .font(DesignSystem.Fonts.headline(14))
                    .foregroundColor(DesignSystem.Colors.primary)
            }

            if let acc = phaseAccuracy(moves) {
                HStack {
                    Text("Phase accuracy:")
                        .font(DesignSystem.Fonts.caption())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text("\(Int(acc))%")
                        .font(DesignSystem.Fonts.moveNotation(13))
                        .foregroundColor(accuracyColor(acc))
                }
            }

            // Best moment
            if let best = phaseBestMove(moves) {
                let move = game.moves[best.index]
                Button {
                    onJumpToMove(best.index + 1)
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: best.annotation.classification.icon)
                            .foregroundColor(best.annotation.classification.color)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(move.moveNumber). \(move.color == .black ? "..." : "")\(move.san)")
                                .font(DesignSystem.Fonts.moveNotation(14))
                            Text(best.annotation.explanation)
                                .font(DesignSystem.Fonts.coaching(14))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DesignSystem.Colors.success.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
            }

            // Worst moment (learning opportunity)
            if let worst = phaseWorstMove(moves) {
                let move = game.moves[worst.index]
                Button {
                    onJumpToMove(worst.index + 1)
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: worst.annotation.classification.icon)
                            .foregroundColor(worst.annotation.classification.color)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(move.moveNumber). \(move.color == .black ? "..." : "")\(move.san)")
                                .font(DesignSystem.Fonts.moveNotation(14))
                            Text(worst.annotation.explanation)
                                .font(DesignSystem.Fonts.coaching(14))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DesignSystem.Colors.warning.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Layout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                .fill(Color.gray.opacity(0.08))
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Takeaways

    private var takeawaysCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .foregroundColor(DesignSystem.Colors.accent)
                Text("Key Takeaways")
                    .font(DesignSystem.Fonts.headline(16))
            }

            ForEach(Array(keyTakeaways.enumerated()), id: \.offset) { index, takeaway in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .font(DesignSystem.Fonts.headline(14))
                        .foregroundColor(DesignSystem.Colors.primary)
                        .frame(width: 20, alignment: .trailing)
                    Text(takeaway)
                        .font(DesignSystem.Fonts.coaching(15))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Layout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                .fill(Color.gray.opacity(0.08))
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Export

    private var exportButtons: some View {
        VStack(spacing: 10) {
            Button {
                // Share placeholder
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Report")
                }
                .font(DesignSystem.Fonts.body(15))
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                        .stroke(DesignSystem.Colors.primary, lineWidth: 1.5)
                )
            }

            Button {
                // Export PGN placeholder
            } label: {
                HStack {
                    Image(systemName: "doc.text")
                    Text("Export PGN")
                }
                .font(DesignSystem.Fonts.body(15))
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Claude Report Card

    @ViewBuilder
    private func claudeReportCard(_ report: GameReport) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Summary
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundColor(DesignSystem.Colors.accent)
                Text("AI Coaching Report")
                    .font(DesignSystem.Fonts.headline(16))
            }

            Text(report.summary)
                .font(DesignSystem.Fonts.coaching(15))

            // Key moments
            if !report.keyMoments.isEmpty {
                Divider()

                Text("KEY MOMENTS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.secondaryText)

                ForEach(Array(report.keyMoments.enumerated()), id: \.offset) { _, moment in
                    Button {
                        // Jump to the move (convert from full-move number to half-move index)
                        let halfMoveIndex = moment.moveNumber * 2 - 1
                        if halfMoveIndex > 0 && halfMoveIndex <= game.moves.count {
                            onJumpToMove(halfMoveIndex)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Move \(moment.moveNumber): \(moment.title)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                            Text(moment.explanation)
                                .font(DesignSystem.Fonts.coaching(14))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            if let alt = moment.betterAlternative {
                                Text("Better: \(alt)")
                                    .font(DesignSystem.Fonts.moveNotation(13))
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.06))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Strengths
            if !report.strengths.isEmpty {
                Divider()
                Text("STRENGTHS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.secondaryText)

                ForEach(Array(report.strengths.enumerated()), id: \.offset) { _, strength in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Colors.success)
                            .padding(.top, 2)
                        Text(strength)
                            .font(DesignSystem.Fonts.coaching(14))
                    }
                }
            }

            // Homework
            Divider()
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "target")
                    .foregroundColor(DesignSystem.Colors.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text("HOMEWORK")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text(report.homework)
                        .font(DesignSystem.Fonts.coaching(15))
                        .fontWeight(.medium)
                }
            }

            // Encouragement
            Text(report.encouragement)
                .font(DesignSystem.Fonts.coaching(15))
                .italic()
                .foregroundColor(DesignSystem.Colors.primary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Layout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                .fill(Color.gray.opacity(0.08))
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Helpers

    private var resultIcon: String {
        if game.playerWon { return "star.fill" }
        if game.playerLost { return "xmark.circle" }
        return "equal.circle"
    }

    private var resultColor: Color {
        if game.playerWon { return DesignSystem.Colors.success }
        if game.playerLost { return DesignSystem.Colors.error }
        return DesignSystem.Colors.secondaryText
    }

    private var resultText: String {
        if game.playerWon { return "Won (\(game.result.displayText))" }
        if game.playerLost { return "Lost (\(game.result.displayText))" }
        return "Draw (\(game.result.displayText))"
    }

    private var moveCounts: (best: Int, good: Int, inaccuracy: Int, mistake: Int, blunder: Int) {
        let anns = game.annotations.values
        return (
            best: anns.filter { $0.classification == .brilliant || $0.classification == .great }.count,
            good: anns.filter { $0.classification == .good }.count,
            inaccuracy: anns.filter { $0.classification == .inaccuracy }.count,
            mistake: anns.filter { $0.classification == .mistake }.count,
            blunder: anns.filter { $0.classification == .blunder }.count
        )
    }

    private func qualityBadge(_ label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(DesignSystem.Fonts.headline(14))
                .foregroundColor(count > 0 ? color : DesignSystem.Colors.secondaryText)
            Text(label)
                .font(DesignSystem.Fonts.caption(9))
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private func accuracyColor(_ accuracy: Double) -> Color {
        if accuracy > 85 { return DesignSystem.Colors.success }
        if accuracy > 70 { return DesignSystem.Colors.warning }
        if accuracy > 55 { return .orange }
        return DesignSystem.Colors.error
    }
}

#Preview {
    NavigationStack {
        CoachingReportView(game: SampleData.sampleGame) { moveIndex in
            print("Jump to move \(moveIndex)")
        }
    }
}
