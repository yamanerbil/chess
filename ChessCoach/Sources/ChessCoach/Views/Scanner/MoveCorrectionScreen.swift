import SwiftUI

/// Move Correction & Validation screen — users verify and fix OCR'd moves
struct MoveCorrectionScreen: View {
    @State var viewModel: MoveCorrectionViewModel
    @Environment(\.dismiss) private var dismiss

    let onDone: ([ScannedMove]) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Mini board showing position at selected move
            ChessBoardView(
                position: viewModel.currentPosition,
                playerColor: .white,
                lastMoveFrom: nil,
                lastMoveTo: nil
            )
            .frame(height: 200)
            .padding(.horizontal, 60)
            .padding(.top, 8)
            .padding(.bottom, 8)

            Divider()

            // Move list in two-column scoresheet format
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        HStack(spacing: 0) {
                            Text("#")
                                .frame(width: 32, alignment: .center)
                            Text("White")
                                .frame(maxWidth: .infinity, alignment: .center)
                            Text("Black")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .font(DesignSystem.Fonts.caption(12))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)

                        Divider()

                        // Move rows
                        let pairs = movePairs
                        ForEach(pairs.indices, id: \.self) { pairIndex in
                            let pair = pairs[pairIndex]
                            HStack(spacing: 0) {
                                // Move number
                                Text("\(pair.moveNumber).")
                                    .font(DesignSystem.Fonts.moveNotation(13))
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .frame(width: 32, alignment: .center)

                                // White move
                                MoveCellView(
                                    move: pair.white,
                                    index: pair.whiteIndex,
                                    isSelected: viewModel.selectedMoveIndex == pair.whiteIndex,
                                    onTap: {
                                        viewModel.selectMove(pair.whiteIndex)
                                    }
                                )
                                .frame(maxWidth: .infinity)

                                // Black move
                                if let blackMove = pair.black, let blackIndex = pair.blackIndex {
                                    MoveCellView(
                                        move: blackMove,
                                        index: blackIndex,
                                        isSelected: viewModel.selectedMoveIndex == blackIndex,
                                        onTap: {
                                            viewModel.selectMove(blackIndex)
                                        }
                                    )
                                    .frame(maxWidth: .infinity)
                                } else {
                                    Spacer()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 16)
                            .id(pairIndex)

                            if pairIndex < pairs.count - 1 {
                                Divider().padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.bottom, 16)
                }
                .onChange(of: viewModel.selectedMoveIndex) { _, newValue in
                    if let idx = newValue {
                        withAnimation {
                            proxy.scrollTo(idx / 2, anchor: .center)
                        }
                    }
                }
            }

            // Inline editor (when editing)
            if viewModel.isEditing, let idx = viewModel.selectedMoveIndex {
                Divider()
                moveEditorView(at: idx)
            }

            Divider()

            // Bottom bar
            bottomBar
        }
        .navigationTitle("Review Moves")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    onDone(viewModel.scannedMoves)
                }
                .disabled(!viewModel.allValid)
                .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Move Pairs

    private struct MovePair {
        let moveNumber: Int
        let white: ScannedMove
        let whiteIndex: Int
        let black: ScannedMove?
        let blackIndex: Int?
    }

    private var movePairs: [MovePair] {
        var pairs: [MovePair] = []
        var i = 0
        while i < viewModel.scannedMoves.count {
            let white = viewModel.scannedMoves[i]
            let black: ScannedMove? = (i + 1 < viewModel.scannedMoves.count) ? viewModel.scannedMoves[i + 1] : nil
            pairs.append(MovePair(
                moveNumber: white.moveNumber,
                white: white,
                whiteIndex: i,
                black: black,
                blackIndex: black != nil ? i + 1 : nil
            ))
            i += 2
        }
        return pairs
    }

    // MARK: - Move Editor

    @ViewBuilder
    private func moveEditorView(at index: Int) -> some View {
        let move = viewModel.scannedMoves[index]

        VStack(spacing: 10) {
            HStack {
                Text("Move \(move.moveNumber) for \(move.color == .white ? "White" : "Black"):")
                    .font(DesignSystem.Fonts.body(14))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                Spacer()
                Button {
                    viewModel.isEditing = false
                    viewModel.selectedMoveIndex = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }

            // Text field
            HStack {
                TextField("Move notation", text: $viewModel.editingText)
                    .font(DesignSystem.Fonts.moveNotation(18))
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif

                Button {
                    viewModel.confirmEdit(at: index)
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                .frame(width: DesignSystem.Layout.minTouchTarget, height: DesignSystem.Layout.minTouchTarget)
            }

            // Suggestions
            if !viewModel.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Suggestions:")
                        .font(DesignSystem.Fonts.caption(12))
                        .foregroundColor(DesignSystem.Colors.secondaryText)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.suggestions) { suggestion in
                                Button {
                                    viewModel.applySuggestion(suggestion, at: index)
                                } label: {
                                    Text(suggestion.san)
                                        .font(DesignSystem.Fonts.moveNotation(15))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(DesignSystem.Colors.primary.opacity(0.1))
                                        )
                                        .foregroundColor(DesignSystem.Colors.primary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.04))
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            if viewModel.issueCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("\(viewModel.issueCount) issue\(viewModel.issueCount == 1 ? "" : "s") found")
                        .font(DesignSystem.Fonts.body(14))
                }

                Spacer()

                Button {
                    if let idx = viewModel.firstIssueIndex {
                        viewModel.selectMove(idx)
                    }
                } label: {
                    Text("Fix Issues")
                        .font(DesignSystem.Fonts.headline(14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(.orange)
                        )
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.success)
                    Text("All moves valid!")
                        .font(DesignSystem.Fonts.body(14))
                        .foregroundColor(DesignSystem.Colors.success)
                }

                Spacer()

                Button {
                    onDone(viewModel.scannedMoves)
                } label: {
                    Text("Looks Good")
                        .font(DesignSystem.Fonts.headline(14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(DesignSystem.Colors.success)
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Move Cell

private struct MoveCellView: View {
    let move: ScannedMove
    let index: Int
    let isSelected: Bool
    let onTap: () -> Void

    private var statusIcon: String {
        switch move.status {
        case .valid: return ""
        case .suspicious: return "⚠️"
        case .illegal: return "❌"
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return DesignSystem.Colors.primary.opacity(0.15)
        }
        switch move.status {
        case .valid: return .clear
        case .suspicious: return Color.orange.opacity(0.08)
        case .illegal: return Color.red.opacity(0.08)
        }
    }

    private var textColor: Color {
        switch move.status {
        case .valid: return .primary
        case .suspicious: return .orange
        case .illegal: return DesignSystem.Colors.error
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if !statusIcon.isEmpty {
                    Text(statusIcon)
                        .font(.system(size: 12))
                }
                Text(move.san)
                    .font(DesignSystem.Fonts.moveNotation(14))
                    .foregroundColor(textColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        MoveCorrectionScreen(
            viewModel: MoveCorrectionViewModel(scannedMoves: SampleData.sampleScannedMoves)
        ) { moves in
            print("Done with \(moves.count) moves")
        }
    }
}
