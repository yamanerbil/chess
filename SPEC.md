# ChessCoach — UI/UX Specification

## Target Audience

**Scholastic chess players (rated U-400 through 2000) and their parents.**

- Kids ages 6-18 playing in USCF-rated tournaments
- Parents who are invested in their child's chess improvement
- The parent is often the one holding the phone and scanning the scoresheet
- The child reviews the game with (or without) the parent afterward

### Design Implications

- **Big, clear touch targets** — kids' fingers are small and imprecise
- **Minimal text, maximum visual** — a 7-year-old should understand the board screen
- **Parent mode vs Kid mode not needed initially** — keep one simple interface
- **Language in coaching reports should be age-appropriate** — "Your knight was really strong in the center!" not "Centralized knight exerted dominant influence on the d5 outpost"
- **Encouraging tone always** — even when pointing out mistakes, frame as learning moments

---

## App Flow Overview

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   ┌──────────┐    ┌──────────┐    ┌──────────────────┐  │
│   │  My Games │───▶│  Scan    │───▶│ Move Correction  │  │
│   │  (Home)  │    │  Sheet   │    │  & Validation    │  │
│   └──────────┘    └──────────┘    └────────┬─────────┘  │
│        │                                   │            │
│        │          ┌──────────┐             │            │
│        └─────────▶│  Game    │◀────────────┘            │
│                   │  Review  │                          │
│                   └────┬─────┘                          │
│                        │                                │
│                   ┌────▼─────┐                          │
│                   │ Coaching │                          │
│                   │ Report   │                          │
│                   └──────────┘                          │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Screen 1: Home — "My Games"

### Layout

```
┌─────────────────────────────────┐
│ ≡  My Games            [trophy] │  ← nav bar: menu + stats icon
│─────────────────────────────────│
│                                 │
│  [Tournament Filter Chips]      │  ← "All" "Spring Open" "State Ch."
│                                 │
│  ┌─────────────────────────────┐│
│  │ ★ vs. Emma W.    W  1-0    ││  ← game card
│  │ Spring Open Rd 3            ││
│  │ Italian Game · Acc: 78%     ││
│  │ ┌─┬─┬─┬─┬─┬─┬─┬─┐         ││  ← tiny board thumbnail
│  │ └─┴─┴─┴─┴─┴─┴─┴─┘  →      ││     showing final position
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ ★ vs. Jake M.    B  0-1    ││
│  │ Spring Open Rd 2            ││
│  │ Sicilian · Acc: 62%         ││
│  │ ┌─┬─┬─┬─┬─┬─┬─┬─┐         ││
│  │ └─┴─┴─┴─┴─┴─┴─┴─┘  →      ││
│  └─────────────────────────────┘│
│                                 │
│                                 │
│      ┌─────────────────┐       │
│      │  📷 Scan Game   │       │  ← primary CTA, bottom center
│      └─────────────────┘       │
│                                 │
│  [Home]   [Progress]   [Settings]│ ← tab bar
└─────────────────────────────────┘
```

### Behavior

- Games sorted by most recent
- Each card shows: opponent, color played, result, tournament + round, opening name, accuracy %
- Tap a card → goes to Game Review screen
- Color coding on result: green (win), red (loss), gray (draw)
- The accuracy % uses a color gradient: green (>85%), yellow (70-85%), orange (55-70%), red (<55%)
- Tournament filter chips are horizontally scrollable

---

## Screen 2: Scoresheet Scanner

### Step 2a: Camera Capture

```
┌─────────────────────────────────┐
│ ✕  Scan Scoresheet              │
│─────────────────────────────────│
│                                 │
│  ┌─────────────────────────────┐│
│  │                             ││
│  │                             ││
│  │    ┌───────────────────┐    ││
│  │    │                   │    ││  ← viewfinder with
│  │    │   Align your      │    ││    scoresheet guide overlay
│  │    │   scoresheet      │    ││
│  │    │   within the      │    ││
│  │    │   frame           │    ││
│  │    │                   │    ││
│  │    └───────────────────┘    ││
│  │                             ││
│  │                             ││
│  └─────────────────────────────┘│
│                                 │
│   [Flash]    (●)    [Gallery]   │  ← capture controls
│                                 │
└─────────────────────────────────┘
```

- Auto-detect scoresheet edges (like document scanner)
- Dashed guide rectangle to help alignment
- Support capturing from photo library (gallery button)
- Tap to capture → shows processing spinner
- **Tip text rotates**: "Flatten the sheet for best results" / "Good lighting helps!"

### Step 2b: Processing

```
┌─────────────────────────────────┐
│                                 │
│                                 │
│                                 │
│         ♟ ── ♟ ── ♟            │  ← animated chess pieces
│                                 │
│      Reading your moves...      │
│                                 │
│      ░░░░░░░░░░░░░░░░░         │  ← progress bar
│                                 │
│                                 │
│                                 │
└─────────────────────────────────┘
```

- Fun animation while LLM processes the image (chess piece walking across screen, or pieces assembling)
- Typically 3-8 seconds
- Progress bar is estimated, not exact

---

## Screen 3: Move Correction & Validation

This is critical for trust. The OCR won't be perfect, especially with kids' handwriting.

```
┌─────────────────────────────────┐
│ ←  Review Moves         [Done] │
│─────────────────────────────────│
│                                 │
│  ┌─────────────────────────────┐│
│  │      ┌─┬─┬─┬─┬─┬─┬─┬─┐    ││
│  │      │r│n│b│q│k│b│n│r│    ││  ← mini board shows
│  │      │p│p│p│p│p│p│p│p│    ││    position at the
│  │      │ │ │ │ │ │ │ │ │    ││    currently selected
│  │      │ │ │ │ │ │ │ │ │    ││    move
│  │      │ │ │ │ │ │ │ │ │    ││
│  │      │ │ │ │ │ │P│ │ │    ││
│  │      │P│P│P│P│P│ │P│P│    ││
│  │      │R│N│B│Q│K│B│N│R│    ││
│  │      └─┴─┴─┴─┴─┴─┴─┴─┘    ││
│  └─────────────────────────────┘│
│                                 │
│  ┌──────────┬──────────────────┐│
│  │  White   │   Black          ││
│  ├──────────┼──────────────────┤│
│  │ 1. e4    │  1... e5         ││  ← green = validated legal
│  │ 2. Nf3   │  2... Nc6        ││
│  │ 3. Bb5   │  3... a6         ││
│  │ 4. Ba4   │  4... ⚠️ Ng6    ││  ← orange = suspicious
│  │ 5. O-O   │  5... Be7        ││     (maybe Nf6?)
│  │ 6. Re1   │  6... ❌ Kf4    ││  ← red = illegal move
│  │ ...       │                  ││
│  └──────────┴──────────────────┘│
│                                 │
│         3 issues found          │
│     [Fix Issues] [Looks Good]   │
│                                 │
└─────────────────────────────────┘
```

### Behavior

- Moves displayed in two-column scoresheet format (mirrors paper)
- Tapping any move:
  - Shows the board position AT that move
  - Opens inline editor to correct the move text
  - Shows suggestions: "Did you mean Nf6?" (based on legal moves + visual similarity)
- Color coding:
  - **Green**: legal move, high OCR confidence
  - **Orange/Warning**: legal but unusual, or low OCR confidence
  - **Red/Error**: illegal move at that position — must be corrected
- "Fix Issues" button scrolls to first problem
- The board updates in real-time as moves are edited
- After all moves validate, "Done" becomes active

### Move Editor (inline)

```
┌─────────────────────────────────┐
│  Move 4 for Black:              │
│                                 │
│  Current: Ng6                   │
│  ┌─────────────────────────────┐│
│  │ Ng6                    [✓]  ││  ← text field with
│  └─────────────────────────────┘│    chess-optimized keyboard
│                                 │
│  Suggestions:                   │
│  ┌──────┐ ┌──────┐ ┌──────┐   │
│  │ Nf6  │ │ Ng4  │ │ Ne7  │   │  ← legal moves that
│  └──────┘ └──────┘ └──────┘   │    look similar
│                                 │
└─────────────────────────────────┘
```

- Custom keyboard or picker with chess-specific characters (K, Q, R, B, N, a-h, 1-8, x, +, #, =, O-O, O-O-O)
- Suggestions are legal moves from that position, ranked by visual similarity to OCR result

---

## Screen 4: Game Review (THE CORE SCREEN)

This is where you spend 90% of your time. Must be best-in-class.

### Layout

```
┌─────────────────────────────────┐
│ ←  vs. Emma W.    ★ Won (1-0) │
│─────────────────────────────────│
│                                 │
│  ┌─────────────────────────────┐│
│  │  8 │r│ │ │ │k│ │ │r│      ││
│  │  7 │ │p│ │ │ │p│b│p│      ││
│  │  6 │p│ │ │ │ │n│p│ │      ││
│  │  5 │ │ │ │N│ │ │ │ │      ││  ← LARGE board
│  │  4 │ │ │ │ │P│ │ │ │      ││    (takes ~55% of screen)
│  │  3 │ │ │N│ │ │ │ │ │      ││
│  │  2 │P│P│P│ │ │P│P│P│      ││
│  │  1 │R│ │ │Q│ │R│K│ │      ││
│  │    a  b  c  d  e  f  g  h  ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ ◁◁   ◁   MOVE 14   ▷   ▷▷ ││  ← navigation bar
│  └─────────────────────────────┘│
│                                 │
│  ┌─ EVAL BAR ─────────────────┐│
│  │████████████░░░░░░░  +1.3   ││  ← horizontal eval bar
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ 14. Nd5  ✓ Great move!     ││  ← move annotation card
│  │                             ││
│  │ Your knight lands on a      ││
│  │ powerful central square     ││
│  │ where it can't be chased    ││
│  │ away by pawns.              ││
│  │                             ││
│  │ Best was: Nd5 (you found   ││
│  │ it!)                        ││
│  │                             ││
│  │ [See Engine Line]           ││
│  └─────────────────────────────┘│
│                                 │
│  [Board]  [Moves]  [Report]     │  ← segment control
└─────────────────────────────────┘
```

### Board Interaction — THE CRITICAL UX

**Navigation methods (multiple ways to go forward/backward):**

1. **Swipe on the board**
   - Swipe left on the board → next move
   - Swipe right on the board → previous move
   - This is the PRIMARY navigation — one-handed, natural, fast
   - Haptic feedback (light tap) on each move

2. **Navigation bar buttons**
   - `◁◁` = go to start
   - `◁` = back one move
   - `▷` = forward one move
   - `▷▷` = go to end
   - Hold `◁` or `▷` = auto-play backward/forward (1 move per 0.8s)

3. **Tap on move in move list** (when in "Moves" tab)
   - Jump directly to that position

4. **Scrubber / timeline** (stretch goal)
   - Horizontal slider at the bottom
   - Drag to scrub through the entire game quickly
   - Shows eval graph as the track — you can SEE where the game swung

### Board Rendering

- **Pieces**: Large, clear, high-contrast piece set (NOT 3D, NOT skeuomorphic)
  - Recommend: Neo or Merida-style pieces — recognizable even for beginners
  - Consider: option for "beginner pieces" with letters on them (K, Q, R, B, N, P)
- **Colors**: Soft green/cream (like lichess) rather than harsh black/white
- **Last move highlight**: subtle colored squares showing from/to squares
- **Board orientation**: always from player's perspective (if they played Black, board is flipped)
- **Coordinates**: a-h and 1-8 visible along edges

### Move Annotation Card

Below the board, each move gets a card with:

- **Move classification badge**:
  - ✨ **Brilliant** (found a move much better than expected for their level) — purple
  - ✅ **Great** (best move or very close) — green
  - 👍 **Good** (slight inaccuracy but reasonable) — light green
  - 🤔 **Inaccuracy** (missed something better) — yellow
  - ❌ **Mistake** (significant eval drop) — orange
  - 💥 **Blunder** (game-changing eval drop) — red
- **Plain language explanation** — age-appropriate, encouraging
  - For a 7yo U-400: "Your queen went to a square where it can be captured! Try to check if the square is safe before moving there."
  - For a 1600 teen: "This allows Bxf7+ winning a pawn and disrupting your king safety. Castling first (O-O) keeps your king safe."
- **"Best move" comparison** — what the engine recommends, shown on the board with an arrow
- **"See Engine Line"** — expandable, shows the top 3 engine lines (for advanced users / parents helping)

### Eval Bar (Horizontal)

- Runs horizontally below the board (not vertical — vertical takes precious horizontal space on phone)
- White fill from left = white advantage, dark fill from right = black advantage
- Number shows evaluation: +1.3, -0.5, M3 (mate in 3)
- **Animates smoothly** as you step through moves
- Tap on eval bar → toggles between centipawn and "winning chance %" (more intuitive for kids: "White has 72% winning chances")

### Segment Control Tabs

**[Board]** — The main view described above

**[Moves]** — Full move list with annotations

```
┌─────────────────────────────────┐
│  1.  e4       ✅   e5      ✅  │
│  2.  Nf3      ✅   Nc6     ✅  │
│  3.  Bb5      ✅   a6      👍  │
│  4.  Ba4      👍   Nf6     ✅  │
│  5.  O-O      ✅   Be7     ✅  │
│  6.  Re1      ✅   b5      🤔  │
│  7.  Bb3      ✅   d6      ✅  │
│  8.  c3       ✅   O-O     ✅  │
│  9.  h3       👍   Nb8     ❌  │
│  ...                            │
└─────────────────────────────────┘
```

- Tap any move → board jumps to that position + shows annotation card
- Scrollable, current move highlighted
- Quick visual scan of game quality via icons

**[Report]** — Coaching summary (see Screen 5)

---

## Screen 5: Coaching Report

Accessible from the [Report] tab on the Game Review screen.

```
┌─────────────────────────────────┐
│ ←  Game Report                  │
│─────────────────────────────────│
│                                 │
│  ┌─────────────────────────────┐│
│  │  ★ vs. Emma W.  Won (1-0)  ││
│  │  Spring Open, Round 3       ││
│  │                             ││
│  │  Accuracy     ████████░ 78% ││
│  │  Best Moves   12 / 34       ││
│  │  Mistakes     2             ││
│  │  Blunders     1             ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ 📖 Opening                  ││
│  │ Ruy Lopez, Morphy Defense   ││
│  │                             ││
│  │ You played the opening      ││
│  │ really well! You followed   ││
│  │ good principles: developed  ││
│  │ your knights, castled       ││
│  │ early, and controlled the   ││
│  │ center with pawns.          ││
│  │                             ││
│  │ 💡 Tip: After 6...b5 look  ││
│  │ at the Bb3 retreat — this   ││
│  │ is the main line and keeps  ││
│  │ your bishop active.         ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ ⚔️ Middlegame               ││
│  │                             ││
│  │ This is where the game got  ││
│  │ exciting! Your Nd5 on move  ││
│  │ 14 was brilliant — it       ││
│  │ created threats that were   ││
│  │ hard to deal with.          ││
│  │                             ││
│  │ ⚠️ On move 18, Qh4 was a   ││
│  │ mistake. [Tap to see →]     ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ 🏁 Endgame                  ││
│  │ ...                         ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ 🎯 Key Takeaways            ││
│  │                             ││
│  │ 1. Great job castling early ││
│  │ 2. Practice looking for     ││
│  │    your opponent's threats  ││
│  │    before making a move     ││
│  │ 3. In the endgame, push     ││
│  │    your passed pawns!       ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │   [Share Report]            ││  ← share with coach, parent
│  │   [Export PGN]              ││  ← for lichess/chess.com import
│  └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

### Coaching Language Guidelines

**Tone**: Encouraging, constructive, like a friendly coach — never harsh

**Scaling by level**:
- **U-600 (beginners)**: Focus on basic principles — "check if your pieces are safe", "control the center", "castle to keep your king safe"
- **U-1000**: Start mentioning tactical patterns — "there was a fork here", "this pin wins a piece"
- **U-1400**: Discuss positional concepts — "pawn structure", "piece activity", "weak squares"
- **U-2000**: Deeper strategy — opening preparation, endgame technique, prophylaxis

**Always include**:
- At least 2 things they did well (even in a loss)
- Specific, actionable advice (not vague "play better")
- Link back to specific moves they can review on the board

---

## Screen 6: Progress Dashboard

```
┌─────────────────────────────────┐
│ ≡  My Progress                  │
│─────────────────────────────────│
│                                 │
│  Games Analyzed: 23             │
│  Since: Jan 2026                │
│                                 │
│  ┌─────────────────────────────┐│
│  │ Accuracy Over Time     📈  ││
│  │                             ││
│  │  85%│          ·  ·         ││
│  │  75%│    ·  ·        ·     ││
│  │  65%│ ·        ·           ││
│  │  55%│·                      ││
│  │     └─────────────────────  ││
│  │      Jan    Feb    Mar      ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ Your Strengths          💪 ││
│  │                             ││
│  │ ████████████████░░  Opening ││
│  │ ██████████████░░░░  Tactics ││
│  │ ████████░░░░░░░░░░  Endgame││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ Focus Areas             🎯 ││
│  │                             ││
│  │ • Endgame technique — you   ││
│  │   had winning endgames in   ││
│  │   3 games but couldn't      ││
│  │   convert. Practice king +  ││
│  │   pawn endings!             ││
│  │                             ││
│  │ • Blunder rate is dropping  ││
│  │   — keep it up! Down from   ││
│  │   3.2/game to 1.1/game.    ││
│  └─────────────────────────────┘│
│                                 │
│  [Home]   [Progress]  [Settings]│
└─────────────────────────────────┘
```

---

## Game Metadata Entry (post-scan, pre-analysis)

After scan + move correction, quick form to capture context:

```
┌─────────────────────────────────┐
│ ←  Game Details                 │
│─────────────────────────────────│
│                                 │
│  I played as:                   │
│  ┌────────┐  ┌────────┐       │
│  │ ⬜ White│  │ ⬛ Black│       │  ← big toggle buttons
│  └────────┘  └────────┘       │
│                                 │
│  Result:                        │
│  ┌──────┐ ┌──────┐ ┌──────┐  │
│  │ Won  │ │ Lost │ │ Draw │   │
│  └──────┘ └──────┘ └──────┘  │
│                                 │
│  Opponent: [_______________]    │
│                                 │
│  Tournament: [Spring Open ▾]    │  ← dropdown of past +
│                                 │     "Add new tournament"
│  Round: [3]                     │
│                                 │
│  My rating: [optional]          │
│  Opp. rating: [optional]        │
│                                 │
│        [Analyze Game →]         │
│                                 │
└─────────────────────────────────┘
```

- Only Color and Result are required
- Everything else is optional but enriches the coaching
- Tournament names are remembered for future games

---

## Design System Notes

### Colors
- **Primary**: Deep blue (#1B4D7A) — trustworthy, calm
- **Accent**: Warm amber (#F5A623) — energy, achievement
- **Board light squares**: #F0D9B5 (classic warm cream)
- **Board dark squares**: #B58863 (classic walnut)
- **Success/great**: #4CAF50
- **Warning/inaccuracy**: #FFC107
- **Error/blunder**: #F44336
- **Background**: #FAFAFA (light mode), #1A1A2E (dark mode)

### Typography
- **Headlines**: SF Pro Rounded — friendly, approachable
- **Body**: SF Pro Text — clean, readable
- **Move notation**: SF Mono — monospaced for alignment
- **Coaching text**: slightly larger than default (17pt) for readability

### Animations
- Board pieces slide (not teleport) when stepping through moves
- Eval bar animates smoothly between positions
- Move classification badges pop in with a subtle scale animation
- Haptic feedback on move navigation (UIImpactFeedbackGenerator, light)

### Accessibility
- VoiceOver support for all interactive elements
- Dynamic Type support
- Minimum touch target: 44x44pt (Apple HIG)
- High contrast piece set option

---

## Gesture Summary for Game Review

| Gesture | Action |
|---------|--------|
| Swipe left on board | Next move |
| Swipe right on board | Previous move |
| Tap ◁ button | Previous move |
| Tap ▷ button | Next move |
| Tap ◁◁ button | Go to start |
| Tap ▷▷ button | Go to end |
| Long press ◁ or ▷ | Auto-play (1 move / 0.8s) |
| Tap move in list | Jump to that position |
| Pinch on board | Zoom (for small screens) |
| Tap a square | Highlight legal moves from there (learning mode) |
| Long press a piece | Show piece's influence/attacked squares |

---

## Offline Behavior

- Scanning requires network (LLM API call)
- Previously analyzed games are fully available offline
- Board replay, move list, coaching report all cached locally
- Engine re-analysis available offline (Stockfish runs on-device)

---

## MVP Scope (v1.0)

**In scope:**
- Scoresheet camera capture
- LLM-based OCR with move correction UI
- Game metadata entry
- Full game replay with swipe navigation
- Stockfish analysis with move classifications
- LLM-generated coaching report
- Local game library with SwiftData
- Basic progress tracking (accuracy over time)

**Out of scope for v1.0 (future):**
- User accounts / cloud sync
- Social features (share with coach)
- Opening repertoire trainer
- Puzzle generation from your games
- Live tournament mode (real-time notation)
- Apple Watch companion
- Android version
