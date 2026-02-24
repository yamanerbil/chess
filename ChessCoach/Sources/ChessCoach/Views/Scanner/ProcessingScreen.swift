import SwiftUI

/// Scanner processing screen — shown while OCR is running on the scoresheet image
struct ProcessingScreen: View {
    @State private var animationPhase: CGFloat = 0
    @State private var progressValue: CGFloat = 0
    @State private var tipIndex = 0

    let tips = [
        "Flatten the sheet for best results",
        "Good lighting helps!",
        "Clear handwriting makes scanning easier",
        "We can handle most scoresheet formats",
    ]

    let onComplete: ([ScannedMove]) -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated chess pieces walking across
            ZStack {
                // Track line
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 2)
                    .padding(.horizontal, 40)

                HStack(spacing: 24) {
                    PieceWalker(symbol: "♟", delay: 0.0, phase: animationPhase)
                    PieceWalker(symbol: "♞", delay: 0.3, phase: animationPhase)
                    PieceWalker(symbol: "♟", delay: 0.6, phase: animationPhase)
                }
            }
            .frame(height: 60)

            // Status text
            Text("Reading your moves...")
                .font(DesignSystem.Fonts.headline(20))
                .foregroundColor(.primary)

            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DesignSystem.Colors.primary)
                            .frame(width: geo.size.width * progressValue)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 60)

                Text("\(Int(progressValue * 100))%")
                    .font(DesignSystem.Fonts.moveNotation(13))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }

            // Rotating tip
            Text(tips[tipIndex])
                .font(DesignSystem.Fonts.coaching(15))
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .transition(.opacity)
                .id(tipIndex)

            Spacer()
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startAnimations()
            simulateProcessing()
        }
    }

    private func startAnimations() {
        // Chess piece bounce animation
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            animationPhase = 1
        }

        // Tip rotation
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.5)) {
                tipIndex = (tipIndex + 1) % tips.count
            }
            if progressValue >= 1.0 {
                timer.invalidate()
            }
        }
    }

    private func simulateProcessing() {
        // Simulate progress over ~4 seconds
        let steps = 20
        let interval = 4.0 / Double(steps)
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    // Non-linear progress (starts fast, slows near end)
                    let t = Double(i) / Double(steps)
                    progressValue = CGFloat(1 - pow(1 - t, 2.5))
                }
                if i == steps {
                    // Done — deliver sample scanned moves
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onComplete(SampleData.sampleScannedMoves)
                    }
                }
            }
        }
    }
}

// MARK: - Animated piece

private struct PieceWalker: View {
    let symbol: String
    let delay: CGFloat
    let phase: CGFloat

    var body: some View {
        Text(symbol)
            .font(.system(size: 36))
            .offset(y: -bounceOffset)
            .animation(
                .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: phase
            )
    }

    private var bounceOffset: CGFloat {
        phase * 12
    }
}

#Preview {
    NavigationStack {
        ProcessingScreen { moves in
            print("Got \(moves.count) moves")
        }
    }
}
