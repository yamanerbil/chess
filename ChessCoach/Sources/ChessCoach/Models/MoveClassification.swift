import SwiftUI

/// Classification of a move's quality based on engine analysis
enum MoveClassification: String, Codable, CaseIterable {
    case brilliant
    case great
    case good
    case inaccuracy
    case mistake
    case blunder

    var label: String {
        switch self {
        case .brilliant: return "Brilliant"
        case .great: return "Great"
        case .good: return "Good"
        case .inaccuracy: return "Inaccuracy"
        case .mistake: return "Mistake"
        case .blunder: return "Blunder"
        }
    }

    /// Friendly coaching title shown in the annotation card
    var friendlyTitle: String {
        switch self {
        case .brilliant: return "Brilliant Move!"
        case .great: return "Great Idea!"
        case .good: return "Solid Move"
        case .inaccuracy: return "Small Slip"
        case .mistake: return "Needs Work"
        case .blunder: return "Watch Out!"
        }
    }

    /// Category tag for the annotation card badge
    var category: String {
        switch self {
        case .brilliant: return "Tactical"
        case .great: return "Tactical"
        case .good: return "Positional"
        case .inaccuracy: return "Positional"
        case .mistake: return "Strategic"
        case .blunder: return "Critical"
        }
    }

    var icon: String {
        switch self {
        case .brilliant: return "sparkles"
        case .great: return "star.fill"
        case .good: return "checkmark.circle.fill"
        case .inaccuracy: return "exclamationmark.triangle.fill"
        case .mistake: return "xmark.circle.fill"
        case .blunder: return "bolt.fill"
        }
    }

    var color: Color {
        switch self {
        case .brilliant: return .purple
        case .great: return Color(red: 0.30, green: 0.69, blue: 0.31) // #4CAF50
        case .good: return Color(red: 0.55, green: 0.76, blue: 0.29)
        case .inaccuracy: return Color(red: 1.0, green: 0.76, blue: 0.03) // #FFC107
        case .mistake: return .orange
        case .blunder: return Color(red: 0.96, green: 0.26, blue: 0.21) // #F44336
        }
    }
}

/// Annotation for a single move with engine analysis results
struct MoveAnnotation: Identifiable, Codable {
    let id: UUID
    let classification: MoveClassification
    /// Plain language explanation of the move
    let explanation: String
    /// What the engine recommends as best
    let bestMove: String?
    /// Evaluation after this move in centipawns (positive = white advantage)
    let evalAfter: Double
    /// Top engine lines (SAN strings)
    let engineLines: [String]

    init(
        id: UUID = UUID(),
        classification: MoveClassification,
        explanation: String,
        bestMove: String? = nil,
        evalAfter: Double,
        engineLines: [String] = []
    ) {
        self.id = id
        self.classification = classification
        self.explanation = explanation
        self.bestMove = bestMove
        self.evalAfter = evalAfter
        self.engineLines = engineLines
    }
}
