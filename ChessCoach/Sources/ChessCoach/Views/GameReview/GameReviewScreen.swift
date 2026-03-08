import SwiftUI

/// The main Game Review screen — the core screen of ChessCoach
struct GameReviewScreen: View {
    @State var viewModel: GameReviewViewModel

    /// Minimum swipe distance to trigger a move
    private let swipeThreshold: CGFloat = 30

    var body: some View {
        VStack(spacing: 0) {
            // Analysis progress banner
            if viewModel.isAnalyzing {
                analysisProgressBanner
            }

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
                analyzeToolbarButton
            }
        }
        .alert("Analysis Error", isPresented: .init(
            get: { viewModel.analysisError != nil },
            set: { if !$0 { viewModel.analysisError = nil } }
        )) {
            Button("OK") { viewModel.analysisError = nil }
        } message: {
            Text(viewModel.analysisError ?? "")
        }
    }

    // MARK: - Toolbar Analyze Button

    @ViewBuilder
    private var analyzeToolbarButton: some View {
        if viewModel.isAnalyzing {
            ProgressView()
                .scaleEffect(0.8)
        } else if viewModel.hasEngineAnalysis {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(DesignSystem.Colors.success)
                .font(.system(size: 16))
        } else {
            Button {
                Task { await viewModel.runAnalysis() }
            } label: {
                Label("Analyze", systemImage: "cpu")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
        }
    }

    // MARK: - Analysis Progress Banner

    private var analysisProgressBanner: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(.white)

                if let progress = viewModel.analysisProgress {
                    Text(progress.phase.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)

                    Spacer()

                    Text("\(progress.currentMove)/\(progress.totalMoves)")
                        .font(DesignSystem.Fonts.moveNotation(13))
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Text("Preparing analysis...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                }
            }

            // Progress bar
            if let progress = viewModel.analysisProgress {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.2))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: geometry.size.width * progress.fraction)
                            .animation(.easeInOut(duration: 0.3), value: progress.fraction)
                    }
                }
                .frame(height: 3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(DesignSystem.Colors.primary)
    }

    // MARK: - Board Tab

    private var boardTab: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Eval bar (show when annotations exist)
                if viewModel.hasEngineAnalysis || !viewModel.liveAnnotations.isEmpty {
                    EvalBarView(evaluation: viewModel.currentEval)
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                }

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

                // Coaching annotation card or analyze prompt
                if viewModel.currentAnnotation != nil || viewModel.lastMove != nil {
                    MoveAnnotationCard(
                        move: viewModel.lastMove,
                        annotation: viewModel.currentAnnotation,
                        moveIndex: viewModel.currentMoveIndex,
                        hasCoaching: viewModel.currentMoveHasCoaching,
                        isLoadingCoaching: viewModel.isLoadingCoaching,
                        onRequestCoaching: viewModel.hasEngineAnalysis ? {
                            Task { await viewModel.requestCoaching() }
                        } : nil
                    )
                    .padding(.horizontal, 16)
                } else if !viewModel.hasEngineAnalysis && viewModel.liveAnnotations.isEmpty {
                    analyzePromptCard
                        .padding(.horizontal, 16)
                }

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

                Spacer(minLength: 8)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Analyze Prompt Card

    private var analyzePromptCard: some View {
        Button {
            Task { await viewModel.runAnalysis() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "cpu")
                    .font(.system(size: 24))
                    .foregroundColor(DesignSystem.Colors.primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Analyze with Stockfish")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("Get move-by-move feedback")
                        .font(.system(size: 13))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Move Chip List

    private var moveChipList: some View {
        VStack(spacing: 8) {
            // Header with analysis stats
            HStack {
                Text("MOVE LIST")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.secondaryText)

                // Quick stats after analysis
                if viewModel.hasEngineAnalysis {
                    let stats = viewModel.analysisStats
                    HStack(spacing: 6) {
                        if stats.blunderCount > 0 {
                            statBadge(count: stats.blunderCount, color: MoveClassification.blunder.color, icon: "bolt.fill")
                        }
                        if stats.mistakeCount > 0 {
                            statBadge(count: stats.mistakeCount, color: MoveClassification.mistake.color, icon: "xmark.circle.fill")
                        }
                        if stats.brilliantCount > 0 {
                            statBadge(count: stats.brilliantCount, color: MoveClassification.brilliant.color, icon: "sparkles")
                        }
                    }
                }

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
    private func statBadge(count: Int, color: Color, icon: String) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text("\(count)")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(color)
    }

    @ViewBuilder
    private func moveChip(move: ChessMove, index: Int) -> some View {
        let isSelected = viewModel.currentMoveIndex == index
        let annotation = viewModel.liveAnnotations[index - 1]
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
            .overlay(
                // Classification indicator dot
                Group {
                    if let ann = annotation, !isSelected {
                        Circle()
                            .fill(ann.classification.color)
                            .frame(width: 6, height: 6)
                            .offset(x: 0, y: -2)
                    }
                },
                alignment: .topTrailing
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
                annotations: viewModel.liveAnnotations,
                currentMoveIndex: viewModel.currentMoveIndex,
                onSelectMove: { index in
                    viewModel.goToMove(index)
                }
            )
        }
    }

    // MARK: - Report Tab

    private var reportTab: some View {
        CoachingReportView(
            game: viewModel.game,
            gameReport: viewModel.gameReport,
            isGeneratingReport: viewModel.isGeneratingReport,
            onRequestReport: viewModel.hasEngineAnalysis ? {
                Task { await viewModel.requestGameReport() }
            } : nil,
            onJumpToMove: { moveIndex in
                viewModel.goToMove(moveIndex)
                viewModel.selectedTab = .board
            }
        )
    }
}

#Preview {
    NavigationStack {
        GameReviewScreen(viewModel: GameReviewViewModel(game: SampleData.sampleGame))
    }
}
