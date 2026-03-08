import SwiftUI

/// Home screen — "My Games" — the app's landing page
struct HomeScreen: View {
    let games: [Game]
    @State private var selectedFilter: String = "All"

    private var tournaments: [String] {
        let events = games.compactMap { $0.event }
        return ["All"] + Array(Set(events)).sorted()
    }

    private var filteredGames: [Game] {
        if selectedFilter == "All" {
            return games.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
        }
        return games
            .filter { $0.event == selectedFilter }
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tournament filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tournaments, id: \.self) { tournament in
                        FilterChip(
                            title: tournament,
                            isSelected: selectedFilter == tournament
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = tournament
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            // Game list
            if filteredGames.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Text("♟")
                        .font(.system(size: 48))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text("No games yet")
                        .font(DesignSystem.Fonts.headline(18))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text("Scan a scoresheet to get started!")
                        .font(DesignSystem.Fonts.body(15))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredGames) { game in
                            NavigationLink(value: game.id) {
                                GameCard(game: game)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // space for FAB
                }
            }
        }
        .navigationTitle("My Games")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Fonts.caption(14))
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? DesignSystem.Colors.primary : Color.gray.opacity(0.12))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

// MARK: - Game Card

struct GameCard: View {
    let game: Game

    private var resultColor: Color {
        if game.playerWon { return DesignSystem.Colors.success }
        if game.playerLost { return DesignSystem.Colors.error }
        return DesignSystem.Colors.secondaryText
    }

    private var resultIcon: String {
        if game.playerWon { return "star.fill" }
        if game.playerLost { return "xmark.circle" }
        return "equal.circle"
    }

    private var resultLabel: String {
        if game.playerWon { return "W" }
        if game.playerLost { return "L" }
        return "D"
    }

    private var colorIndicator: String {
        game.playerColor == .white ? "W" : "B"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Left: mini board thumbnail
            ChessBoardView(
                position: game.positions.last ?? .initial,
                playerColor: game.playerColor,
                lastMoveFrom: game.moves.last?.from,
                lastMoveTo: game.moves.last?.to
            )
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Middle: game info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: resultIcon)
                        .foregroundColor(resultColor)
                        .font(.system(size: 14))
                    Text("vs. \(game.opponentName)")
                        .font(DesignSystem.Fonts.headline(16))
                        .foregroundColor(.primary)
                    Spacer()
                    // Color + Result badge
                    Text("\(colorIndicator)  \(game.result.displayText)")
                        .font(DesignSystem.Fonts.moveNotation(13))
                        .foregroundColor(resultColor)
                }

                if let event = game.event {
                    HStack(spacing: 0) {
                        Text(event)
                        if let round = game.round {
                            Text(" Rd \(round)")
                        }
                    }
                    .font(DesignSystem.Fonts.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                }

                HStack(spacing: 8) {
                    if let opening = game.opening {
                        Text(opening)
                            .font(DesignSystem.Fonts.caption(12))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .lineLimit(1)
                    }
                    Spacer()
                    if let accuracy = game.accuracy {
                        Text("Acc: \(Int(accuracy))%")
                            .font(DesignSystem.Fonts.moveNotation(12))
                            .foregroundColor(accuracyColor(accuracy))
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.gray.opacity(0.4))
        }
        .padding(DesignSystem.Layout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                .fill(Color.gray.opacity(0.08))
        )
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
        HomeScreen(games: SampleData.allGames)
    }
}
