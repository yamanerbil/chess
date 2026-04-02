import SwiftUI
import Observation

/// Represents a scanned move that may need correction
struct ScannedMove: Identifiable {
    let id = UUID()
    var san: String
    var moveNumber: Int
    var color: PieceColor
    var status: MoveStatus

    enum MoveStatus {
        case valid       // Legal move, high confidence
        case suspicious  // Legal but unusual, or low OCR confidence
        case illegal     // Not a legal move at this position
    }
}

/// View model for the Move Correction screen
@Observable
final class MoveCorrectionViewModel {
    var scannedMoves: [ScannedMove]
    var positions: [BoardPosition] = [.initial]
    var selectedMoveIndex: Int? = nil
    var editingText: String = ""
    var isEditing: Bool = false

    /// The position at the currently selected move (or start)
    var currentPosition: BoardPosition {
        guard let idx = selectedMoveIndex, !positions.isEmpty else {
            return positions.last ?? .initial
        }
        let posIdx = min(idx + 1, positions.count - 1)
        return positions[max(0, posIdx)]
    }

    /// Position BEFORE the selected move (for showing legal moves)
    var positionBeforeSelected: BoardPosition {
        guard let idx = selectedMoveIndex, idx < positions.count else {
            return positions.last ?? .initial
        }
        return positions[min(idx, positions.count - 1)]
    }

    /// Number of issues (illegal + suspicious)
    var issueCount: Int {
        scannedMoves.filter { $0.status == .illegal || $0.status == .suspicious }.count
    }

    /// Index of the first problem move
    var firstIssueIndex: Int? {
        scannedMoves.firstIndex { $0.status == .illegal || $0.status == .suspicious }
    }

    /// Whether all moves are valid (or auto-corrected)
    var allValid: Bool { issueCount == 0 }

    /// Count of auto-corrected (suspicious) moves
    var suspiciousCount: Int {
        scannedMoves.filter { $0.status == .suspicious }.count
    }

    /// Count of truly illegal moves
    var illegalCount: Int {
        scannedMoves.filter { $0.status == .illegal }.count
    }

    /// Human-readable issue description for the bottom bar
    var issueDescription: String {
        let illegal = illegalCount
        let suspicious = suspiciousCount
        var parts: [String] = []
        if illegal > 0 { parts.append("\(illegal) unreadable") }
        if suspicious > 0 { parts.append("\(suspicious) auto-corrected") }
        return parts.joined(separator: ", ") + " — review needed"
    }

    /// Accept all auto-corrected moves, changing status from suspicious → valid
    func acceptAllAutoCorrections() {
        for i in 0..<scannedMoves.count {
            if scannedMoves[i].status == .suspicious {
                scannedMoves[i].status = .valid
            }
        }
    }

    /// Suggestions for the currently selected move
    var suggestions: [ChessMove] {
        guard let idx = selectedMoveIndex, idx < positions.count, idx < scannedMoves.count else { return [] }
        let pos = positions[idx]
        let scanned = scannedMoves[idx]
        return pos.similarLegalMoves(to: scanned.san, maxResults: 4)
    }

    init(scannedMoves: [ScannedMove]) {
        self.scannedMoves = scannedMoves
        revalidateAll()
    }

    /// Revalidate all moves from scratch, rebuilding positions.
    /// Attempts automatic correction of OCR errors using game-flow analysis.
    func revalidateAll() {
        positions = [.initial]
        var currentPos = BoardPosition.initial

        for i in 0..<scannedMoves.count {
            let expectedColor: PieceColor = (i % 2 == 0) ? .white : .black
            scannedMoves[i].color = expectedColor
            scannedMoves[i].moveNumber = (i / 2) + 1

            // Make sure position has right active color
            if currentPos.activeColor != expectedColor {
                scannedMoves[i].status = .illegal
                for j in (i+1)..<scannedMoves.count {
                    scannedMoves[j].status = .illegal
                }
                return
            }

            if let move = currentPos.legalMove(forSAN: scannedMoves[i].san) {
                scannedMoves[i].status = .valid
                currentPos = currentPos.applyingMove(move)
                positions.append(currentPos)
            } else {
                // AUTO-CORRECTION: try OCR alternatives before giving up
                if let (correctedSAN, correctedMove) = attemptAutoCorrection(
                    original: scannedMoves[i].san,
                    position: currentPos
                ) {
                    scannedMoves[i].san = correctedSAN
                    scannedMoves[i].status = .suspicious  // mark as auto-corrected
                    currentPos = currentPos.applyingMove(correctedMove)
                    positions.append(currentPos)
                } else {
                    scannedMoves[i].status = .illegal
                    for j in (i+1)..<scannedMoves.count {
                        scannedMoves[j].status = .illegal
                    }
                    return
                }
            }
        }
    }

    /// Try to auto-correct an illegal OCR move by testing common misreadings
    /// against the current position's legal moves.
    private func attemptAutoCorrection(
        original: String,
        position: BoardPosition
    ) -> (String, ChessMove)? {
        let cleaned = original
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: "#", with: "")

        // Strategy 1: Try piece-letter confusion alternatives (Q↔B, N↔M, etc.)
        let alternatives = ScoresheetOCR.ocrAlternatives(for: cleaned)
        for alt in alternatives {
            if let move = position.legalMove(forSAN: alt) {
                return (alt, move)
            }
        }

        // Strategy 2: Try adding/removing capture "x"
        // Kids often omit "x" or add it spuriously
        if cleaned.contains("x") {
            let withoutCapture = cleaned.replacingOccurrences(of: "x", with: "")
            if let move = position.legalMove(forSAN: withoutCapture) {
                return (withoutCapture, move)
            }
        } else if let first = cleaned.first, "KQRBN".contains(first), cleaned.count >= 3 {
            // Try inserting "x" before the destination square
            let insertPos = cleaned.index(cleaned.startIndex, offsetBy: 1)
            let withCapture = String(cleaned[cleaned.startIndex]) + "x" + String(cleaned[insertPos...])
            if let move = position.legalMove(forSAN: withCapture) {
                return (withCapture, move)
            }
        } else if cleaned.count >= 3, cleaned.first?.isLowercase == true {
            // Pawn capture: try inserting "x" after the file letter
            let insertPos = cleaned.index(cleaned.startIndex, offsetBy: 1)
            let withCapture = String(cleaned[cleaned.startIndex]) + "x" + String(cleaned[insertPos...])
            if let move = position.legalMove(forSAN: withCapture) {
                return (withCapture, move)
            }
        }

        // Strategy 3: Swap confused file letters (f↔t, a↔o)
        let fileSwaps: [(Character, Character)] = [
            ("f", "t"), ("t", "f"),
            ("a", "e"), ("e", "a"),
            ("c", "e"), ("e", "c"),
        ]
        for (from, to) in fileSwaps {
            let swapped = String(cleaned.map { $0 == from ? to : $0 })
            if swapped != cleaned, let move = position.legalMove(forSAN: swapped) {
                return (swapped, move)
            }
        }

        // Strategy 4: Try digit confusions for ranks
        let rankSwaps: [(Character, Character)] = [
            ("1", "7"), ("7", "1"),
            ("5", "6"), ("6", "5"),
            ("5", "8"), ("8", "5"),
            ("3", "8"), ("8", "3"),
            ("6", "8"), ("8", "6"),
        ]
        for (from, to) in rankSwaps {
            let swapped = String(cleaned.map { $0 == from ? to : $0 })
            if swapped != cleaned, let move = position.legalMove(forSAN: swapped) {
                return (swapped, move)
            }
        }

        // Strategy 5: Combined — piece swap + capture toggle
        for alt in alternatives {
            if alt.contains("x") {
                let withoutCapture = alt.replacingOccurrences(of: "x", with: "")
                if let move = position.legalMove(forSAN: withoutCapture) {
                    return (withoutCapture, move)
                }
            } else if alt.count >= 3 {
                let insertPos = alt.index(alt.startIndex, offsetBy: 1)
                let withCapture = String(alt[alt.startIndex]) + "x" + String(alt[insertPos...])
                if let move = position.legalMove(forSAN: withCapture) {
                    return (withCapture, move)
                }
            }
        }

        return nil
    }

    /// Replace the SAN at a given index and revalidate
    func updateMove(at index: Int, newSAN: String) {
        guard index < scannedMoves.count else { return }
        scannedMoves[index].san = newSAN
        revalidateAll()
    }

    /// Select a move for editing
    func selectMove(_ index: Int) {
        selectedMoveIndex = index
        editingText = scannedMoves[index].san
        isEditing = true
    }

    /// Apply a suggestion
    func applySuggestion(_ move: ChessMove, at index: Int) {
        let san = move.san.replacingOccurrences(of: "+", with: "").replacingOccurrences(of: "#", with: "")
        updateMove(at: index, newSAN: san)
        isEditing = false
    }

    /// Confirm the current edit
    func confirmEdit(at index: Int) {
        updateMove(at: index, newSAN: editingText)
        isEditing = false
    }
}

// MARK: - Sample scanned data for previews

extension SampleData {
    /// Simulated OCR output with some errors
    static let sampleScannedMoves: [ScannedMove] = [
        ScannedMove(san: "e4", moveNumber: 1, color: .white, status: .valid),
        ScannedMove(san: "e5", moveNumber: 1, color: .black, status: .valid),
        ScannedMove(san: "Nf3", moveNumber: 2, color: .white, status: .valid),
        ScannedMove(san: "Nc6", moveNumber: 2, color: .black, status: .valid),
        ScannedMove(san: "Bb5", moveNumber: 3, color: .white, status: .valid),
        ScannedMove(san: "a6", moveNumber: 3, color: .black, status: .valid),
        ScannedMove(san: "Ba4", moveNumber: 4, color: .white, status: .valid),
        ScannedMove(san: "Ng6", moveNumber: 4, color: .black, status: .illegal),  // OCR error: should be Nf6
        ScannedMove(san: "O-O", moveNumber: 5, color: .white, status: .valid),
        ScannedMove(san: "Be7", moveNumber: 5, color: .black, status: .valid),
    ]
}
