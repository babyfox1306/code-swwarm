# V0.2 — 10 Save & Persistence

## Principles

| Action | Affects world | Affects editor code |
|--------|---------------|---------------------|
| RUN | Yes | No (read only) |
| STOP | Stops script | No |
| RESET WORLD (F8) | Yes — reset positions/state | **No — code preserved** |
| Close game | — | **Saved** |
| Reopen game | Fresh world state OR last sim state* | **Restored** |

*Recommendation: on boot, **reset world** but **restore code** — predictable for beginners. Document choice in implementation.

**Recommended boot behavior:**

```text
Load saved code → editor
Reset world to Mission 01 initial state
Coach step: infer from empty progress OR always start Coach at current step with sim reset
```

If sim state persisted, beginner may confuse ore counts — **prefer world reset on boot, code persist only.**

---

## Save file

| Field | Value |
|-------|-------|
| Path | `{save_dir}/mission01_code.py` |
| Format | Plain UTF-8 Python source |
| API | `love.filesystem.write/read` |

### Example

```lua
local SAVE_FILE = "mission01_code.py"

function saveEditorCode(text)
  love.filesystem.write(SAVE_FILE, text, "string")
end

function loadEditorCode()
  if love.filesystem.getInfo(SAVE_FILE) then
    return love.filesystem.read(SAVE_FILE)
  end
  return love.filesystem.read("data/mission01/starter.py") -- from source mount
end
```

Use `love.filesystem.load` / mount for `data/` if not in save dir.

---

## When to save

| Trigger | Save? |
|---------|-------|
| Debounced edit (2s after last key) | Yes |
| RUN pressed | Yes |
| STOP | Optional |
| RESET WORLD | Yes (code unchanged but flush OK) |
| WIN | Yes |

**Never save on RESET to starter** unless user explicit "Reset code" — **no such button V0.2**.

---

## Coach progress persistence (optional P6)

| Approach | Pros | Cons |
|----------|------|------|
| A — Don't persist step | Simple | Coach repeats step 1 text |
| B — Persist step in JSON | Better UX | More state |

**Recommendation:** `mission01_progress.json` with `{ "step": 4 }` — optional P6 nice-to-have.

If not implemented, Coach can infer step from `deposited` / events on load.

---

## What NOT to persist V0.2

- Python worker process
- Half-run simulation mid-flight
- Hint tier unlocked (optional — reset hints per session OK)

---

## Migration from V0.1

`player/program.lua` is **not** auto-imported to Python.

First boot V0.2: starter.py only.

Dev note in CHANGELOG — no player action.

---

## Corruption / empty file

| Case | Behavior |
|------|----------|
| Empty save | Load starter.py |
| Read fail | Load starter.py + Coach note |
| Invalid UTF-8 | Load starter + warn in dev log |

---

## QA tests

| # | Steps | Expected |
|---|-------|----------|
| S1 | Type code, wait 3s, quit, reopen | Code restored |
| S2 | Type code, RUN, F8 RESET | Code same, world reset |
| S3 | WIN, reopen | Code saved; world reset (recommended) or WIN state cleared |
| S4 | Delete save file manually | Starter loads |

---

## Player-facing copy

RESET button tooltip:

```text
Reset World (F8)
Resets ore and drone. Your code stays in the editor.
```

No mention of filesystem paths.
