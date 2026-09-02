# Gate 2 — V0.2 Current Evidence

> **STATUS: YELLOW / NOT COMPLETE**  
> Technical IPC regression found on 2026-09-02 was fixed and is now covered by CI.  
> Product Gate 2 still requires live Windows playtest, standalone packaging, real Figma Make UI evidence, and beginner cold-start validation.

## Current hardened path

```text
IN-GAME EDITOR BUFFER
        ↓
Lua IPC serializer (`scripting/ipc_protocol.lua`)
        ↓
unique per-game IPC session
        ↓
Python worker (`python/worker.py`)
        ↓
player API (`python/codeswarm.py`)
        ↓
Lua simulation API
        ↓
drone / ore / base / world
```

## 2026-09-02 regression that was fixed

The previous Lua JSON encoder converted `args = { source }` into a string such as `"table: 0x..."` instead of a JSON array. The Python-only harness never exercised this production serializer, so it could pass while the real RUN path failed.

Fixes now in `main`:

- real recursive JSON encoder for Lua IPC;
- atomic IPC writes on both Lua and Python sides;
- unique IPC directory per game session;
- stale PID/error files no longer define readiness;
- worker startup is polled through `update()` instead of a 5-second busy loop;
- STOP/cleanup no longer busy-waits 300 ms on the game thread;
- malformed IPC is surfaced as an internal error instead of silently deleting the request;
- Python worker validates that `args` is a JSON array and source is text;
- error SFX ownership moved to `main.lua` only;
- normal `running -> idle` completion records Mission01 `success`;
- resize/F11 preserves Coach step/hint state;
- editor click-to-caret geometry corrected;
- fragile runtime regex parsing of hint JSON replaced by deterministic Lua hint data.

## Automated evidence

GitHub Actions workflow: `.github/workflows/qa.yml`

Latest verified run after the hardening series:

- Workflow run: `33577289113`
- Result: **SUCCESS**
- Critical Lua files compile: **PASS**
- Python runtime files compile: **PASS**
- worker SyntaxError/NameError/anti-freeze harness: **PASS**
- **Lua encoder -> Python worker -> response end-to-end contract: PASS**

The E2E test specifically asserts that Lua serializes player source under `args` as a JSON array, publishes it atomically, the real Python worker executes it, and a real `{"type":"done"}` response returns.

## Tutorial / editor fixes

- Mission Step 3 -> 4 dead-end: fixed by code + behavior recognition.
- Coach state reset on window resize/F11: fixed by `ui/coach_panel_fixed.lua`.
- Mouse click caret offset: fixed by `ui/editor_fixed.lua` using rendered prefix widths.
- Hint strings containing quotes such as `move_to("base")`: no longer depend on the old regex JSON parser at runtime.

## What is NOT yet proven

The following remain mandatory before Gate 2 can be GREEN:

- [ ] Live LÖVE Windows test of the full visible path: editor -> RUN -> `move_to(nearest_ore())` -> drone visibly moves.
- [ ] Live mine -> cargo -> base -> deposit -> WIN mission test.
- [ ] STOP/reset/error recovery tested inside the actual game window.
- [ ] Standalone Windows alpha package with bundled LÖVE + Python; player installs neither runtime manually.
- [ ] Clean-machine package test.
- [ ] Real Figma Make S1–S7 reference. ASCII is explicitly **not** accepted as Figma evidence.
- [ ] Game screenshots compared against the approved Figma design.
- [ ] Cold-start test with a beginner who has never coded.

## Gate question

> Can a person who has never written code open CODE SWARM, understand the mission, write Python inside the game, see the drone respond, understand and fix mistakes, complete Mission 01, and do all of that in an interface that feels like a game rather than a developer dashboard?

**Answer today: NOT YET PROVEN.**

Therefore:

> **GATE 2 = YELLOW**

Do not open Mission/Level 2 as the main development track until the remaining product evidence above is complete.
