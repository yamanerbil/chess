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

    // MARK: - Report Tab

    private var reportTab: some View {
        CoachingReportView(game: viewModel.game) { moveIndex in
            viewModel.goToMove(moveIndex)
            viewModel.selectedTab = .board
        }
    }
}

#Preview {
    NavigationStack {
        GameReviewScreen(viewModel: GameReviewViewModel(game: SampleData.sampleGame))
    }
}
