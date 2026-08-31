# V0.2 — 09 Layout & HUD

## Target resolution

**Primary:** 1280×720  
**Minimum:** 1024×600 (panels scale proportionally)

---

## Four zones (Issue #2)

```text
┌─────────────────────────────────────────────────────────────────┐
│ TOP BAR: CODE SWARM · Mission 01 · DEPOSITED 0/20 · [API] [Hints]│
├──────────────────────────────┬──────────────────────────────────┤
│                              │                                  │
│   WORLD (simulation)         │   COACH PANEL                    │
│   ~45% width                 │   ~25% width                     │
│   Drone, ore, base, walls    │   Step text, Next Hint, objective│
│                              │                                  │
├──────────────────────────────┤                                  │
│                              │                                  │
│   PYTHON EDITOR              │   ERROR / STATUS STRIP (bottom   │
│   ~45% width, ~55% height    │   of right column)               │
│   Multiline, scroll          │                                  │
│                              │                                  │
├──────────────────────────────┴──────────────────────────────────┤
│ CONTROLS: [RUN F5] [STOP Esc] [RESET WORLD F8]   Status: IDLE   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Zone 1 — Mission / objective (top bar)

| Element | Content |
|---------|---------|
| Title | CODE SWARM |
| Mission | Mission 01: First Program |
| Progress | DEPOSITED: N / 20 |
| Cargo | CARGO: n / 5 (optional inline) |
| Step | Step 3 of 7 — Repeat |

---

## Zone 2 — Python editor (left bottom)

- Primary focus for typing
- Label: "Your Python program"
- Subtle border when focused
- Error line highlight spans editor width

**Minimum height:** 12 visible lines at 720p

---

## Zone 3 — World (left top)

Reuse V0.1 rendering:

- Floor, walls, ore, base, drone
- Mining/deposit effects
- No regression from Gate 1 visuals

Camera: fixed — no pan/zoom V0.2.

---

## Zone 4 — Coach + errors (right column)

### Coach (upper right)

- Step title bold
- Body text wrapped
- "Next Hint" button
- Optional "Show solution" confirm on tier 4

### Error strip (lower right)

When IDLE/RUNNING: show last run status or Coach tip.

When ERROR:

- Friendly title
- 2–4 lines explanation
- Line reference: "See line 4 in your editor"

**No overlap:** error strip must not cover editor caret area.

---

## Controls bar (bottom)

| Button / Key | Action |
|--------------|--------|
| RUN (F5) | Execute editor buffer |
| STOP (Esc) | Stop Python worker |
| RESET WORLD (F8) | Reset sim — **not** code |
| API (F1) | Toggle API reference overlay/modal |

Mouse: buttons call same functions as keys.

---

## API reference overlay

- Semi-transparent backdrop or slide-in panel
- Scrollable 6 entries
- Close: F1, Esc, or [X]
- Does not clear editor buffer

---

## Status indicator

| State | Color | Text |
|-------|-------|------|
| IDLE | Gray | Ready |
| RUNNING | Yellow | Running… |
| ERROR | Red | Error — fix and RUN again |
| WIN | Green | Mission complete! |

---

## Typography

| Use | Style |
|-----|-------|
| Coach body | Sans-serif, readable |
| Editor | Monospace |
| API | Monospace signatures |

Reuse V0.1 font assets if available; else LÖVE default with size ≥14.

---

## `ui/hud_v02.lua` responsibilities

```lua
-- Draw order
1. world (game draw)
2. editor panel chrome + editor:draw()
3. coach panel
4. error strip
5. top bar + bottom controls
6. api overlay if open
7. WIN modal if won
```

Input routing:

- Mouse click zones → focus editor OR button
- Keys → editor when focused, else globals (F5…)

---

## Responsive fallback (1024×600)

- Reduce world height slightly
- Editor min 8 lines
- Coach scroll if text long

---

## Explicitly not in layout V0.2

- Lua file path display
- Terminal/console for player
- File menu / open save
- Settings screen
- Level select map

---

## Regression check vs V0.1

- Walls visible
- Correct ore sprite
- WIN stops script
- STOP from ERROR state works
