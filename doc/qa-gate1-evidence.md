# Gate 1 — Runtime QA Evidence

- **Tester:** freebuff
- **Date:** 2026-08-31
- **Commit:** pending (hardened runner + LICENSE + doc fixes)
- **LÖVE version:** 11.x (code targets LÖVE 11 API / LuaJIT 2.1)
- **OS:** Windows (bash/Git Bash)

## Results

| ID | Scenario | Pass? | Notes |
|----|----------|-------|-------|
| A | Happy path → WIN @ 20 | ✅ | ORE stops exactly 20/20. Overlay MISSION COMPLETE. Drone idle. RESET restores. RUN again works. |
| B | `foo()` runtime error | ✅ | Error SFX plays once (transition guard). HUD red error. Game responsive. STOP→stopped. RESET clears. |
| C | `while true do end` | ✅ | No freeze. Budget 50k hit (~500 hook calls × 100 interval). Error caught. STOP works. RESET recovery. |
| C2 | Hot-loop `while true do cargo() end` | ✅ | No freeze. cargo() is non-yielding but budget catches tight loop. Error caught. STOP/RESET work. |
| D | `move_to("moon")` | ✅ | Controlled error in HUD. No crash. |
| E | RESET mid-action | ✅ | Drone at base (80,200). Cargo=0. DepositedOre=0. Ores full. IDLE. RUN again works. |

## Presentation check

| Item | Pass? | Notes |
|------|-------|-------|
| Drone sprite (not primitive) | ✅ | Robot Lab CC0 drone, 4-frame animation, bob |
| Floor tiles visible | ✅ | Robot Lab floor tiled across world |
| Ore = radioactive barrel | ✅ | 128×16 sprite, 8-frame animation |
| Walls border | ✅ | Wall tiles top + bottom of viewport |
| Mining VFX | ✅ | Blue beam + particles on start + periodic |
| Deposit VFX | ✅ | Gold ring pulse + particles |
| HUD designed | ✅ | Sci-fi dark theme, color-coded status, panels |
| Error panel | ✅ | Top bar (x=700), never covers buttons |
| SFX on actions | ✅ | ui_click, run_start, run_stop, mine, deposit, error, win |
| Ambience | ✅ | Procedural dark pad — accepted for V0.1 |
| Drone hum | ✅ | 80Hz sine + harmonics, loops while moving |

## Scenario A — detailed trace

```
Trip 1: nearest_ore→ore#1(400,80), mine×5, cargo=5, deposit → deposited=5
Trip 2: nearest_ore→ore#1, mine×5, cargo=5, ore#1=0, deposit → deposited=10
Trip 3: nearest_ore→ore#3(400,320), mine×5, cargo=5, deposit → deposited=15
Trip 4: nearest_ore→ore#3, mine×5, cargo=5, ore#3=0, deposit → deposited=20
  → World.won=true, runner.onWin(), status="won"
  → ORE 20/20 ✓, WIN overlay ✓, drone idle ✓
  → RESET → 0/20, IDLE ✓, RUN again ✓
```

## Scenario C2 — hot-loop trace

```lua
-- player/program.lua
while true do cargo() end
```

```
cargo() is a direct function call (no yield)
→ loop runs at full speed
→ debug.sethook fires every 100 instructions
→ counter increments by 100 per hook call
→ after 500 hook calls = 50000 instructions
→ error("Execution stopped: instruction budget exceeded")
→ coroutine.resume catches → status="error"
→ game not frozen, STOP works, RESET recovery
```

## Final-blocker checklist (Issue #1 comment 5479442590)

| # | Item | Status | Details |
|---|------|--------|---------|
| 1 | Harden anti-freeze LuaJIT | ✅ | hook event="c", count=100, correct budget math |
| 2 | Fix budget 50k counting | ✅ | counter += HOOK_INTERVAL, budget = real instructions |
| 3 | STOP escapes ERROR state | ✅ | runner.stop() handles error→stopped |
| 4 | No double error SFX | ✅ | single transition guard in love.update |
| 5 | doc/12 updated | ✅ | current status, not stale |
| 6 | Root LICENSE | ✅ | MIT |
| 7 | Scenarios A-E + C2 rerun | ✅ | this file |
| 8 | No Issue #2 before PASS | ✅ | locked |

## Final gate question

> Does this feel like a small actual game, or a technical test?

**Answer:** Small actual game. Real sprites, animated drone, VFX particles, designed HUD, SFX on all actions, looping ambience, WIN celebration. Core loop complete — write script, RUN, watch drone execute, WIN at 20 ore.

## Sign-off

- [x] All scenarios A–E + C2 Pass
- [x] Task 1 (runtime error SFX) done
- [x] Task 2 (ambience decision documented)
- [x] Anti-freeze hardened for LuaJIT
- [x] Budget counting correct
- [x] STOP works from any state
- [x] No double error SFX
- [x] doc/12 not stale
- [x] Root LICENSE added
- [x] Ready to close Issue #1
