# V0.2 — 05 Python Runtime

## Requirements (from Issue #2)

| Req | Implementation |
|-----|----------------|
| Real Python | CPython embeddable distribution |
| No user install | Ship `vendor/python/` or first-run fetch |
| No regex→Lua | Worker executes source via `exec()` |
| Blocking API | IPC synchronous call/resume |
| STOP | Terminate worker |
| Anti-freeze | Trace hook + wall timeout + process kill |

---

## Bundled Python layout (Windows)

```text
vendor/python/
├── python.exe
├── python311.dll
├── python311.zip          # stdlib
├── Lib/                   # if not fully in zip
└── codeswarm/             # copy or PYTHONPATH
    ├── worker.py
    ├── codeswarm.py
    └── bootstrap.py
```

### Fetch script (dev/CI)

`scripts/fetch-python.ps1`:

1. Download embeddable zip from python.org (pin version)
2. Extract to `vendor/python/`
3. Enable `import site` in `python311._pth` if needed for local packages

**Release:** bundle includes `vendor/python/` — player double-clicks `run.bat`.

---

## Worker lifecycle

```text
Game boot
  → python_runner: no worker yet

First RUN
  → spawn: vendor/python/python.exe worker.py
  → handshake {"type":"ready"}

Each RUN
  → send {"type":"run","source":"<editor text>"}
  → worker exec in fresh namespace OR reset namespace per run

STOP / ERROR / WIN / timeout
  → send {"type":"stop"} OR kill process
  → worker = nil, spawn on next RUN
```

**Recommendation:** **New namespace per RUN** — simpler than hot-reload state bugs.

---

## `bootstrap.py`

```python
# Pseudocode — implement fully in spike

ALLOWED_BUILTINS = {
    "True", "False", "None",
    "int", "float", "str", "bool",
    "range", "len", "print",  # print → optional no-op or log to dev
    "Exception",
}

def make_globals():
    g = {"__builtins__": {k: __builtins__[k] for k in ALLOWED_BUILTINS}}
    import codeswarm
    g.update({
        "move_to": codeswarm.move_to,
        "nearest_ore": codeswarm.nearest_ore,
        "mine": codeswarm.mine,
        "cargo": codeswarm.cargo,
        "capacity": codeswarm.capacity,
        "deposit": codeswarm.deposit,
    })
    return g
```

`print()` — **optional** route to Coach log in dev; hide from beginner or show small debug strip.

---

## `codeswarm.py` — bridge functions

Each function:

```python
def move_to(target):
    return _rpc("move_to", [target])
```

`_rpc`:

1. Write `{"type":"call","fn":...,"args":...,"call_id":N}` to stdout, flush
2. Block read stdin until `{"type":"resume","call_id":N,"result":...}` or error
3. Raise `RuntimeError(message)` if Lua returns error

---

## Lua `python_runner.lua` — spawn

Windows example (use love.filesystem or io):

```lua
-- Pseudocode
local cmd = string.format('"%s" "%s"', pythonExe, workerPath)
-- Option A: love.thread (if available) — not in all LOVE builds
-- Option B: os.execute redirect — awkward for IPC
-- Option C: ffi socket/pipe — heavy
-- Recommended Option D: io.popen with cmd that runs worker.py reading/writing pipes
```

**Spike must pick one working approach on Windows 10/11.**

Document chosen approach in `python/README.md` after P0.

### Non-blocking read pattern

Each `love.update`:

```lua
function python_runner.update(dt)
  if not worker then return end
  drainStdout()  -- parse complete lines
  if pendingCall then
    api.tickSimulation(dt)
    if simIdle then sendResume(pendingCall) end
  end
  checkWallTimeout(dt)
end
```

Main thread **never** blocks on Python.

---

## Error serialization

Python side:

```python
except SyntaxError as e:
    emit({"type":"error","kind":"SyntaxError","message":str(e),"line":e.lineno})
except IndentationError as e:
    emit({"type":"error","kind":"IndentationError",...})
except Exception as e:
    emit({"type":"error","kind":type(e).__name__,"message":str(e),"line":extract_tb_line(e)})
```

Lua sets `status = ERROR`, passes to `coach/errors.lua`.

---

## Anti-freeze strategy (layered)

| Layer | Mechanism |
|-------|-----------|
| 1 | **Process kill** on STOP — always works |
| 2 | **Wall clock** — if RUN > 30s without progress → error "Your loop may be infinite" |
| 3 | **Instruction budget** — `sys.settrace` count lines; exceed → raise in worker |
| 4 | **Progress detection** — reset wall timer on mine/deposit/move complete |

### Instruction budget (worker)

```python
MAX_OPS = 50000  # match V0.1 spirit

def trace(frame, event, arg):
    if event == "line":
        global ops
        ops += 1
        if ops > MAX_OPS:
            raise RuntimeError("Instruction budget exceeded — check for infinite loop")
    return trace
```

Arm trace before `exec`, disarm after.

### LuaJIT lesson from V0.1

V0.1 Lua runner uses `jit.off` + hook around coroutine — **Python worker is separate process**, so LuaJIT hooks don't apply to Python loops. Budget must live **in Python worker**.

---

## Security notes (V0.2 proportionate)

- Subprocess sandbox: no imports except bootstrap
- Kill on STOP — no zombie
- No network in worker
- Player code never passed to `loadstring` in Lua

---

## Platform scope V0.2

| Platform | Priority |
|----------|----------|
| Windows 10/11 | **P0 required** |
| macOS / Linux | Nice-to-have post-V0.2 |

`run.bat` Windows-first; document manual love launch for others.

---

## P0 spike checklist (copy for PR)

```markdown
- [ ] worker starts from bundled python.exe
- [ ] move_to(nearest_ore()) moves drone on screen
- [ ] mine() increments cargo HUD
- [ ] deposit() at base increments deposited
- [ ] SyntaxError shows line number in Lua log/panel
- [ ] while True: x=1 stops via budget or timeout
- [ ] STOP kills worker, window responsive
- [ ] grep repo: no python-to-lua regex transpiler
```

---

## Alternatives considered (record only)

| Alternative | Why not V0.2 |
|-------------|--------------|
| Pyodide in browser build | Not LÖVE desktop target |
| Micropython | Not full Python syntax/teaching |
| Transpile to Lua | Issue forbids |
| System Python | Player install forbidden |
