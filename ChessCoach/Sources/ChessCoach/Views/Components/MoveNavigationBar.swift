import SwiftUI

/// Navigation bar for stepping through moves with a centered play button
struct MoveNavigationBar: View {
    let currentMoveIndex: Int
    let totalMoves: Int
    let onGoToStart: () -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onGoToEnd: () -> Void
    var onAutoPlay: (() -> Void)?

    /// Timer for auto-play on long press
    @State private var autoPlayTimer: Timer?
    @State private var isAutoPlaying = false

    var body: some View {
        HStack(spacing: 16) {
            // Go to start
            smallNavButton(systemName: "backward.end.fill") {
                onGoToStart()
            }
            .disabled(currentMoveIndex == 0)

            // Previous
            smallNavButton(systemName: "chevron.left") {
                onPrevious()
            }
            .disabled(currentMoveIndex == 0)

            Spacer()

            // Centered Play/Pause button
            Button {
                if isAutoPlaying {
                    stopAutoPlay()
                } else {
                    startAutoPlay()
                }
            } label: {
                Image(systemName: isAutoPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(DesignSystem.Colors.primary)
                    )
            }

            Spacer()

            // Next
            smallNavButton(systemName: "chevron.right") {
                onNext()
            }
            .disabled(currentMoveIndex >= totalMoves)

            // Go to end
            smallNavButton(systemName: "forward.end.fill") {
                onGoToEnd()
            }
            .disabled(currentMoveIndex >= totalMoves)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.08))
        )
        .onDisappear {
            stopAutoPlay()
        }
    }

    @ViewBuilder
    private func smallNavButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.gray.opacity(0.6))
                .frame(width: DesignSystem.Layout.minTouchTarget,
                       height: DesignSystem.Layout.minTouchTarget)
        }
    }

    private func startAutoPlay() {
        isAutoPlaying = true
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if currentMoveIndex >= totalMoves {
                stopAutoPlay()
            } else {
                onNext()
            }
        }
    }

    private func stopAutoPlay() {
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
        isAutoPlaying = false
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
