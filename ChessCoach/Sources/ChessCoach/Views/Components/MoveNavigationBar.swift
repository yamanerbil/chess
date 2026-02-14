import SwiftUI

/// Navigation bar for stepping through moves: |< < MOVE N > >|
struct MoveNavigationBar: View {
    let currentMoveIndex: Int
    let totalMoves: Int
    let onGoToStart: () -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onGoToEnd: () -> Void

    /// Timer for auto-play on long press
    @State private var autoPlayTimer: Timer?
    @State private var isAutoPlayingForward = false
    @State private var isAutoPlayingBackward = false

    private var moveLabel: String {
        if currentMoveIndex == 0 {
            return "START"
        }
        return "MOVE \(currentMoveIndex)"
    }

    var body: some View {
        HStack(spacing: 0) {
            // Go to start
            navButton(systemName: "backward.end.fill") {
                onGoToStart()
            }
            .disabled(currentMoveIndex == 0)

            Spacer()

            // Previous
            navButton(systemName: "chevron.left") {
                onPrevious()
            }
            .disabled(currentMoveIndex == 0)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.4)
                    .onEnded { _ in startAutoPlay(forward: false) }
            )

            Spacer()

            // Move indicator
            Text(moveLabel)
                .font(DesignSystem.Fonts.moveNotation(14))
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .frame(minWidth: 80)

            Spacer()

            // Next
            navButton(systemName: "chevron.right") {
                onNext()
            }
            .disabled(currentMoveIndex >= totalMoves)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.4)
                    .onEnded { _ in startAutoPlay(forward: true) }
            )

            Spacer()

            // Go to end
            navButton(systemName: "forward.end.fill") {
                onGoToEnd()
            }
            .disabled(currentMoveIndex >= totalMoves)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                .fill(Color.gray.opacity(0.12))
        )
        .onDisappear {
            stopAutoPlay()
        }
    }

    @ViewBuilder
    private func navButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: DesignSystem.Layout.minTouchTarget,
                       height: DesignSystem.Layout.minTouchTarget)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in stopAutoPlay() }
        )
    }

    private func startAutoPlay(forward: Bool) {
        stopAutoPlay()
        if forward {
            isAutoPlayingForward = true
        } else {
            isAutoPlayingBackward = true
        }
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            if forward {
                onNext()
            } else {
                onPrevious()
            }
        }
    }

    private func stopAutoPlay() {
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
        isAutoPlayingForward = false
        isAutoPlayingBackward = false
    }
}

#Preview {
    MoveNavigationBar(
        currentMoveIndex: 14,
        totalMoves: 27,
        onGoToStart: {},
        onPrevious: {},
        onNext: {},
        onGoToEnd: {}
    )
    .padding()
}
