import SwiftUI

/// Game metadata entry screen — captures game details before analysis
struct GameMetadataScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var playerColor: PieceColor = .white
    @State private var result: GameResultChoice = .won
    @State private var opponentName: String = ""
    @State private var tournament: String = ""
    @State private var round: String = ""
    @State private var playerRating: String = ""
    @State private var opponentRating: String = ""
    @State private var showNewTournament = false
    @State private var newTournamentName: String = ""

    let knownTournaments: [String]
    let onSubmit: (GameMetadata) -> Void

    enum GameResultChoice: String, CaseIterable {
        case won = "Won"
        case lost = "Lost"
        case draw = "Draw"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Color selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("I played as:")
                        .font(DesignSystem.Fonts.body(15))
                        .foregroundColor(DesignSystem.Colors.secondaryText)

                    HStack(spacing: 12) {
                        colorButton(.white, label: "White", icon: "square.fill")
                        colorButton(.black, label: "Black", icon: "square.fill")
                    }
                }

                // Result selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Result:")
                        .font(DesignSystem.Fonts.body(15))
                        .foregroundColor(DesignSystem.Colors.secondaryText)

                    HStack(spacing: 12) {
                        ForEach(GameResultChoice.allCases, id: \.self) { choice in
                            resultButton(choice)
                        }
                    }
                }

                // Opponent name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Opponent:")
                        .font(DesignSystem.Fonts.body(15))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    TextField("Opponent name", text: $opponentName)
                        .textFieldStyle(.roundedBorder)
                        .font(DesignSystem.Fonts.body(16))
                }

                // Tournament
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tournament:")
                        .font(DesignSystem.Fonts.body(15))
                        .foregroundColor(DesignSystem.Colors.secondaryText)

                    if knownTournaments.isEmpty || showNewTournament {
                        TextField("Tournament name", text: $newTournamentName)
                            .textFieldStyle(.roundedBorder)
                            .font(DesignSystem.Fonts.body(16))
                    } else {
                        Menu {
                            ForEach(knownTournaments, id: \.self) { t in
                                Button(t) { tournament = t }
                            }
                            Divider()
                            Button("Add new tournament...") {
                                showNewTournament = true
                            }
                        } label: {
                            HStack {
                                Text(tournament.isEmpty ? "Select tournament" : tournament)
                                    .foregroundColor(tournament.isEmpty ? .gray : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                            }
                            .font(DesignSystem.Fonts.body(16))
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3))
                            )
                        }
                    }
                }

                // Round
                VStack(alignment: .leading, spacing: 8) {
                    Text("Round:")
                        .font(DesignSystem.Fonts.body(15))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    TextField("Round number", text: $round)
                        .textFieldStyle(.roundedBorder)
                        .font(DesignSystem.Fonts.body(16))
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }

                // Ratings (optional)
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("My rating:")
                            .font(DesignSystem.Fonts.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        TextField("Optional", text: $playerRating)
                            .textFieldStyle(.roundedBorder)
                            .font(DesignSystem.Fonts.body(16))
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Opp. rating:")
                            .font(DesignSystem.Fonts.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        TextField("Optional", text: $opponentRating)
                            .textFieldStyle(.roundedBorder)
                            .font(DesignSystem.Fonts.body(16))
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                    }
                }

                Spacer(minLength: 20)

                // Submit button
                Button(action: submitGame) {
                    HStack {
                        Text("Analyze Game")
                            .font(DesignSystem.Fonts.headline(17))
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                            .fill(DesignSystem.Colors.primary)
                    )
                }
            }
            .padding(20)
        }
        .navigationTitle("Game Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Components

    private func colorButton(_ color: PieceColor, label: String, icon: String) -> some View {
        Button {
            playerColor = color
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color == .white ? .white : .black)
                    .font(.system(size: 20))
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color == .white ? Color.gray.opacity(0.2) : Color.black)
                    )
                Text(label)
                    .font(DesignSystem.Fonts.body(16))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(playerColor == color ? DesignSystem.Colors.primary.opacity(0.1) : Color.gray.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(playerColor == color ? DesignSystem.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func resultButton(_ choice: GameResultChoice) -> some View {
        let color: Color = {
            switch choice {
            case .won: return DesignSystem.Colors.success
            case .lost: return DesignSystem.Colors.error
            case .draw: return DesignSystem.Colors.secondaryText
            }
        }()

        return Button {
            result = choice
        } label: {
            Text(choice.rawValue)
                .font(DesignSystem.Fonts.body(15))
                .fontWeight(result == choice ? .semibold : .regular)
                .foregroundColor(result == choice ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(result == choice ? color : Color.gray.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
    }

    private func submitGame() {
        let gameResult: GameResult = {
            switch (result, playerColor) {
            case (.won, .white): return .whiteWins
            case (.won, .black): return .blackWins
            case (.lost, .white): return .blackWins
            case (.lost, .black): return .whiteWins
            case (.draw, _): return .draw
            }
        }()

        let effectiveTournament = showNewTournament ? newTournamentName : tournament

        let metadata = GameMetadata(
            playerColor: playerColor,
            result: gameResult,
            opponentName: opponentName.isEmpty ? "Opponent" : opponentName,
            tournament: effectiveTournament.isEmpty ? nil : effectiveTournament,
            round: round.isEmpty ? nil : round,
            playerRating: Int(playerRating),
            opponentRating: Int(opponentRating)
        )
        onSubmit(metadata)
    }
}

/// Data collected from the game metadata form
struct GameMetadata {
    let playerColor: PieceColor
    let result: GameResult
    let opponentName: String
    let tournament: String?
    let round: String?
    let playerRating: Int?
    let opponentRating: Int?
}

#Preview {
    NavigationStack {
        GameMetadataScreen(
            knownTournaments: ["Spring Open", "State Championship"]
        ) { metadata in
            print("Submitted: \(metadata)")
        }
    }
}
