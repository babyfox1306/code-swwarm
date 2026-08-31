# V0.2 — 02 File Structure

## Cây thư mục mục tiêu

```text
code-swwarm/
├── main.lua                    # Route V0.2 UI, wire python_runner
├── conf.lua
├── run.bat                     # Launch + verify bundled python path
│
├── game/                       # UNCHANGED simulation core
│   ├── world.lua
│   ├── drone.lua
│   ├── ore.lua
│   ├── base.lua
│   ├── effects.lua
│   ├── assets.lua
│   ├── audio.lua
│   └── constants.lua
│
├── scripting/
│   ├── api.lua                 # Internal Lua bridge (python_runner calls)
│   ├── runner.lua              # V0.1 Lua runner — dev/QA only
│   ├── sandbox.lua
│   └── python_runner.lua       # NEW — IPC, yield, STOP/WIN
│
├── python/
│   ├── worker.py               # NEW — subprocess entry, IPC loop
│   ├── codeswarm.py            # NEW — player-visible API module
│   ├── bootstrap.py            # NEW — restricted imports, trace hook
│   └── README.md               # Dev notes (not player-facing)
│
├── ui/
│   ├── hud_v02.lua             # NEW — layout V0.2
│   ├── editor.lua              # NEW — multiline buffer, caret, scroll
│   ├── coach_panel.lua         # NEW — mission + coach text
│   ├── api_reference.lua       # NEW — in-game API docs panel
│   ├── error_panel.lua         # NEW — beginner errors + line ref
│   └── hud.lua                 # V0.1 — keep for regression/dev toggle
│
├── coach/
│   ├── mission01.lua           # NEW — step state, objectives, unlocks
│   ├── hints.lua               # NEW — 4-tier hint loader
│   └── errors.lua              # NEW — map Python errors → beginner copy
│
├── data/
│   ├── mission01/
│   │   ├── starter.py          # NEW — partial starter, NOT full solution
│   │   ├── coach_steps.json    # NEW — step text (optional split)
│   │   └── hints.json          # NEW — tier 1–4 per step
│   └── api_reference.json      # NEW — structured API docs for UI
│
├── vendor/
│   └── python/                 # NEW — embeddable CPython (git-lfs or script)
│       ├── python.exe
│       ├── python311.zip
│       └── ...
│
├── player/
│   └── program.lua             # DEPRECATED player path — qa/dev only
│
├── qa/
│   └── lua_smoke.lua           # Optional — V0.1 runner smoke
│
├── doc/
│   └── v02/                    # This plan
│
└── assets/                     # UNCHANGED
```

## Spec từng file mới

### `scripting/python_runner.lua`

| Responsibility | |
|----------------|---|
| Spawn/maintain worker subprocess | `love.system` / `io.popen` / `os.execute` wrapper |
| Send `run` with editor source | On RUN |
| Read stdout JSON lines each frame | Non-blocking where possible |
| On `call`: invoke `api.lua`, yield sim | Same as V0.1 runner yield |
| STOP / WIN / budget / timeout | Mirror V0.1 semantics |
| Expose events to Coach | `onMined`, `onDeposited`, `onError` |

**Must not:** parse Python syntax in Lua.

### `python/worker.py`

| Responsibility | |
|----------------|---|
| Read stdin JSON lines | Blocking in worker thread OK |
| `exec` user source in restricted globals | `codeswarm` only |
| Serialize API calls to stdout | |
| Catch exceptions → error JSON | With line number |
| Handle `stop` message | Clean exit |

### `python/codeswarm.py`

Player-facing module — **exactly 6 functions**:

```python
def move_to(target): ...
def nearest_ore(): ...
def mine(): ...
def cargo(): ...
def capacity(): ...
def deposit(): ...
```

Docstrings = source for API reference panel.

### `ui/editor.lua`

| Field / method | |
|----------------|---|
| `lines` | table of strings |
| `caretRow`, `caretCol` | |
| `scrollY` | |
| `getText()` | join lines with `\n` |
| `setText(s)` | load starter / saved |
| `insert`, `backspace`, `newline` | |
| `handleKey`, `handleTextInput` | love callbacks |
| `draw(x,y,w,h)` | monospace, line numbers optional |
| `highlightLine(n)` | error state |

### `coach/mission01.lua`

| API | |
|-----|---|
| `getCurrentStep()` | 1..N |
| `getCoachText()` | string for panel |
| `onEvent(name, data)` | simulation hooks |
| `canAdvance()` | optional soft check |
| `advanceStep()` | on objective met |

### `data/mission01/starter.py`

**Rules:**

- Comments welcome (`# TODO: ...`)
- May include **one** example line commented out
- **Must NOT** contain working full loop + deposit 20 solution
- Example allowed start:

```python
# Mission 01: Teach the drone to collect ore.
# Step 1: Move to the nearest ore.

# Your code below:

```

### `data/mission01/hints.json`

Structure per step:

```json
{
  "step_1": {
    "tier1": "Think: the drone needs to know WHERE to go.",
    "tier2": "API: nearest_ore() returns a target. move_to(...) sends the drone.",
    "tier3": "Shape:\nmove_to(nearest_ore())",
    "tier4": "move_to(nearest_ore())"
  }
}
```

Tier 4 = solution for **that micro-step only**, not full mission.

### Save file

Path: `love.filesystem.getSaveDirectory()/mission01_code.py`

- Autosave on edit debounce (e.g. 2s) or on RUN
- Load on boot into editor
- RESET world does **not** delete this file

## `main.lua` changes (outline)

```lua
-- Pseudocode responsibilities
require("ui.hud_v02")
require("scripting.python_runner")
require("coach.mission01")

function love.load()
  -- load assets, world, editor from save or starter.py
end

function love.update(dt)
  python_runner.update(dt)
  world:update(dt)
end

function love.keypressed(key)
  if editor:focused() then editor:handleKey(key)
  elseif key == "f5" then doRun() end
end

function doRun()
  local src = editor:getText()
  python_runner.run(src)
end
```

## `run.bat` changes

- Verify `vendor\python\python.exe` exists
- Set env `CODESWARM_PYTHON=...` if needed
- Launch LÖVE with quoted path (space-safe)

## Git / binary policy

| Asset | Policy |
|-------|--------|
| `vendor/python/` | Git LFS **or** download script in `scripts/fetch-python.ps1` documented in README |
| `data/*.json` | Commit |
| Player saves | Never in repo |

Document fetch in root README — player không chạy script nếu release bundle includes python.

## Dev toggle (optional)

Env `CODESWARM_DEV=1`:

- Show Lua runner shortcut
- Skip Coach (QA only)

**Hidden from default player build.**
