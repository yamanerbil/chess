# Chess Coach App

iOS app helping kids in chess tournaments replay games 
and get AI coaching feedback.

## Key Docs
- UI/UX spec: SPEC.md (screens, wireframes, design system, gestures)
- Technical spec: TECHNICAL-SPEC.md (architecture, data models, AI prompts, implementation phases)
- Read both before implementing any new feature

## Stack
- SwiftUI (iOS 17+)
- Stockfish 17 via ChessKitEngine (on-device, iOS + macOS) for position evaluation
- Claude API for AI coaching explanations
- SwiftData for local persistence
- Apple Vision for scoresheet OCR

## Critical Rules
- Never expose raw Stockfish eval numbers to the user
- AI coaching must be calibrated to kid's age and rating
- Stockfish on-device; Claude API calls are lazy-loaded and cached
- Lead with positives — even when explaining mistakes
- Follow the design system in SPEC.md (colors, typography, animations)

## Current Status
- Home, Progress, Settings, Scanner, and Coaching views started
- Stockfish integration: ChessEngine protocol, ChessKitStockfishEngine adapter,
  GameAnalysisService (move classification, full-game analysis), toFEN support
- Next: Claude API integration for coaching explanations

## Stockfish NNUE Setup (optional, for full-strength eval)
1. Download `nn-1111cefa1111.nnue` + `nn-37f18f62d772.nnue` from https://tests.stockfishchess.org/nns
2. Add to app bundle (drag into Xcode project, check "Copy items if needed")
3. ChessKitStockfishEngine auto-detects them at runtime
4. Without NNUE files, Stockfish uses classical eval (~3000 Elo, still very strong)
