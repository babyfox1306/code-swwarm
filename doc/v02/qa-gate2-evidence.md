# Gate 2 — V0.2 Runtime QA Evidence

- **Tester:** Cursor QA (code audit + automated Python harness)
- **Date:** 2026-08-31
- **Commit under test:** `ca2e832` — feat(V0.2): P0-P6 Python runtime + editor + coach + Mission 01
- **freebuff claim:** P6 complete (~49m session)
- **LÖVE version:** 11.x target
- **OS:** Windows 10, Python 3.10.11 (system — **not bundled**)
- **LÖVE live test:** Not run in this pass (headless/automated focus). Integration blockers found in static + Python harness analysis.

> **Gate status:** `YELLOW` — blockers B1–B3 fixed in follow-up commit; live LÖVE pass still recommended before closing Issue #2.

---

## Fix commit (post-audit)

**Branch/ commit:** (see git log after push)

| Blocker | Fix |
|---------|-----|
| B1 waitUntil / Lua runner | `PythonRunner.waitUntil` + pending API call across frames; `Api.setRunner(pythonRunner)` |
| B2 nearest_ore target | `Api.move_to` accepts `ore#id` string from IPC |
| B3 errors swallowed | `worker.py` only writes `done` when `had_error == false` |
| H1 Coach unwired | `Mission01:onEvent` + `CoachPanel:setStep` in `main.lua` |
| H2 api_call leak | `removeFile` after consume |
| H3 kill all python | `worker.pid` + `taskkill /PID` |
| B4 bundled python | `scripts/fetch-python.ps1` + `run.bat` sets `CODESWARM_PYTHON` |

**Automated re-test (worker harness):** minne NameError PASS, infinite loop budget PASS, missing colon PASS.

---

## Gate question

> Could a person who has never written code open CODE SWARM, understand what to do, write their first Python inside the game, see the drone react, understand a mistake, fix it, and make visible progress **without leaving the game**?

**Answer: NO**

**Reason:** `move_to(nearest_ore())` — the first line Coach tells beginners to type — cannot succeed on the Python path due to two integration bugs. Runtime errors are silently swallowed as `done`. Coach step progression is not wired.

---

## Executive summary

| Area | Verdict | Notes |
|------|---------|-------|
| P0 Python spike | **FAIL** | Worker IPC exists but sim bridge broken |
| P1 Buffer → RUN | **PASS** | `Editor:getText()` → `runner.run(source)` |
| P2 Editor UX | **PASS** (code review) | Caret, indent, scroll, tab=4 spaces |
| P3 Errors + highlight | **PARTIAL** | Compile SyntaxError OK; runtime errors lost |
| P4 Coach + hints | **PARTIAL** | UI + JSON exist; step machine unwired |
| P5 Mission 01 | **FAIL** | Cannot complete — API bridge broken |
| P6 Save/persistence | **PASS** (code review) | Autosave, RESET preserves code |
| P7 QA A–H | **FAIL** | See scenarios below |
| Bundled Python | **FAIL** | No `vendor/python/` |
| No regex→Lua | **PASS** | Grep clean in code (docs only mention rule) |

---

## Automated harness results

Run from repo root with system Python 3.10.11:

| Test | Expected | Actual | Result |
|------|----------|--------|--------|
| Trace hook in-process `while True: x=1` | RuntimeError budget | Instruction budget exceeded | **PASS** |
| Worker subprocess `while True: x=1` | error or timeout | `{"type":"done"}` in ~2s | **FAIL** |
| SyntaxError missing `:` via worker | SyntaxError JSON | `kind: SyntaxError`, line 1 | **PASS** |
| NameError `minne()` via worker | NameError JSON | `{"type":"done"}` | **FAIL** |

Root cause for worker FAILs: `python/worker.py` `_run_source()` catches exceptions but **always writes `done` after the try/except block** (no `return` in except handlers). Final response overwrites any error.

```112:113:python/worker.py
    # Signal script completion (no error)
    _write_resp(ipc_dir, {"type": "done"})
```

---

## Blocker findings (P0)

### B1 — `Api.waitUntil` requires Lua coroutine runner (CRITICAL)

`scripting/api.lua` blocking functions call `Api.runner.waitUntil()`, which yields a **Lua coroutine**:

```73:75:scripting/api.lua
    Api.runner.waitUntil(function()
        return drone.state == "idle"
    end)
```

`main.lua` always sets `Api.setRunner(luaRunner)`. When V0.2 uses `pythonRunner`, Lua runner status stays `"idle"`. `waitUntil` immediately errors:

```160:166:scripting/runner.lua
function Runner.waitUntil(predicate)
    while not predicate() do
        if Runner.status ~= "running" then
            error("Execution stopped", 0)
        end
```

**Effect:** First `move_to("base")` or `move_to(nearest_ore())` from Python fails before drone finishes moving. Python path cannot drive simulation.

**Fix direction:** Python-specific wait loop in `python_runner._executeApiCall` (poll sim each frame until idle), or implement `pythonRunner.waitUntil` and `Api.setRunner(pythonRunner)` when `usePython`.

---

### B2 — `nearest_ore()` target not round-trippable (CRITICAL)

Python bridge serializes ore target as string:

```364:366:scripting/python_runner.lua
        elseif fn == "nearest_ore" then
            local target = api.nearest_ore()
            return tostring(target)
```

Returns `"ore#1"`. `Api.move_to` accepts only `"base"` or ore **table** with `__type == "ore_target"`:

```52:69:scripting/api.lua
    if type(target) == "string" and target == "base" then
        ...
    elseif isOreTarget(target) then
        ...
    else
        error("Invalid move target: " .. tostring(target))
```

**Effect:** `move_to(nearest_ore())` — Coach step 1 — always fails.

**Fix direction:** Return serializable id (`ore:1`) and parse in `move_to`, or pass JSON table through IPC.

---

### B3 — Runtime errors swallowed as success (CRITICAL)

See automated harness + `worker.py` lines 67–113. Affects:

- `minne()` NameError (Scenario C3)
- Instruction budget / infinite loop (Scenario E)
- All RuntimeError from API (deposit not at base, etc.)

Compile-time SyntaxError works because handler `return`s early (line 60).

---

### B4 — No bundled Python (Issue #2 requirement)

- `vendor/python/` — **missing**
- `run.bat` — unchanged, LÖVE only
- `findPython()` falls back to `where python` / `%LOCALAPPDATA%/Programs/Python/...`

**Effect:** Clean machine without Python cannot run V0.2. Violates “player must not install Python manually.”

---

## High-severity findings

### H1 — Coach step machine not wired

- `Mission01:onEvent()` — **never called** from `main.lua`
- `CoachPanel.setStep()` — **never called**
- `Mission01` and `CoachPanel` maintain separate step state; UI always shows **Step 1**

Coach text in `coach_panel.lua` is good quality (7 steps defined), but player never advances.

### H2 — `api_call.json` not consumed/deleted

`python_runner.update()` reads `api_call.json` but does not remove it after handling. Same call may re-execute every frame until overwritten.

### H3 — `killWorker()` kills all Python processes

```208:208:scripting/python_runner.lua
    os.execute('taskkill /F /IM python.exe /T >nul 2>&1')
```

STOP affects **every** `python.exe` on the system, not just the worker.

### H4 — JSON IPC fragility

- `jsonDecode` in Lua is regex-based; nested JSON in player source sent via `command.json` may break encoding for edge cases.
- `command.json` embeds full editor source in JSON string without robust escaping beyond basic `\n`.

---

## Scenario results (doc/v02/11-testing.md)

| ID | Scenario | Result | Evidence |
|----|----------|--------|----------|
| **A** | Fresh start — Coach, starter not full solution | **PARTIAL** | Starter OK; Coach shows step 1 forever |
| **B** | `move_to` + `mine` first success | **FAIL** | B1 + B2 block drone movement |
| **C** | Syntax errors (`:`, indent, `minne`) | **PARTIAL** | Missing `:` PASS; `minne()` FAIL (B3) |
| **D** | Logic errors (mine before move, deposit away) | **FAIL** | Errors swallowed or API broken |
| **E** | Infinite loop / STOP | **FAIL** | Worker returns `done`; wall timeout 30s only if still "running" |
| **F** | Full mission WIN @ 20 | **FAIL** | Cannot automate with Python path |
| **G** | Persistence + RESET preserves code | **PASS** | Code review: save on RUN/debounce/quit; RESET no editor wipe |
| **H** | RUN = editor buffer only | **PASS** | `main.lua:56-63` uses `Editor:getText()` only |

---

## Milestone exit criteria audit

### P0 — Python spike

| Criterion | Status |
|-----------|--------|
| Bundled python works | ❌ Missing |
| 6 API callable | ❌ Bridge broken |
| Blocking move_to/mine | ❌ waitUntil wrong runner |
| SyntaxError surfaces | ✅ Compile path |
| RuntimeError surfaces | ❌ Overwritten by done |
| STOP terminates | ⚠️ Untested live; kills all python.exe |
| Anti-freeze | ❌ Subprocess returns done |
| No regex→Lua | ✅ |

### P1–P2 — Editor

| Criterion | Status |
|-----------|--------|
| RUN = buffer | ✅ |
| Multiline + indent + scroll | ✅ (code review) |

### P3 — Errors

| Criterion | Status |
|-----------|--------|
| Beginner messages | ⚠️ Defined in mapError but often not reached |
| Line highlight | ⚠️ Would work if errors propagated |

### P4 — Coach + hints

| Criterion | Status |
|-----------|--------|
| Coach visible on boot | ✅ Step 1 text |
| 4-tier hints | ✅ JSON + button (step stuck at 1) |
| API reference F1 | ✅ `data/api_reference.json` |
| Starter not full solution | ✅ |

### P5 — Mission progression

| Criterion | Status |
|-----------|--------|
| 7 steps with detection | ❌ Not wired |
| WIN @ 20 | ❌ Cannot reach via Python |

### P6 — Save

| Criterion | Status |
|-----------|--------|
| Autosave | ✅ |
| RESET preserves code | ✅ |
| run.bat bundled python | ❌ |

---

## What works (credit)

1. **Architecture scaffold** — sensible file layout matching `doc/v02/02-file-structure.md`
2. **V0.2 HUD layout** — 4 zones, F5/Esc/F8/F1 wired in `hud_v02.lua`
3. **Editor** — functional buffer model, auto-indent on `:`, error line highlight hook
4. **Coach copy + hints.json** — beginner-friendly content, 4 tiers per step
5. **API reference** — all 6 functions documented in-game
6. **No fake Python** — real `exec()` in worker; no transpiler
7. **V0.1 preserved** — Lua runner still available via `usePython = false`
8. **Persistence design** — save file, RESET world-only semantics correct in `main.lua`

---

## Recommended fix order (for freebuff)

```text
1. worker.py — return after every error write; never emit done after error
2. python_runner — sim wait loop (replace coroutine waitUntil for Python path)
3. nearest_ore/move_to — stable target id over IPC (e.g. "ore:3" or JSON table)
4. api_call.json — delete after consume
5. killWorker — track worker PID; avoid global taskkill
6. Wire Mission01:onEvent → CoachPanel:setStep from world events
7. vendor/python + run.bat OR fetch script for clean machine
8. Re-run scenarios A–H; update this doc to GREEN
```

---

## freebuff session note

Terminal reported **P6 complete** with suggested followups “Test P7 scenarios / Create gate evidence / Verify LÖVE integration.” This QA confirms followups were necessary — **P0 integration was not actually complete** despite broad UI scaffolding.

---

## Sign-off

| Role | Gate 2 |
|------|--------|
| Automated + code audit | **FAIL** |
| Issue #2 close | **Blocked** |
| Next action | Fix B1–B4, then live LÖVE pass on Windows |
