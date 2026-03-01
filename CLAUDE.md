# Chess Coach App

iOS app helping kids in chess tournaments replay games 
and get AI coaching feedback.

## Key Docs
- UI/UX spec: SPEC.md (screens, wireframes, design system, gestures)
- Technical spec: TECHNICAL-SPEC.md (architecture, data models, AI prompts, implementation phases)
- Read both before implementing any new feature

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
- Follow the design system in SPEC.md (colors, typography, animations)

## Current Status
- Home, Progress, Settings, Scanner, and Coaching views started
- Next: [your next priority]
