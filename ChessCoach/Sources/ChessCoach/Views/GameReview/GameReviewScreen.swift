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
        .background(DesignSystem.Colors.backgroundLight)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(viewModel.titleText)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .textCase(.uppercase)

                    Text(viewModel.subtitleText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Settings placeholder
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
    }

    // MARK: - Board Tab

    private var boardTab: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Chess board with swipe gestures and shadow
                ChessBoardView(
                    position: viewModel.currentPosition,
                    playerColor: viewModel.game.playerColor,
                    lastMoveFrom: viewModel.lastMove?.from,
                    lastMoveTo: viewModel.lastMove?.to
                )
                .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
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
                .padding(.horizontal, 12)

                // Horizontal move list chips
                moveChipList
                    .padding(.horizontal, 16)

                // Coaching annotation card
                MoveAnnotationCard(
                    move: viewModel.lastMove,
                    annotation: viewModel.currentAnnotation,
                    moveIndex: viewModel.currentMoveIndex
                )
                .padding(.horizontal, 16)

                // Navigation bar with play button
                MoveNavigationBar(
                    currentMoveIndex: viewModel.currentMoveIndex,
                    totalMoves: viewModel.game.moves.count,
                    onGoToStart: { viewModel.goToStart() },
                    onPrevious: { viewModel.goBackward() },
                    onNext: { viewModel.goForward() },
                    onGoToEnd: { viewModel.goToEnd() }
                )
                .padding(.horizontal, 16)

                Spacer(minLength: 8)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Move Chip List

    private var moveChipList: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("MOVE LIST")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                Spacer()
                Button {
                    viewModel.selectedTab = .moves
                } label: {
                    Text("VIEW ALL")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }

            // Scrollable chips
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(viewModel.game.moves.enumerated()), id: \.offset) { index, move in
                            let chipIndex = index + 1
                            moveChip(move: move, index: chipIndex)
                                .id(chipIndex)
                        }
                    }
                }
                .onChange(of: viewModel.currentMoveIndex) { _, newValue in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func moveChip(move: ChessMove, index: Int) -> some View {
        let isSelected = viewModel.currentMoveIndex == index
        let moveNum = move.color == .white
            ? "\(move.moveNumber)."
            : "\(move.moveNumber)..."

        Button {
            viewModel.goToMove(index)
        } label: {
            HStack(spacing: 3) {
                Text(moveNum)
                    .font(DesignSystem.Fonts.moveNotation(12))
                if move.piece.type != .pawn {
                    PieceIconView(piece: move.piece, size: 14)
                }
                Text(move.san.dropPiecePrefix())
                    .font(DesignSystem.Fonts.moveNotation(12))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? DesignSystem.Colors.primary : Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Moves Tab

    private var movesTab: some View {
        VStack(spacing: 12) {
            // Compact board at the top
            ChessBoardView(
                position: viewModel.currentPosition,
                playerColor: viewModel.game.playerColor,
                lastMoveFrom: viewModel.lastMove?.from,
                lastMoveTo: viewModel.lastMove?.to,
                showCoordinates: false
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
