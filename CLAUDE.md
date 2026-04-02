# Chess Coach App

iOS app helping kids in chess tournaments replay games 
and get AI coaching feedback.

## Key Docs
- UI/UX spec: SPEC.md (screens, wireframes, design system, gestures)
- Technical spec: TECHNICAL-SPEC.md (architecture, data models, AI prompts, implementation phases)
- Read both before implementing any new feature

## Stack
- SwiftUI (iOS 17+, macOS 14+), Swift 5.9
- Stockfish 17 via ChessKitEngine v0.7.0 (on-device, iOS + macOS) for position evaluation
- Claude API for AI coaching explanations + scoresheet OCR (Claude Vision)
- ElevenLabs API for text-to-speech voice coaching
- SwiftData for local persistence
- XcodeGen (project.yml is source of truth for Xcode project)
- API keys via .env + XcodeGen scheme environment variables

## Critical Rules
- Never expose raw Stockfish eval numbers to the user
- AI coaching must be calibrated to kid's age and rating
- Stockfish on-device; Claude API calls are lazy-loaded and cached
- Lead with positives — even when explaining mistakes
- Follow the design system in SPEC.md (colors, typography, animations)

## Current Status
- **Views**: Home, Progress, Settings, Scanner (camera + OCR + correction), GameReview, Report — all implemented
- **iPad support**: Side-by-side layout in GameReviewScreen using horizontalSizeClass
- **Stockfish**: ChessKitStockfishEngine adapter, GameAnalysisService (move classification, full-game analysis), FEN support
- **Claude API**: ClaudeCoachService for coaching explanations, lazy-loaded and cached
- **Scoresheet OCR**: Claude Vision (replaced Apple Vision) with game-flow-aware auto-correction for kids' handwriting
- **Voice coaching**: ElevenLabs TTS via VoiceCoachService with adaptive tone (celebratory for brilliant moves, supportive for mistakes, adjusted for game outcome)
- **Best move arrows**: Canvas-drawn arrows on ChessBoardView showing suggested moves for misplays
- **Move classification**: Brilliant → blunder scale with color coding and voice settings per classification

## Stockfish NNUE Setup (optional, for full-strength eval)
1. Download `nn-1111cefa1111.nnue` + `nn-37f18f62d772.nnue` from https://tests.stockfishchess.org/nns
2. Add to app bundle (drag into Xcode project, check "Copy items if needed")
3. ChessKitStockfishEngine auto-detects them at runtime
4. Without NNUE files, Stockfish uses classical eval (~3000 Elo, still very strong)
