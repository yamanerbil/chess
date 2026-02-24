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
        guard let idx = selectedMoveIndex, idx < positions.count else {
            return positions.last ?? .initial
        }
        return positions[idx + 1 < positions.count ? idx + 1 : positions.count - 1]
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

    /// Whether all moves are valid
    var allValid: Bool { issueCount == 0 }

    /// Suggestions for the currently selected move
    var suggestions: [ChessMove] {
        guard let idx = selectedMoveIndex, idx < positions.count else { return [] }
        let pos = positions[idx]
        let scanned = scannedMoves[idx]
        return pos.similarLegalMoves(to: scanned.san, maxResults: 4)
    }

    init(scannedMoves: [ScannedMove]) {
        self.scannedMoves = scannedMoves
        revalidateAll()
    }

    /// Revalidate all moves from scratch, rebuilding positions
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
                // Can't continue validation after an illegal move
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
                scannedMoves[i].status = .illegal
                // Moves after an illegal move can't be validated
                for j in (i+1)..<scannedMoves.count {
                    scannedMoves[j].status = .illegal
                }
                return
            }
        }
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
