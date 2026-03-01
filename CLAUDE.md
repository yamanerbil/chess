# Chess Coach App

iOS app helping kids in chess tournaments replay games 
and get AI coaching feedback.

## Key Docs
- Technical spec: SPEC.md (root of repo)

## Stack
- SwiftUI (iOS 17+)
- Stockfish (on-device, C++ bridge) for position evaluation
- Claude API for AI coaching explanations
- SwiftData for local persistence
- Apple Vision for scoresheet OCR

## Critical Rules
- Never expose raw Stockfish eval numbers to the user
- AI coaching must be calibrated to kid's age and rating
- Stockfish on-device; Claude API calls are lazy-loaded and cached
- Lead with positives — even when explaining mistakes

## Current Status
- Home, Progress, Settings, Scanner, and Coaching views exist in ChessCoach/
- Next: [whatever you want to tackle next]
