import SwiftUI

/// The main Game Review screen — the core screen of ChessCoach
struct GameReviewScreen: View {
    @State var viewModel: GameReviewViewModel

    /// Minimum swipe distance to trigger a move
    private let swipeThreshold: CGFloat = 30

    var body: some View {
        VStack(spacing: 0) {
            // Content area
            switch viewModel.selectedTab {
            case .board:
                boardTab
            case .moves:
                movesTab
            case .report:
                reportTab
            }

            // Segment control
            Picker("Tab", selection: $viewModel.selectedTab) {
                ForEach(GameReviewViewModel.ReviewTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .navigationTitle("vs. \(viewModel.game.opponentName)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Text("vs. \(viewModel.game.opponentName)")
                        .font(DesignSystem.Fonts.headline(17))

                    HStack(spacing: 3) {
                        Image(systemName: viewModel.resultIcon)
                            .font(.system(size: 12))
                        Text(viewModel.resultText)
                            .font(DesignSystem.Fonts.caption(13))
                    }
                    .foregroundColor(viewModel.resultColor)
                }
            }
        }
    }

    // MARK: - Board Tab

    private var boardTab: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Chess board with swipe gestures
                ChessBoardView(
                    position: viewModel.currentPosition,
                    playerColor: viewModel.game.playerColor,
                    lastMoveFrom: viewModel.lastMove?.from,
                    lastMoveTo: viewModel.lastMove?.to
                )
                .gesture(
                    DragGesture(minimumDistance: swipeThreshold)
                        .onEnded { value in
                            let horizontal = value.translation.width
                            if horizontal < -swipeThreshold {
                                viewModel.goForward()
                            } else if horizontal > swipeThreshold {
                                viewModel.goBackward()
                            }
                        }
                )
                .padding(.horizontal, 4)

                // Navigation bar
                MoveNavigationBar(
                    currentMoveIndex: viewModel.currentMoveIndex,
                    totalMoves: viewModel.game.moves.count,
                    onGoToStart: { viewModel.goToStart() },
                    onPrevious: { viewModel.goBackward() },
                    onNext: { viewModel.goForward() },
                    onGoToEnd: { viewModel.goToEnd() }
                )
                .padding(.horizontal, 16)

                // Eval bar
                EvalBarView(evaluation: viewModel.currentEval)
                    .padding(.horizontal, 16)

                // Move annotation card
                MoveAnnotationCard(
                    move: viewModel.lastMove,
                    annotation: viewModel.currentAnnotation,
                    moveIndex: viewModel.currentMoveIndex
                )
                .padding(.horizontal, 16)

                Spacer(minLength: 16)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Moves Tab

    private var movesTab: some View {
        VStack(spacing: 12) {
            // Compact board at the top
            ChessBoardView(
                position: viewModel.currentPosition,
                playerColor: viewModel.game.playerColor,
                lastMoveFrom: viewModel.lastMove?.from,
                lastMoveTo: viewModel.lastMove?.to
            )
            .frame(height: 200)
            .padding(.horizontal, 60)
            .padding(.top, 8)

            // Move list
            MoveListView(
                moves: viewModel.game.moves,
                annotations: viewModel.game.annotations,
                currentMoveIndex: viewModel.currentMoveIndex,
                onSelectMove: { index in
                    viewModel.goToMove(index)
                }
            )
        }
    }

    // MARK: - Report Tab (placeholder)

    private var reportTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Game summary card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: viewModel.resultIcon)
                            .foregroundColor(viewModel.resultColor)
                        Text("vs. \(viewModel.game.opponentName)")
                            .font(DesignSystem.Fonts.headline(18))
                        Spacer()
                        Text(viewModel.resultText)
                            .font(DesignSystem.Fonts.body(15))
                            .foregroundColor(viewModel.resultColor)
                    }

                    if let event = viewModel.game.event {
                        HStack {
                            if let round = viewModel.game.round {
                                Text("\(event), Round \(round)")
                            } else {
                                Text(event)
                            }
                        }
                        .font(DesignSystem.Fonts.caption())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    }

                    Divider()

                    if let accuracy = viewModel.game.accuracy {
                        HStack {
                            Text("Accuracy")
                                .font(DesignSystem.Fonts.body(15))
                            Spacer()
                            Text("\(Int(accuracy))%")
                                .font(DesignSystem.Fonts.headline(15))
                                .foregroundColor(accuracyColor(accuracy))
                        }
                    }

                    // Move quality summary
                    let brilliant = countMoves(.brilliant)
                    let great = countMoves(.great)
                    let good = countMoves(.good)
                    let inaccuracies = countMoves(.inaccuracy)
                    let mistakes = countMoves(.mistake)
                    let blunders = countMoves(.blunder)

                    HStack {
                        Text("Best Moves")
                            .font(DesignSystem.Fonts.body(15))
                        Spacer()
                        Text("\(brilliant + great) / \(viewModel.game.moves.count)")
                            .font(DesignSystem.Fonts.headline(15))
                    }
                    HStack {
                        Text("Good Moves")
                            .font(DesignSystem.Fonts.body(15))
                        Spacer()
                        Text("\(good)")
                            .font(DesignSystem.Fonts.headline(15))
                    }
                    HStack {
                        Text("Inaccuracies")
                            .font(DesignSystem.Fonts.body(15))
                        Spacer()
                        Text("\(inaccuracies)")
                            .font(DesignSystem.Fonts.headline(15))
                            .foregroundColor(inaccuracies > 0 ? DesignSystem.Colors.warning : .primary)
                    }
                    HStack {
                        Text("Mistakes")
                            .font(DesignSystem.Fonts.body(15))
                        Spacer()
                        Text("\(mistakes)")
                            .font(DesignSystem.Fonts.headline(15))
                            .foregroundColor(mistakes > 0 ? .orange : .primary)
                    }
                    HStack {
                        Text("Blunders")
                            .font(DesignSystem.Fonts.body(15))
                        Spacer()
                        Text("\(blunders)")
                            .font(DesignSystem.Fonts.headline(15))
                            .foregroundColor(blunders > 0 ? DesignSystem.Colors.error : .primary)
                    }
                }
                .padding(DesignSystem.Layout.cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal, 16)

                // Opening section
                if let opening = viewModel.game.opening {
                    sectionCard(title: "Opening", icon: "book.fill") {
                        Text(opening)
                            .font(DesignSystem.Fonts.headline(15))
                            .foregroundColor(.primary)
                    }
                }

                // Placeholder for LLM-generated coaching sections
                sectionCard(title: "Key Takeaways", icon: "target") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Coaching report will be generated after engine analysis.")
                            .font(DesignSystem.Fonts.coaching())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }

                Spacer(minLength: 16)
            }
            .padding(.top, 16)
        }
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
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal, 16)
    }

    private func countMoves(_ classification: MoveClassification) -> Int {
        viewModel.game.annotations.values.filter { $0.classification == classification }.count
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
        GameReviewScreen(viewModel: GameReviewViewModel(game: SampleData.sampleGame))
    }
}
