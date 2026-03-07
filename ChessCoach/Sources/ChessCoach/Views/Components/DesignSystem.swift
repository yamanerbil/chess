import SwiftUI

/// ChessCoach design system constants
enum DesignSystem {

    // MARK: - Colors

    enum Colors {
        static let primary = Color(red: 0.20, green: 0.45, blue: 0.85) // Blue accent
        static let accent = Color(red: 0.961, green: 0.651, blue: 0.137) // #F5A623

        // Green/cream board (chess.com style)
        static let boardLight = Color(red: 0.93, green: 0.93, blue: 0.82) // #EEEED2
        static let boardDark = Color(red: 0.46, green: 0.59, blue: 0.34) // #769656

        // Last move highlights (yellow-green tint)
        static let lastMoveHighlightLight = Color(red: 0.72, green: 0.77, blue: 0.38).opacity(0.7)
        static let lastMoveHighlightDark = Color(red: 0.47, green: 0.55, blue: 0.22).opacity(0.7)

        static let success = Color(red: 0.298, green: 0.686, blue: 0.314) // #4CAF50
        static let warning = Color(red: 1.0, green: 0.757, blue: 0.027) // #FFC107
        static let error = Color(red: 0.957, green: 0.263, blue: 0.212) // #F44336

        static let backgroundLight = Color(red: 0.96, green: 0.97, blue: 0.98) // #F5F7FA
        static let backgroundDark = Color(red: 0.102, green: 0.102, blue: 0.180) // #1A1A2E

        static let cardBackground = Color.white
        static let secondaryText = Color.secondary
    }

    // MARK: - Typography

    enum Fonts {
        static func headline(_ size: CGFloat = 20) -> Font {
            .system(size: size, weight: .bold, design: .rounded)
        }

        static func body(_ size: CGFloat = 17) -> Font {
            .system(size: size, weight: .regular, design: .default)
        }

        static func moveNotation(_ size: CGFloat = 15) -> Font {
            .system(size: size, weight: .medium, design: .monospaced)
        }

        static func coaching(_ size: CGFloat = 17) -> Font {
            .system(size: size, weight: .regular, design: .default)
        }

        static func caption(_ size: CGFloat = 13) -> Font {
            .system(size: size, weight: .regular, design: .default)
        }
    }

    // MARK: - Layout

    enum Layout {
        static let cornerRadius: CGFloat = 12
        static let cardPadding: CGFloat = 16
        static let minTouchTarget: CGFloat = 44
    }
}

/// Renders a chess piece in "club" style — white pieces have a white fill
/// with a black outline, black pieces are solid dark with a subtle outline.
/// Uses the filled Unicode symbols for consistent sizing across all piece types.
struct PieceIconView: View {
    let piece: ChessPiece
    let size: CGFloat

    /// All pieces use the filled (black) Unicode symbols for consistent shape
    private var symbol: String {
        switch piece.type {
        case .king: return "\u{265A}"   // ♚
        case .queen: return "\u{265B}"  // ♛
        case .rook: return "\u{265C}"   // ♜
        case .bishop: return "\u{265D}" // ♝
        case .knight: return "\u{265E}" // ♞
        case .pawn: return "\u{265F}\u{FE0E}" // ♟︎ with text variant selector
        }
    }

    var body: some View {
        ZStack {
            if piece.color == .white {
                // Black outline layer (rendered slightly larger via shadows)
                Text(symbol)
                    .font(.system(size: size * 0.85))
                    .foregroundColor(.black)
                    .shadow(color: .black, radius: 0, x: 0.5, y: 0)
                    .shadow(color: .black, radius: 0, x: -0.5, y: 0)
                    .shadow(color: .black, radius: 0, x: 0, y: 0.5)
                    .shadow(color: .black, radius: 0, x: 0, y: -0.5)

                // White fill layer on top
                Text(symbol)
                    .font(.system(size: size * 0.82))
                    .foregroundColor(.white)
            } else {
                // Solid dark piece with subtle outline
                Text(symbol)
                    .font(.system(size: size * 0.85))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .shadow(color: .black.opacity(0.5), radius: 0, x: 0.5, y: 0.5)
            }
        }
        .minimumScaleFactor(0.7)
        .frame(width: size, height: size)
        .lineLimit(1)
    }
}
