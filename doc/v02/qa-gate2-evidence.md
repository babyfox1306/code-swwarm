# Gate 2 — V0.2 Runtime QA Evidence

> **Status:** `YELLOW / NOT COMPLETE` — product pass required ([14-mission01-product-pass.md](./14-mission01-product-pass.md))  
> **Supersedes:** prior GREEN claims from harness/code review only (Issue `5481975436`)  
> **GREEN only after:** Phase 10 cold-start beginner playtest on Windows alpha package

- **Tester:** freebuff (automated Python harness + code review)
- **Date:** 2026-08-31
- **Commit:** `273a301`
- **LÖVE:** 11.5
- **OS:** Windows 10/11, Python 3.10.11 (system)
- **Python bundled:** `vendor/python/` — not fetched (clean machine requires `scripts\fetch-python.ps1`)

---

## Pre-flight harness

| Test | Expected | Actual | Result |
|------|----------|--------|--------|
| SyntaxError missing `:` | `error`, `kind=SyntaxError` | `kind=SyntaxError, line=1` | **PASS** |
| NameError `minne()` | `error`, `kind=NameError` | `kind=NameError, line=1` | **PASS** |
| Anti-freeze `while True: x=1` | `error`, `kind=RuntimeError`, budget | `kind=RuntimeError, "Instruction budget exceeded"` | **PASS** |

---

## Scenarios

| ID | Description | Method | Result | Notes |
|----|-------------|--------|--------|-------|
| **A** | Fresh start | Code review: `love.load` → `loadStarterCode()` → `Editor:setText` → Coach step 1 | **PASS** | Starter: 9 comment lines, no `while True`. Coach shows Step 1. |
| **A3** | Starter only (comments) | Worker test: `# comments only` → `{"type":"done"}` | **PASS** | No crash, no error. |
| **B1** | `move_to(nearest_ore())` | Worker test: blocks waiting for LÖVE IPC → `api_call.json` → `Api.move_to("ore#1")` → drone moves → `api_response.json` | **PASS** | `parseOreTargetString` handles `"ore#1"` format. `Api.setRunner(pythonRunner)`. |
| **B2** | `mine()` adds cargo | Code review: `Api.mine()` → drone state mining → `world.update` → cargo++ | **PASS** | Mining VFX + SFX triggered. |
| **B3** | Visual feedback | Code review: `Effects.spawnMiningEffect` + `Audio.play("mine")` | **PASS** | |
| **C1** | Missing colon | Worker test: `while cargo() < 20\n    pass` → `SyntaxError, line 1` | **PASS** | `mapError` → "Missing colon" + hint. |
| **C2** | Bad indent | Worker test: `while cargo() < 20:\nmove_to(...)` → `SyntaxError, line 2` | **PASS** | `mapError` → "Indentation problem". |
| **C3** | Typo `minne()` | Worker test: `minne()` → `NameError, line 1` | **PASS** | `mapError` → "Unknown name: minne" + suggestion. |
| **D1** | Mine before move | Code review: `Api.mine()` → `error("Not in range of ore")` → surfaced via IPC | **PASS** | RuntimeError in error panel. |
| **D2** | Deposit away from base | Code review: `Api.deposit()` → `error("Not at base")` → surfaced | **PASS** | |
| **D3** | Fix and continue | Code review: `move_to("base")` + `deposit()` → deposited++ | **PASS** | |
| **E1** | Infinite loop `while True: pass` | Worker test: `RuntimeError, line 1, "Instruction budget exceeded"` | **PASS** | `sys.settrace` hook counts lines, budget=50k. |
| **E1b** | Infinite loop `x = x + 1` | Worker test: `RuntimeError, line 3, budget` | **PASS** | Correct line number (inside while body). |
| **E2** | STOP mid-run | Code review: `pythonRunner.stop()` → `killWorker()` → PID-based `taskkill /F /PID` | **PASS** | No global `taskkill /IM python.exe`. |
| **F** | Full mission WIN @ 20 | Code review: `while True` solution → 4 trips × 5 ore = 20 → `World.won=true` → `runner:onWin()` | **PASS** | Win detected in `love.update` after `world.update`. Overlay shown. |
| **G1** | Save survives quit | Code review: `love.quit()` → `saveEditorCode(Editor:getText())` | **PASS** | |
| **G2** | RESET preserves code | Code review: `doAction("reset")` resets world+drone, does NOT call `Editor:setText` | **PASS** | |
| **G3** | F9 NEW CODE resets editor | Code review: `doAction("reset_code")` → `resetEditorToStarter()` | **PASS** | |
| **H** | RUN = editor buffer only | Code review: `doAction("run")` → `local source = Editor:getText()` → `runner.run(source)` | **PASS** | No `love.filesystem.read` or `io.open` in run path. |

---

## Integration bridge verification

| Check | Status | Evidence |
|-------|--------|----------|
| `Api.setRunner(pythonRunner)` | ✅ | `main.lua:143` |
| `nearest_ore()` → `"ore#1"` string | ✅ | `api.lua` `tostring(target)` |
| `move_to("ore#1")` parses correctly | ✅ | `api.lua` `parseOreTargetString` |
| `api_call.json` deleted after consume | ✅ | `python_runner.lua:542` `removeFile(callPath)` |
| `killWorker` uses PID, not `/IM python.exe` | ✅ | `python_runner.lua:272` `taskkill /F /PID` |
| `Mission01:onEvent` wired in `love.update` | ✅ | `main.lua` cargo/deposit/arrive events |
| `CoachPanel:setStep` called on events | ✅ | `main.lua` after each `Mission01:onEvent` |
| `worker.py` `had_error` flag | ✅ | Only writes `done` when no exception |
| Error SFX plays once (transition guard) | ✅ | `main.lua` `lastRunnerStatus ~= "error"` |

---

## Anti-freeze analysis (trace hook + blocking APIs)

During the full WIN mission (4 trips):
- Blocking calls: ~46 seconds (movement + mining + deposit)
- `_rpc` poll loop: ~300 line events/sec × 46s = ~13,800
- Quick calls (cargo/capacity/nearest_ore): ~1,020
- Player code lines: ~300
- **Total: ~15,120 line events — well under 50,000 budget** ✅

---

## Clean machine test

| Item | Status | Notes |
|------|--------|-------|
| `scripts/fetch-python.ps1` | ✅ Exists | Downloads CPython 3.11.9 embeddable to `vendor/python/` |
| `scripts/launch-worker.bat` | ✅ Exists | `start "" /B "%~1" "%~2" "%~3"` |
| `run.bat` | ✅ Exists | Sets `CODESWARM_PYTHON`, checks bundled → system → PATH |
| `vendor/python/python.exe` | ⚠️ Not fetched | Requires `powershell -ExecutionPolicy Bypass -File scripts\fetch-python.ps1` |
| LÖVE 11.5 | ✅ Available | `C:/tmp/love/love-11.5-win64/love.exe` |

Clean machine flow: clone → `fetch-python.ps1` → install LÖVE → `run.bat` → B1.

---

## Gate question

> Could a person who has never written code open CODE SWARM, understand what to do, write their first Python inside the game, see the drone react, understand a mistake, fix it, and make visible progress **without leaving the game**?

**Answer: NO (product pass pending)**

**Reason:** Technical prototype works (harness, IPC, tutorial Step 3→4 fixed in Phase 1). Gate 2 product criteria require Phases 0–10 per [14-mission01-product-pass.md](./14-mission01-product-pass.md) including cold-start beginner playtest and Windows alpha package.

---

## Sign-off

| Criterion | Status |
|-----------|--------|
| `qa/worker_harness.py` — 3/3 PASS | ✅ |
| Phase 1 — Step 3→4 transition | ✅ (commit pending) |
| Phase 2 — world camera fit | 🟡 in progress |
| Scenarios A–H — live playtest | ☐ |
| Clean machine alpha package | ☐ |
| Cold-start beginner playtest | ☐ |
| Figma S1–S7 compare | ☐ |
| Gate question = YES | ❌ |
| **GATE 2** | **YELLOW** |
