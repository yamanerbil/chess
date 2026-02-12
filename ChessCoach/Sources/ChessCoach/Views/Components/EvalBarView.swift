import SwiftUI

/// Horizontal evaluation bar showing the position assessment
struct EvalBarView: View {
    /// Evaluation in centipawns (positive = white advantage)
    let evaluation: Double
    /// Whether to show as winning percentage instead of centipawns
    @State private var showAsPercentage = false

    /// Convert centipawn eval to a 0-1 white advantage fraction
    private var whiteFraction: Double {
        // Use a sigmoid-like function to map eval to 0..1
        // This gives a natural-looking bar that doesn't max out immediately
        let clampedEval = max(-10.0, min(10.0, evaluation))
        return 1.0 / (1.0 + exp(-0.5 * clampedEval))
    }

    /// Convert eval to winning percentage
    private var winningPercentage: Int {
        Int(round(whiteFraction * 100))
    }

    /// Display text for the evaluation
    private var evalText: String {
        if showAsPercentage {
            let whitePercent = winningPercentage
            if whitePercent >= 50 {
                return "White: \(whitePercent)%"
            } else {
                return "Black: \(100 - whitePercent)%"
            }
        } else {
            if evaluation > 0 {
                return "+\(String(format: "%.1f", evaluation))"
            } else if evaluation < 0 {
                return String(format: "%.1f", evaluation)
            } else {
                return "0.0"
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background (black side)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0.2, green: 0.2, blue: 0.25))

                // White advantage fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
                    .frame(width: geometry.size.width * whiteFraction)
                    .animation(.easeInOut(duration: 0.4), value: whiteFraction)

                // Eval text
                HStack {
                    Spacer()
                    Text(evalText)
                        .font(DesignSystem.Fonts.moveNotation(12))
                        .foregroundColor(whiteFraction > 0.5 ? .black : .white)
                        .padding(.horizontal, 8)
                    Spacer()
                }
            }
        }
        .frame(height: 24)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showAsPercentage.toggle()
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        EvalBarView(evaluation: 1.3)
        EvalBarView(evaluation: 0.0)
        EvalBarView(evaluation: -2.5)
        EvalBarView(evaluation: 0.3)
    }
    .padding()
}
