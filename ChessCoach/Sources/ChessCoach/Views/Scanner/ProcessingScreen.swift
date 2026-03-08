import SwiftUI
import CoreGraphics

/// Scanner processing screen — performs OCR on captured scoresheet images
struct ProcessingScreen: View {
    let images: [CGImage]
    let onComplete: ([ScannedMove]) -> Void

    @State private var animationPhase: CGFloat = 0
    @State private var progressValue: CGFloat = 0
    @State private var tipIndex = 0
    @State private var statusText = "Reading your moves..."
    @State private var ocrError: String? = nil

    let tips = [
        "Flatten the sheet for best results",
        "Good lighting helps!",
        "Clear handwriting makes scanning easier",
        "We can handle most scoresheet formats",
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated chess pieces walking across
            ZStack {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 2)
                    .padding(.horizontal, 40)

                HStack(spacing: 24) {
                    PieceWalker(symbol: "\u{265F}\u{FE0E}", delay: 0.0, phase: animationPhase)
                    PieceWalker(symbol: "\u{265E}", delay: 0.3, phase: animationPhase)
                    PieceWalker(symbol: "\u{265F}\u{FE0E}", delay: 0.6, phase: animationPhase)
                }
            }
            .frame(height: 60)

            // Status text
            Text(statusText)
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

            // Error message
            if let error = ocrError {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.orange)
                    Text(error)
                        .font(DesignSystem.Fonts.body(14))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
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
            performOCR()
        }
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            animationPhase = 1
        }

        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.5)) {
                tipIndex = (tipIndex + 1) % tips.count
            }
            if progressValue >= 1.0 {
                timer.invalidate()
            }
        }
    }

    private func performOCR() {
        guard !images.isEmpty else {
            ocrError = "No image captured. Please try again."
            return
        }

        // Animate progress to ~30% quickly (image loaded)
        withAnimation(.easeOut(duration: 0.5)) {
            progressValue = 0.3
        }

        Task {
            do {
                // Process each page and combine results
                var allMoves: [ScannedMove] = []

                for (pageIndex, image) in images.enumerated() {
                    await MainActor.run {
                        statusText = images.count > 1
                            ? "Reading page \(pageIndex + 1) of \(images.count)..."
                            : "Reading your moves..."
                        withAnimation(.easeOut(duration: 0.3)) {
                            progressValue = 0.3 + 0.5 * CGFloat(pageIndex) / CGFloat(images.count)
                        }
                    }

                    // Save the scoresheet image as PNG
                    ScoresheetOCR.saveImage(image)

                    // Run OCR
                    let rawText = try await ScoresheetOCR.recognizeText(from: image)
                    let pageMoves = ScoresheetOCR.parseMoves(from: rawText)

                    // Renumber moves continuing from previous pages
                    let offset = allMoves.count
                    for move in pageMoves {
                        let adjustedIndex = offset + (allMoves.count - offset)
                        let color: PieceColor = (adjustedIndex % 2 == 0) ? .white : .black
                        let moveNumber = (adjustedIndex / 2) + 1
                        allMoves.append(ScannedMove(
                            san: move.san,
                            moveNumber: moveNumber,
                            color: color,
                            status: .valid
                        ))
                    }
                }

                await MainActor.run {
                    statusText = "Done! Found \(allMoves.count) moves"
                    withAnimation(.easeOut(duration: 0.3)) {
                        progressValue = 1.0
                    }
                }

                // Brief pause to show completion
                try await Task.sleep(nanoseconds: 600_000_000)

                await MainActor.run {
                    if allMoves.isEmpty {
                        ocrError = "No chess moves found. Try scanning again or enter moves manually."
                    } else {
                        onComplete(allMoves)
                    }
                }

            } catch {
                await MainActor.run {
                    statusText = "Scan failed"
                    ocrError = "Could not read the scoresheet: \(error.localizedDescription)"
                    progressValue = 0
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
        ProcessingScreen(images: []) { moves in
            print("Got \(moves.count) moves")
        }
    }
}
