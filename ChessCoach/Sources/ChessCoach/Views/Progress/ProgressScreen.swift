import SwiftUI

/// Progress Dashboard — shows accuracy trends, strengths, and focus areas
struct ProgressScreen: View {
    let games: [Game]

    private var sortedGames: [Game] {
        games.sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
    }

    private var gamesAnalyzed: Int { games.count }

    private var accuracies: [Double] {
        sortedGames.compactMap { $0.accuracy }
    }

    private var averageAccuracy: Double? {
        guard !accuracies.isEmpty else { return nil }
        return accuracies.reduce(0, +) / Double(accuracies.count)
    }

    private var openingScore: Double {
        guard !games.isEmpty else { return 0 }
        // Approximate: look at first 10 moves' annotations
        var goodCount = 0
        var totalCount = 0
        for game in games {
            let playerMoves = game.moves.enumerated().filter { $0.element.color == game.playerColor }
            for (idx, _) in playerMoves.prefix(5) {
                totalCount += 1
                if let ann = game.annotations[idx],
                   ann.classification == .brilliant || ann.classification == .great || ann.classification == .good {
                    goodCount += 1
                }
            }
        }
        return totalCount > 0 ? Double(goodCount) / Double(totalCount) : 0
    }

    private var tacticsScore: Double {
        guard !games.isEmpty else { return 0 }
        // Middle portion of games
        var goodCount = 0
        var totalCount = 0
        for game in games {
            let playerMoves = game.moves.enumerated().filter { $0.element.color == game.playerColor }
            let midMoves = playerMoves.dropFirst(5).prefix(10)
            for (idx, _) in midMoves {
                totalCount += 1
                if let ann = game.annotations[idx],
                   ann.classification == .brilliant || ann.classification == .great || ann.classification == .good {
                    goodCount += 1
                }
            }
        }
        return totalCount > 0 ? Double(goodCount) / Double(totalCount) : 0
    }

    private var endgameScore: Double {
        guard !games.isEmpty else { return 0 }
        var goodCount = 0
        var totalCount = 0
        for game in games {
            let playerMoves = game.moves.enumerated().filter { $0.element.color == game.playerColor }
            let lateMoves = playerMoves.dropFirst(15)
            for (idx, _) in lateMoves {
                totalCount += 1
                if let ann = game.annotations[idx],
                   ann.classification == .brilliant || ann.classification == .great || ann.classification == .good {
                    goodCount += 1
                }
            }
        }
        return totalCount > 0 ? Double(goodCount) / Double(totalCount) : 0
    }

    private var blunderRate: Double {
        guard !games.isEmpty else { return 0 }
        var totalBlunders = 0
        for game in games {
            totalBlunders += game.annotations.values.filter { $0.classification == .blunder }.count
        }
        return Double(totalBlunders) / Double(games.count)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Games Analyzed: \(gamesAnalyzed)")
                            .font(DesignSystem.Fonts.headline(18))
                        if let firstDate = sortedGames.first?.date {
                            Text("Since \(firstDate, format: .dateTime.month(.wide).year())")
                                .font(DesignSystem.Fonts.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)

                // Accuracy over time chart
                sectionCard(title: "Accuracy Over Time", icon: "chart.line.uptrend.xyaxis") {
                    if accuracies.count >= 2 {
                        AccuracyChart(values: accuracies)
                            .frame(height: 150)
                    } else {
                        Text("Play more games to see your accuracy trend!")
                            .font(DesignSystem.Fonts.coaching())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .padding(.vertical, 20)
                    }
                }

                // Strengths
                sectionCard(title: "Your Strengths", icon: "bolt.fill") {
                    VStack(spacing: 12) {
                        StrengthBar(label: "Opening", value: openingScore)
                        StrengthBar(label: "Tactics", value: tacticsScore)
                        StrengthBar(label: "Endgame", value: endgameScore)
                    }
                }

                // Focus areas
                sectionCard(title: "Focus Areas", icon: "target") {
                    VStack(alignment: .leading, spacing: 10) {
                        if endgameScore < openingScore && endgameScore < tacticsScore {
                            focusItem(
                                text: "Endgame technique — practice converting winning positions! King and pawn endings are a great place to start."
                            )
                        }
                        if tacticsScore < 0.7 {
                            focusItem(
                                text: "Tactical awareness — try to spot checks, captures, and threats before each move."
                            )
                        }
                        if blunderRate > 0.5 {
                            focusItem(
                                text: "Blunder check — before you move, ask yourself: \"Is this piece safe?\" Your blunder rate is \(String(format: "%.1f", blunderRate))/game."
                            )
                        }
                        if let avg = averageAccuracy {
                            if avg >= 80 {
                                focusItem(
                                    text: "Great accuracy! Keep it up — you're averaging \(Int(avg))% across your games."
                                )
                            } else if avg >= 65 {
                                focusItem(
                                    text: "Your average accuracy is \(Int(avg))% — with a little more care on each move, you can push past 80%!"
                                )
                            }
                        }
                    }
                }

                Spacer(minLength: 16)
            }
            .padding(.top, 16)
        }
        .navigationTitle("My Progress")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionCard(title: String, icon: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(DesignSystem.Colors.accent)
                Text(title)
                    .font(DesignSystem.Fonts.headline(16))
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Layout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                .fill(Color.gray.opacity(0.08))
        )
        .padding(.horizontal, 16)
    }

    private func focusItem(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(DesignSystem.Fonts.body(15))
                .foregroundColor(DesignSystem.Colors.accent)
            Text(text)
                .font(DesignSystem.Fonts.coaching(15))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Accuracy Chart

private struct AccuracyChart: View {
    let values: [Double]

    private var minVal: Double { max((values.min() ?? 50) - 10, 0) }
    private var maxVal: Double { min((values.max() ?? 100) + 10, 100) }
    private var range: Double { max(maxVal - minVal, 1) }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let stepX = values.count > 1 ? w / CGFloat(values.count - 1) : w
            let inset: CGFloat = 20

            ZStack(alignment: .topLeading) {
                // Y-axis labels
                VStack {
                    Text("\(Int(maxVal))%")
                        .font(DesignSystem.Fonts.caption(10))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(Int(minVal))%")
                        .font(DesignSystem.Fonts.caption(10))
                        .foregroundColor(.gray)
                }
                .frame(height: h - inset)

                // Line chart
                Path { path in
                    for (i, val) in values.enumerated() {
                        let x = CGFloat(i) * stepX + 30
                        let y = (h - inset) - CGFloat((val - minVal) / range) * (h - inset)
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(DesignSystem.Colors.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                // Dots
                ForEach(values.indices, id: \.self) { i in
                    let x = CGFloat(i) * stepX + 30
                    let y = (h - inset) - CGFloat((values[i] - minVal) / range) * (h - inset)
                    Circle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
        }
    }
}

// MARK: - Strength Bar

private struct StrengthBar: View {
    let label: String
    let value: Double // 0.0 to 1.0

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(DesignSystem.Fonts.body(14))
                .frame(width: 70, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 14)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(min(value, 1.0)), height: 14)
                }
            }
            .frame(height: 14)

            Text("\(Int(value * 100))%")
                .font(DesignSystem.Fonts.moveNotation(12))
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .frame(width: 36, alignment: .trailing)
        }
    }

    private var barColor: Color {
        if value >= 0.8 { return DesignSystem.Colors.success }
        if value >= 0.6 { return DesignSystem.Colors.warning }
        return DesignSystem.Colors.error
    }
}

#Preview {
    NavigationStack {
        ProgressScreen(games: SampleData.allGames)
    }
}
