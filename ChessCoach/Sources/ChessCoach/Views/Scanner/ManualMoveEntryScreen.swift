import SwiftUI

/// Manual move entry screen — allows users to type SAN moves from a paper scoresheet
struct ManualMoveEntryScreen: View {
    @State private var moveText: String = ""
    @FocusState private var isTextFieldFocused: Bool

    let onSubmit: ([ScannedMove]) -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Instructions
            VStack(spacing: 8) {
                Text("Type your moves below")
                    .font(DesignSystem.Fonts.headline(18))
                Text("Enter moves in standard notation, separated by spaces. Move numbers are optional.")
                    .font(DesignSystem.Fonts.body(14))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 8)

            // Example
            Text("Example: e4 e5 Nf3 Nc6 Bb5 a6")
                .font(DesignSystem.Fonts.moveNotation(14))
                .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.7))
                .padding(.horizontal, 20)

            // Text editor for moves
            TextEditor(text: $moveText)
                .font(DesignSystem.Fonts.moveNotation(16))
                .focused($isTextFieldFocused)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 16)

            // Move count indicator
            if !parsedSANs.isEmpty {
                Text("\(parsedSANs.count) moves entered")
                    .font(DesignSystem.Fonts.caption(13))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }

            Spacer()

            // Submit button
            Button(action: submitMoves) {
                HStack {
                    Text("Review Moves")
                        .font(DesignSystem.Fonts.headline(17))
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                        .fill(parsedSANs.isEmpty ? Color.gray : DesignSystem.Colors.primary)
                )
            }
            .disabled(parsedSANs.isEmpty)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .navigationTitle("Enter Moves")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isTextFieldFocused = true
        }
    }

    /// Parse the raw text into SAN move strings, stripping move numbers and annotations
    private var parsedSANs: [String] {
        parseSANMoves(from: moveText)
    }

    private func submitMoves() {
        let sans = parsedSANs
        guard !sans.isEmpty else { return }

        var scannedMoves: [ScannedMove] = []
        for (index, san) in sans.enumerated() {
            let color: PieceColor = (index % 2 == 0) ? .white : .black
            let moveNumber = (index / 2) + 1
            scannedMoves.append(ScannedMove(
                san: san,
                moveNumber: moveNumber,
                color: color,
                status: .valid // will be re-validated by MoveCorrectionViewModel
            ))
        }
        onSubmit(scannedMoves)
    }
}

/// Parse a string of chess moves into individual SAN strings.
/// Handles formats like:
///   "e4 e5 Nf3 Nc6"
///   "1. e4 e5 2. Nf3 Nc6"
///   "1.e4 1...e5 2.Nf3 2...Nc6"
func parseSANMoves(from text: String) -> [String] {
    // Split on whitespace and newlines
    let tokens = text.components(separatedBy: .whitespacesAndNewlines)
        .filter { !$0.isEmpty }

    var results: [String] = []

    for token in tokens {
        var cleaned = token

        // Strip trailing periods or dots from move numbers like "1." or "1..."
        // A pure move number token: digits followed by dots
        if cleaned.allSatisfy({ $0.isNumber || $0 == "." }) {
            continue // skip move number tokens like "1." or "1..."
        }

        // Handle "1.e4" or "1...e5" — move number glued to SAN
        if let dotRange = cleaned.range(of: ".", options: .literal) {
            let prefix = cleaned[cleaned.startIndex..<dotRange.lowerBound]
            if prefix.allSatisfy({ $0.isNumber }) {
                // Strip everything up to and including the last dot
                while cleaned.hasPrefix(".") || cleaned.first?.isNumber == true {
                    cleaned = String(cleaned.dropFirst())
                }
                // Also strip leading dots after the number
                while cleaned.hasPrefix(".") {
                    cleaned = String(cleaned.dropFirst())
                }
            }
        }

        // Skip empty results
        guard !cleaned.isEmpty else { continue }

        // Skip common annotation symbols
        let skipTokens: Set<String> = ["", "+/-", "+-", "-+", "=", "?", "??", "!", "!!", "!?", "?!"]
        if skipTokens.contains(cleaned) { continue }

        // Strip trailing annotation marks (?, !, ??, !!, ?!, !?)
        while cleaned.hasSuffix("?") || cleaned.hasSuffix("!") {
            cleaned = String(cleaned.dropLast())
        }

        guard !cleaned.isEmpty else { continue }

        results.append(cleaned)
    }

    return results
}

#Preview {
    NavigationStack {
        ManualMoveEntryScreen { moves in
            print("Got \(moves.count) moves")
        }
    }
}
