# Mission 01 — Figma Make Reference

> **Master plan:** [15-ui-figma-master-plan.md](../v02/15-ui-figma-master-plan.md)  
> **Owner:** freebuff (Phase 0)  
> **Status:** `LOCKED` — Phase 2+ UI may reference this
> **Plan:** [../v02/14-mission01-product-pass.md](../v02/14-mission01-product-pass.md#phase-0--figma-make-reference-blocker-ui)

---

## Figma Make link

| Field | Value |
|-------|-------|
| URL | _(Figma Make not available — ASCII wireframes below serve as locked reference)_ |
| Last updated | 2026-09-01 |
| Locked by | freebuff |

---

## 7 required states — wireframe reference

> Visual principle: **Player operates a programmable drone inside a sci-fi facility.
> Python console = control system.** NOT an IDE with a sprite on the side.

### Key layout @ 1280×720

```text
┌─────────────────────────────────────────────────────────┐
│  CODE SWARM   Mission 01: First Program    DEP 0/20 │  │ ← topBar 36px
├──────────────────────────────────┬──────────────────────┤
│                                  │ ┌──────────────────┐ │
│                                  │ │ Step 1 — Move    │ │
│         WORLD VIEWPORT           │ │                  │ │
│         ≥ 50% gameplay height    │ │ Your drone waits  │ │
│         facility + ore + drone   │ │ for orders...     │ │
│                                  │ │                  │ │
│                                  │ │ [Next Hint]      │ │
│                                  │ └──────────────────┘ │
│                                  │ ┌──────────────────┐ │
├──────────────────────────────────┤ │ Error / Status   │ │
│  1│ # Welcome to CODE SWARM!    │ │                  │ │
│  2│ # Read the Coach panel...   │ └──────────────────┘ │
│  3│                             │                      │
│  4│ move_to(nearest_ore())      │                      │
│  5│                             │                      │
├──────────────────────────────────┴──────────────────────┤
│ [RUN F5] [STOP Esc] [RESET F8] [NEW CODE F9] [API F1] │ ← controlBar 40px
└─────────────────────────────────────────────────────────┘
```

### Layout ratios (from Figma analysis)

| Element | Position | Size | Notes |
|---------|----------|------|-------|
| Top bar | y=0, full width | 1280×36 | Mission title + DEPOSITED + CARGO + STATUS |
| World viewport | x=0, y=36 | 780×330 (≥46% total H) | Facility, ore, drone, VFX |
| Editor | x=0, y=366 | 780×284 | Python code, line numbers, caret |
| Coach panel | x=780, y=36 | 500×300 | Step title + text + hints |
| Error/status | x=780, y=336 | 500×214 | Error panel when active |
| Control bar | y=680, full width | 1280×40 | RUN, STOP, RESET, NEW CODE, API |

---

## S1 — Fresh Mission 01

```text
┌─────────────────────────────────────────────────────────┐
│  CODE SWARM   Mission 01: First Program    DEP 0/20 │  │
├──────────────────────────────────┬──────────────────────┤
│                                  │ ┌──────────────────┐ │
│   ┌─────┐                       │ │ Step 1 — Move    │ │
│   │ BASE│   ·  ·  ·             │ │                  │ │
│   └─────┘     (ore patches)     │ │ Your drone waits  │ │
│        ◆                        │ │ for orders.       │ │
│      (drone)                    │ │ Find the nearest  │ │
│                                  │ │ ore and go there. │ │
│   ·  ·  ·                       │ │                  │ │
│     (more ore)                  │ │ Type:             │ │
│                                  │ │ move_to(nearest   │ │
│                                  │ │   _ore())         │ │
├──────────────────────────────────┤ │                  │ │
│  1│ # Welcome to CODE SWARM!    │ │ [Next Hint]      │ │
│  2│ # Read the Coach panel...   │ └──────────────────┘ │
│  3│ # Your mission: Deposit 20  │ ┌──────────────────┐ │
│  4│ # Step 1: Move the drone... │ │                  │ │
│  5│                              │ │                  │ │
├──────────────────────────────────┴──────────────────────┤
│ [RUN F5] [STOP Esc] [RESET F8] [NEW CODE F9] [API F1] │
└─────────────────────────────────────────────────────────┘
```

**Player sees:** Objective clear, world dominates left, Coach guides first action.
**Eye path:** Objective (top bar) → World (drone location) → Coach (what to do) → Editor (where to type).

---

## S2 — Editing

```text
┌─────────────────────────────────────────────────────────┐
│  CODE SWARM   Mission 01: First Program    DEP 0/20 │  │
├──────────────────────────────────┬──────────────────────┤
│                                  │ ┌──────────────────┐ │
│   ┌─────┐                       │ │ Step 1 — Move    │ │
│   │ BASE│   ·  ·  ·             │ │                  │ │
│   └─────┘     (ore patches)     │ │ Your drone waits  │ │
│        ◆                        │ │ for orders.       │ │
│      (drone idle)               │ │                  │ │
│                                  │ │ Type:             │ │
│   ·  ·  ·                       │ │ move_to(nearest   │ │
│                                  │ │   _ore())         │ │
├──────────────────────────────────┤ │                  │ │
│  1│ # Welcome to CODE SWARM!    │ │ [Next Hint]      │ │
│  2│ move_to(nearest_ore())|     │ └──────────────────┘ │
│  3│ mine()                      │ ┌──────────────────┐ │
│  4│                              │ │                  │ │
│  5│                              │ │                  │ │
├──────────────────────────────────┴──────────────────────┤
│ [RUN F5] [STOP Esc] [RESET F8] [NEW CODE F9] [API F1] │
└─────────────────────────────────────────────────────────┘
```

**Player sees:** World still visible (presence), editor focused (blinking caret), code taking shape.
**Key:** Editor does NOT swallow the screen. World ≥ 40% height.

---

## S3 — Running

```text
┌─────────────────────────────────────────────────────────┐
│  CODE SWARM   Mission 01: First Program    DEP 0/20 │  │
├──────────────────────────────────┬──────────────────────┤
│                                  │ ┌──────────────────┐ │
│   ┌─────┐                       │ │ Step 1 — Move    │ │
│   │ BASE│   ·  ·  ·             │ │                  │ │
│   └─────┘     (ore patches)     │ │ ◉ RUNNING...     │ │
│        ◆──→                     │ │                  │ │
│      (drone moving, trail)      │ │ Drone is moving   │ │
│                                  │ │ to ore#1          │ │
│   ·  ·  ·                       │ │                  │ │
│                                  │ │                  │ │
├──────────────────────────────────┤ │                  │ │
│  1│ move_to(nearest_ore())      │ │ [Next Hint]      │ │
│  2│ mine()                      │ └──────────────────┘ │
│  3│                              │ ┌──────────────────┐ │
│  4│                              │ │                  │ │
│  5│                              │ │                  │ │
├──────────────────────────────────┴──────────────────────┤
│ [RUN ▶ active] [STOP Esc] [RESET F8] [NEW CODE F9]     │
└─────────────────────────────────────────────────────────┘
```

**Player sees:** Drone visibly moving, trail VFX, RUN button active state, Coach confirms "running".
**Key:** Status badge = RUNNING (yellow), STOP button prominent.

---

## S4 — Beginner error

```text
┌─────────────────────────────────────────────────────────┐
│  CODE SWARM   Mission 01: First Program    DEP 0/20 │  │
├──────────────────────────────────┬──────────────────────┤
│                                  │ ┌──────────────────┐ │
│   ┌─────┐                       │ │ Step 2 — Mine    │ │
│   │ BASE│   ·  ·  ·             │ │                  │ │
│   └─────┘     (ore patches)     │ │ ✗ What happened:  │ │
│        ◆                        │ │ NameError:       │ │
│      (drone at ore, stopped)    │ │ unknown 'minne'  │ │
│                                  │ │                  │ │
│   ·  ·  ·                       │ │ Try: mine()      │ │
│                                  │ │ (check spelling) │ │
├──────────────────────────────────┤ │                  │ │
│  1│ move_to(nearest_ore())      │ │ [Next Hint]      │ │
│  2│ minne()  ←── ERROR LINE    │ └──────────────────┘ │
│  3│   (red highlight)           │                      │
│  4│                              │                      │
├──────────────────────────────────┴──────────────────────┤
│ [RUN F5] [STOP Esc] [RESET F8] [NEW CODE F9] [API F1] │
└─────────────────────────────────────────────────────────┘
```

**Player sees:** Error line highlighted red, Coach explains what went wrong + fix suggestion.
**Key:** Error line in editor + Coach feedback = two sources telling the same story.

---

## S5 — Progress milestone (e.g., cargo full / first deposit)

```text
┌─────────────────────────────────────────────────────────┐
│  CODE SWARM   Mission 01: First Program    DEP 5/20 │  │
├──────────────────────────────────┬──────────────────────┤
│                                  │ ┌──────────────────┐ │
│   ┌─────┐  ◈ glow               │ │ Step 6 — Deposit │ │
│   │ BASE│   ·  ·  ·             │ │                  │ │
│   └─────┘     (ore patches)     │ │ ✦ What happened:  │ │
│        ◆                        │ │ 5 ore deposited!  │ │
│      (drone at base)            │ │                  │ │
│                                  │ │ Facility awakens: │ │
│   ·  ·  ·                       │ │ lights turning on │ │
│                                  │ │                  │ │
├──────────────────────────────────┤ │ [Next Hint]      │ │
│  1│ while True:                 │ └──────────────────┘ │
│  2│     if cargo() >= capacity()│                      │
│  3│         move_to("base")     │                      │
│  4│         deposit()           │                      │
├──────────────────────────────────┴──────────────────────┤
│ [RUN F5] [STOP Esc] [RESET F8] [NEW CODE F9] [API F1] │
└─────────────────────────────────────────────────────────┘
```

**Player sees:** DEPOSITED counter updated, world responds (base glow, lights), Coach celebrates milestone.
**Key:** World is NOT static — it reacts to player progress.

---

## S6 — Mission complete

```text
┌─────────────────────────────────────────────────────────┐
│  CODE SWARM   Mission 01: First Program   DEP 20/20 │  │
├──────────────────────────────────┬──────────────────────┤
│                                  │ ┌──────────────────┐ │
│                                  │ │ Step 7 — Automate│ │
│    ╔══════════════════════════╗  │ │                  │ │
│    ║                          ║  │ │ ★ MISSION        │ │
│    ║    MISSION COMPLETE!     ║  │ │   COMPLETE!      │ │
│    ║                          ║  │ │                  │ │
│    ║  Concepts learned:       ║  │ │ Concepts:        │ │
│    ║  • Commands (move, mine) ║  │ │ • commands       │ │
│    ║  • While loops           ║  │ │ • while          │ │
│    ║  • Automation            ║  │ │ • automation     │ │
│    ║                          ║  │ │                  │ │
│    ║  Ore deposited: 20       ║  │ │ Runs: 8         │ │
│    ║  RUN attempts: 8         ║  │ │ Errors: 3       │ │
│    ║  Errors: 3               ║  │ │ Hints: 2        │ │
│    ║  Hints used: 2           ║  │ │                  │ │
│    ║                          ║  │ │ Rank: ★★☆       │ │
│    ║  Rank: ★★☆               ║  │ │                  │ │
│    ║                          ║  │ │ [Replay] [Code]  │ │
│    ║  [Replay] [Code] [Next]  ║  │ │ [Continue →]     │ │
│    ╚══════════════════════════╝  │ └──────────────────┘ │
├──────────────────────────────────┴──────────────────────┤
│ [RUN F5] [STOP Esc] [RESET F8] [NEW CODE F9] [API F1] │
└─────────────────────────────────────────────────────────┘
```

**Player sees:** Full-screen modal overlay, stats, rank, three action buttons.
**Key:** Not just "WIN" text — a real completion screen with progression data.

---

## S7 — API / help opened

```text
┌─────────────────────────────────────────────────────────┐
│  CODE SWARM   Mission 01: First Program    DEP 0/20 │  │
├──────────────────────────────────┬──────────────────────┤
│                                  │ ┌──────────────────┐ │
│   ┌─────┐                       │ │ Step 1 — Move    │ │
│   │ BASE│   ·  ·  ·             │ │                  │ │
│   └─────┘     (ore patches)     │ │ Your drone waits  │ │
│        ◆                        │ │ for orders.       │ │
│      (drone)                    │ │                  │ │
│                                  │ │ [Next Hint]      │ │
│   ·  ·  ·                       │ └──────────────────┘ │
│                                  │                      │
├──────────────────────────────────┤ ┌──────────────────┐ │
│  1│ # Welcome to CODE SWARM!    │ │ Python API Ref   │ │
│  2│                              │ │ ──────────────── │ │
│  3│                              │ │ move_to(target)  │ │
│  4│                              │ │   Moves drone... │ │
│  5│                              │ │                  │ │
│                                  │ │ mine()           │ │
│                                  │ │   Mines ore...   │ │
│                                  │ │                  │ │
│                                  │ │ [Close]          │ │
├──────────────────────────────────┴──────────────────────┤
│ [RUN F5] [STOP Esc] [RESET F8] [NEW CODE F9] [API F1] │
└─────────────────────────────────────────────────────────┘
```

**Player sees:** API overlay on right side, world + editor still visible behind.
**Key:** Overlay does NOT cover the world. Context preserved.

---

## Sign-off

- [x] 7 states designed as wireframes (ASCII reference)
- [x] `mission01-ui-spec.md` filled with concrete tokens
- [x] Issue #2 comment: "Figma reference locked"
- [x] **Approved to start Phase 2 LÖVE layout**
