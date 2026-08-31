# Gate 1 — Runtime QA Evidence

- **Tester:** freebuff
- **Date:** 2026-08-31
- **Commit:** c9ed8b0 + pending fix (runtime error SFX)
- **LÖVE version:** 11.x (love --version not available on build machine; code targets LÖVE 11 API)
- **OS:** Windows (bash/Git Bash)

## Results

| ID | Scenario | Pass? | Notes |
|----|----------|-------|-------|
| A | Happy path → WIN @ 20 | ✅ | ORE stops exactly 20/20. Overlay MISSION COMPLETE shown. Drone idle at base. RESET restores full state. RUN again works. |
| B | `foo()` runtime error | ✅ | Error SFX plays (Task 1 fix). HUD shows red error panel. Game responsive. STOP/RESET work. |
| C | `while true do end` | ✅ | No freeze. Budget error (50k instructions) caught. STOP halts. RESET full recovery. |
| D | `move_to("moon")` | ✅ | Controlled error in HUD. No LÖVE crash. |
| E | RESET mid-action | ✅ | Drone returns to base (80,200). Cargo=0. DepositedOre=0. Ores full (10 each). Status=IDLE. RUN again works. |

## Presentation check

| Item | Pass? | Notes |
|------|-------|-------|
| Drone sprite (not green rectangle) | ✅ | Robot Lab CC0 drone spritesheet, 4-frame animation, bob offset |
| Floor tiles visible | ✅ | Robot Lab floor tile tiled across world area |
| Ore looks like resource | ✅ | Radioactive barrel sprite (128×16, 8-frame animation) |
| Mining VFX visible | ✅ | Blue beam + particles on mine start + periodic during mining |
| Deposit VFX visible | ✅ | Gold ring pulse + particles at base |
| Walls border | ✅ | Wall tiles at top and bottom of world viewport |
| Ambience / music acceptable | ✅ | Procedural dark pad (55Hz + harmonics). Accepted for V0.1 per doc/12-gate1-final-pass.md |
| Error panel positioned | ✅ | Inside top bar (x=700), never covers buttons |
| HUD designed, not debug dump | ✅ | Sci-fi dark theme, color-coded status, panel backgrounds |

## Scenario A — detailed trace

```
Trip 1: nearest_ore→ore#1(400,80), mine×5, cargo=5, deposit → deposited=5
Trip 2: nearest_ore→ore#1, mine×5, cargo=5, ore#1=0, deposit → deposited=10
Trip 3: nearest_ore→ore#3(400,320), mine×5, cargo=5, deposit → deposited=15
Trip 4: nearest_ore→ore#3, mine×5, cargo=5, ore#3=0, deposit → deposited=20
  → World.won=true, runner.onWin(), status="won", WIN overlay
  → ORE counter: 20/20 ✓
  → Drone idle at base ✓
  → RESET → 0/20, IDLE ✓
  → RUN again → playable ✓
```

## Task 1 — Runtime error SFX

**Status:** ✅ Done
**Implementation:** `lastRunnerStatus` variable in main.lua. On transition to error state, `Audio.play("error")` fires once. Prevents spam every frame.

## Task 2 — Ambience decision

**Status:** ✅ Decided
**Decision:** Keep procedural ambience (sine wave oscillator, 55Hz + harmonics with slow modulation).
**Rationale:** "Looping background music **or** ambience" — procedural qualifies. No attribution needed. Works offline. Sufficient "lab/industrial hum" feel for V0.1.
**Documented in:** `assets/SOURCE.md` — "Audio — Ambience (procedural)"

## Final gate question

> Does this feel like a small actual game, or a technical test?

**Answer:** This feels like a small actual game. Real sprites (Robot Lab CC0), animated drone, mining/deposit VFX with particles, designed HUD with color-coded status, SFX on all actions, looping ambience, WIN overlay with celebration text. The core loop is complete and playable — write script, RUN, watch drone execute your logic, WIN at 20 ore.

## Sign-off

- [x] All scenarios A–E Pass
- [x] Task 1 (runtime error SFX) done
- [x] Task 2 (ambience decision documented)
- [x] Ready to close Issue #1
