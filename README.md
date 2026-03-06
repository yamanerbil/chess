# ChessCoach

A chess coaching app for scholastic players (ages 6-18) and their parents. Scan or enter tournament games, get move-by-move analysis, and track improvement over time.

## Features

- **Scoresheet Scanner** - Capture paper scoresheets with your camera and auto-recognize moves
- **Manual Move Entry** - Type in games from notation with smart validation and correction suggestions
- **Game Review** - Interactive board with move navigation, evaluation bar, and move classifications (brilliant through blunder)
- **Coaching Reports** - Phase-by-phase analysis (opening, middlegame, endgame) with age-appropriate feedback
- **Game Library** - Browse past games filtered by tournament, with accuracy stats and opening info
- **Progress Tracking** - Accuracy trends and performance statistics over time

## Tech Stack

- **Swift / SwiftUI** - Declarative UI with `@Observable` state management
- **SwiftData** - Persistent storage for games and player profiles
- **Swift Package Manager** - Dependency management
- **XcodeGen** - Project generation from `project.yml`

## Requirements

- iOS 17.0+ / macOS 14.0+
- Xcode 15+
- Swift 5.9+

## Getting Started

1. Clone the repo
2. Open `ChessCoach/` in Xcode (or generate the project with `xcodegen` using `project.yml`)
3. Select your target device and hit Run

## Project Structure

```
ChessCoach/Sources/ChessCoach/
├── App/                  # App entry point, tab navigation
├── Models/               # Chess logic, game data, persistence models
├── ViewModels/           # Game review & move correction state
└── Views/
    ├── Components/       # Board, eval bar, move list, design system
    ├── Home/             # Game library & metadata entry
    ├── GameReview/       # Main analysis screen
    ├── Scanner/          # Scoresheet capture & OCR flow
    ├── Progress/         # Stats & trends
    ├── Report/           # Coaching report
    └── Settings/         # App preferences
```

## Chess Engine

The app includes a built-in chess engine with:
- Full legal move generation with check/pin detection
- FEN parsing and SAN notation
- Castling, en passant, and promotion support
- Move similarity matching (Levenshtein distance) for OCR error correction

## License

All rights reserved.
