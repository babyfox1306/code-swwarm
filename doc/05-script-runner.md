# 05 — Script Runner & Sandbox

> Phần **kỹ thuật quan trọng nhất** của V0.1.  
> Làm sai ở đây = game freeze hoặc player hack world.

---

## Tổng quan

```text
RUN pressed
    → read player/program.lua
    → sandbox.compile(chunk)
    → coroutine.create(fn)
    → each frame: resume with instruction budget
    → API calls yield until simulation done
    → error or complete or STOP or WIN
```

---

## `scripting/sandbox.lua`

### Load program

```lua
function sandbox.loadProgram(path)
    path = path or "player/program.lua"
    local info = love.filesystem.getInfo(path)
    if not info then
        return nil, "Program file not found: " .. path
    end
    local source = love.filesystem.read(path)
    return source, nil
end
```

### Restricted environment

```lua
function sandbox.createEnv(api)
    return {
        -- Player API only
        move_to = api.move_to,
        nearest_ore = api.nearest_ore,
        mine = api.mine,
        cargo = api.cargo,
        capacity = api.capacity,
        deposit = api.deposit,
    }
end
```

### Compile

```lua
function sandbox.compile(source, env)
    local fn, err = load(source, "@player/program.lua", "t", env)
    if not fn then
        return nil, "Syntax error: " .. err
    end
    return fn, nil
end
```

### Không expose

| Blocked | Lý do |
|---------|-------|
| `io` | filesystem |
| `os` | execute, exit |
| `package` | load arbitrary modules |
| `debug` | hooks, upvalues |
| `load` / `loadfile` / `dofile` | arbitrary code |
| `require` | unless whitelisted internal — player không có |
| `love` | engine internals |
| `_G` | global escape hatch |

---

## `scripting/runner.lua` — State

```lua
local runner = {
    status = "idle",       -- idle | running | stopped | error | won
    errorMessage = nil,
    co = nil,
    fn = nil,
    world = nil,
    instructionsThisFrame = 0,
    INSTRUCTION_BUDGET = 50000,
}
```

---

## Instruction budget (chống infinite loop) — LuaJIT-safe

### Yêu cầu bắt buộc (LÖVE 11 = LuaJIT 2.1)

1. **`jit.off(fn, true)`** sau khi compile player chunk — JIT-compiled loops **bỏ qua** debug hooks.
2. **Hook chỉ arm quanh `coroutine.resume()`** — tháo ngay sau resume; không set hook lúc `coroutine.create` và để sống suốt khi drone yield.
3. **Count mode `"c"`** với `HOOK_INSTRUCTION_INTERVAL`; budget cộng theo interval (50k instructions thật).

```lua
local jit_ok, jit = pcall(require, "jit")

if jit_ok and jit.off then
    jit.off(fn, true)
end

Runner.co = coroutine.create(function()
    fn()  -- no sethook here
end)

-- each frame in Runner.update:
armHook(co)
local ok, err = coroutine.resume(co)
clearHook(co)
```

### QA: Scenario C3 (JIT-friendly)

```lua
local x = 0
while true do x = x + 1 end
```

C/C2 (`while true do end`, `while true do cargo() end`) **không đủ** — phải pass C3 trên máy thật.

### Debug hook (implementation)

```lua
local function hook(event)
    if event == "count" then
        Runner.instructionsThisFrame = Runner.instructionsThisFrame + C.HOOK_INSTRUCTION_INTERVAL
        if Runner.instructionsThisFrame > C.INSTRUCTION_BUDGET then
            error("Execution stopped: instruction budget exceeded", 0)
        end
    end
end
```

### Cách 2 — Count hook mỗi resume

Mỗi `coroutine.resume`, reset counter; hook increment.

### Khi budget exceeded

- Catch error
- `status = "error"` (hoặc `"stopped"`)
- `errorMessage = "Execution stopped: instruction budget exceeded"`
- Clear hook
- Drone: cancel pending action → idle

---

## Coroutine yield protocol

### Runner helpers

```lua
function runner.waitUntil(predicate)
    while not predicate() do
        if runner.status ~= "running" then
            error("Execution stopped", 0)
        end
        coroutine.yield("wait")
    end
end

function runner.yield()
    coroutine.yield("api")
end
```

### API usage

```lua
function api.move_to(target)
    startMove(target)
    runner.waitUntil(function()
        return drone.state == "idle"
    end)
end
```

### Update loop

```lua
function runner.update(dt)
    if runner.status ~= "running" or not runner.co then
        return
    end

    runner.instructionsThisFrame = 0

  local ok, err = coroutine.resume(runner.co)

    if not ok then
        debug.sethook(runner.co, nil)
        runner.status = "error"
        runner.errorMessage = tostring(err)
        runner.co = nil
        return
    end

    if coroutine.status(runner.co) == "dead" then
        debug.sethook(runner.co, nil)
        if runner.status == "running" then
            runner.status = "idle"  -- script ended naturally
        end
        runner.co = nil
    end
end
```

**Thứ tự quan trọng:** `world.update` chạy **cùng frame** sau `runner.update` resume — để drone tiến khi coroutine đang yield.

Đề xuất trong `main.lua`:

```lua
function love.update(dt)
    runner.update(dt)   -- resume coroutine (may set intents)
    world.update(dt)    -- simulate movement (progress toward yield condition)
end
```

---

## RUN

```lua
function runner.run()
    if runner.status == "won" then
        return  -- must RESET first
    end

    runner.stop()  -- clear previous

    local source, err = sandbox.loadProgram()
    if not source then
        runner.status = "error"
        runner.errorMessage = err
        return
    end

    local env = sandbox.createEnv(api)
    local fn, compileErr = sandbox.compile(source, env)
    if not fn then
        runner.status = "error"
        runner.errorMessage = compileErr
        return
    end

    runner.fn = fn
    runner.co = coroutine.create(function()
        debug.sethook(hook, "", 1000)
        fn()
    end)
    runner.status = "running"
    runner.errorMessage = nil

    -- play SFX run_start
end
```

Reload file mỗi RUN — player sửa `program.lua` externally rồi RUN lại.

---

## STOP

```lua
function runner.stop()
    if runner.co then
        debug.sethook(runner.co, nil)
        runner.co = nil
    end
    runner.fn = nil

    if runner.status == "running" then
        runner.status = "stopped"
    end

    -- Cancel drone pending action
    world.getDrone():cancelAction()

    -- play SFX run_stop
end
```

---

## RESET

```lua
function runner.reset()
    runner.stop()
    world.reset()
    runner.status = "idle"
    runner.errorMessage = nil
end
```

`world.reset()` must restore:
- drone pos/cargo/state
- all ore nodes
- deposited = 0
- won = false
- clear effects

---

## WIN handling

```lua
function runner.onWin()
    runner.stop()
    runner.status = "won"
    -- play win SFX
end
```

Gọi từ `world` sau deposit khi `deposited >= 20`.

Script đang `while true` sẽ bị stop — OK.

---

## Error display format

Strip debug paths nếu quá dài, giữ message core:

```lua
function runner.getError()
    return runner.errorMessage
end
```

HUD hiển thị nguyên string hoặc wrap:

```text
ERROR
Runtime error: attempt to call global 'foo' (a nil value)
```

---

## Test matrix — runner only

| Program | Expected status | Game responsive |
|---------|-----------------|-----------------|
| valid mining loop | running → won | ✓ |
| `while true do end` | error (budget) | ✓ |
| `foo()` | error | ✓ |
| empty file | error (syntax) | ✓ |
| STOP during move | stopped | ✓ |
| RESET during mine | idle, world reset | ✓ |

---

## Pitfalls — tránh

| Pitfall | Hậu quả | Fix |
|---------|---------|-----|
| Gọi `fn()` trực tiếp không coroutine | freeze | always `coroutine.create` |
| Busy-wait trong api | freeze | `coroutine.yield` |
| Expose `_G` | player gọi `os.execute` | restricted env |
| Không clear debug hook | leak / slow | clear on stop/error/dead |
| `world.update` trước `runner.update` | yield condition never met | đúng thứ tự hoặc 2-pass |
| Resume nhiều lần per frame | script chạy quá nhanh | 1 resume/frame đủ |

---

## Optional: print capture

```lua
env.print = function(...)
    hud.appendLog(table.concat({...}, "\t"))
end
```

Chỉ bật nếu dễ — không bắt buộc V0.1.
