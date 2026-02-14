import SwiftUI

/// ChessCoach design system constants
enum DesignSystem {

    // MARK: - Colors

    enum Colors {
        static let primary = Color(red: 0.106, green: 0.302, blue: 0.478) // #1B4D7A
        static let accent = Color(red: 0.961, green: 0.651, blue: 0.137) // #F5A623

        static let boardLight = Color(red: 0.941, green: 0.851, blue: 0.710) // #F0D9B5
        static let boardDark = Color(red: 0.710, green: 0.533, blue: 0.388) // #B58863

        static let lastMoveHighlightLight = Color(red: 0.804, green: 0.820, blue: 0.412).opacity(0.5)
        static let lastMoveHighlightDark = Color(red: 0.690, green: 0.714, blue: 0.271).opacity(0.5)

        static let success = Color(red: 0.298, green: 0.686, blue: 0.314) // #4CAF50
        static let warning = Color(red: 1.0, green: 0.757, blue: 0.027) // #FFC107
        static let error = Color(red: 0.957, green: 0.263, blue: 0.212) // #F44336

        static let backgroundLight = Color(red: 0.980, green: 0.980, blue: 0.980) // #FAFAFA
        static let backgroundDark = Color(red: 0.102, green: 0.102, blue: 0.180) // #1A1A2E

        static let cardBackground = Color(red: 1.0, green: 1.0, blue: 1.0)
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
