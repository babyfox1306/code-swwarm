# 02 — File Structure

## Cây thư mục đầy đủ (target)

```text
code-swwarm/
├── main.lua                    # LÖVE entry, callbacks
├── conf.lua                    # Window config
├── README.md
│
├── doc/                        # Bộ plan này
│
├── game/
│   ├── constants.lua           # WIN target, speeds, timers, colors fallback
│   ├── world.lua               # World orchestrator: init, update, draw, reset
│   ├── drone.lua               # Drone entity + state machine
│   ├── ore.lua                 # Ore node factory + mine helpers
│   ├── base.lua                # Base entity + deposit logic
│   └── effects.lua             # VFX: mining beam, deposit pulse, particles
│
├── scripting/
│   ├── runner.lua              # RUN/STOP/RESET, coroutine tick, budget
│   ├── sandbox.lua             # Restricted env builder
│   └── api.lua                 # Player-facing API implementation
│
├── ui/
│   └── hud.lua                 # HUD panels, buttons, win overlay
│
├── player/
│   └── program.lua             # Default player script (editable)
│
└── assets/
    ├── SOURCE.md               # Licenses cho mọi asset bên thứ 3
    ├── vendor/
    │   └── robot-lab/          # PNG gốc từ itch pack
    ├── sprites/                # Sprite đã cắt/sẵn sàng dùng
    ├── tiles/                  # Floor/wall tiles
    ├── ui/                     # Panel, button graphics (optional)
    └── audio/
        ├── sfx/
        └── music/
```

> Nếu cấu trúc nhỏ hơn mà rõ ràng hơn — OK. **Không** thêm thư mục chỉ để khớp diagram.

---

## Spec từng file

### `main.lua`

**Vai trò:** Entry point duy nhất của LÖVE.

**Exports / callbacks:**

| Callback | Nhiệm vụ |
|----------|----------|
| `love.load()` | Init world, runner, hud, load assets, set filter nearest |
| `love.update(dt)` | `runner.update(dt)` → `world.update(dt)` → `hud.update(dt)` |
| `love.draw()` | `world.draw()` → `hud.draw()` |
| `love.mousepressed(x,y,button)` | HUD button hit test |
| `love.keypressed(key)` | Shortcuts RUN/STOP/RESET |
| `love.quit()` | Cleanup (optional) |

**Không chứa:** drone movement math, sandbox logic.

**Gợi ý khung:**

```lua
local world = require("game.world")
local runner = require("scripting.runner")
local hud = require("ui.hud")

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    world.init()
    runner.init(world)
    hud.init(runner, world)
end

function love.update(dt)
    runner.update(dt)
    world.update(dt)
    hud.update(dt)
end
```

---

### `conf.lua`

```lua
function love.conf(t)
    t.window.title = "CODE SWARM"
    t.window.width = 960
    t.window.height = 540
    t.window.resizable = false
    t.console = true  -- Windows: giúp debug print
end
```

---

### `game/constants.lua`

**Single source of truth** cho tuning. Xem [09-constants.md](./09-constants.md).

Export table `C` hoặc `Constants`.

---

### `game/world.lua`

| Function | Mô tả |
|----------|-------|
| `init()` | Tạo base, drone, 3 ore nodes, load tilemap layout |
| `reset()` | Restore initial state (gọi từ RESET) |
| `update(dt)` | Delegate drone/ore/effects; check win |
| `draw()` | Draw floor → base → ores → drone → effects |
| `findNearestOre(x,y)` | Trả ore node gần nhất còn ore |
| `getBase()` | Trả base ref cho api |
| `getDrone()` | Trả drone ref **nội bộ** — không expose player |
| `isWon()` | boolean |
| `getDepositedOre()` | number |

**World state table (nội bộ):**

```lua
{
    base = Base,
    drone = Drone,
    ores = { Ore, Ore, Ore },
    depositedOre = 0,
    won = false,
    effects = Effects,
}
```

---

### `game/drone.lua`

| Function | Mô tả |
|----------|-------|
| `new(opts)` | Factory: x, y, cargo=0, capacity, speed |
| `reset(initial)` | Về vị trí base, clear cargo/state |
| `update(dt, world)` | Thực thi moving/mining/depositing |
| `draw()` | Sprite + bob offset |
| `requestMove(targetPos)` | Set state moving |
| `requestMine(oreNode)` | Set state mining |
| `requestDeposit(base)` | Set state depositing |
| `isBusy()` | boolean — api yield condition |
| `getCargo()` / `getCapacity()` | Numbers |

**State transitions:** xem [06-simulation.md](./06-simulation.md)

---

### `game/ore.lua`

| Function | Mô tả |
|----------|-------|
| `new(id, x, y, amount)` | Ore node |
| `reset()` | Restore full amount |
| `mine(drone, dt)` | Trả ore mined this tick hoặc complete flag |
| `draw()` | Sprite + depleted visual |
| `hasOre()` | remaining > 0 |
| `getPosition()` | x, y |

---

### `game/base.lua`

| Function | Mô tả |
|----------|-------|
| `new(x, y)` | Base station |
| `getPosition()` | x, y |
| `isDroneInRange(drone)` | Distance check cho deposit |
| `draw()` | Sprite + deposit pulse from effects |
| `depositFrom(drone)` | Transfer cargo → return amount deposited |

---

### `game/effects.lua`

| Function | Mô tả |
|----------|-------|
| `spawnMiningEffect(x,y)` | Beam/particles |
| `spawnDepositEffect(x,y)` | Pulse at base |
| `update(dt)` / `draw()` | Particle pool đơn giản |

Không bắt buộc OOP — table + list particles là đủ.

---

### `scripting/runner.lua`

| Function | Mô tả |
|----------|-------|
| `init(worldRef)` | Lưu world reference |
| `run()` | Load program, start coroutine |
| `stop()` | Halt execution |
| `reset()` | stop + signal world reset |
| `update(dt)` | Instruction budget + resume coroutine |
| `getStatus()` | idle/running/stopped/error/won |
| `getError()` | string | nil |
| `onWin()` | Called when world wins |

---

### `scripting/sandbox.lua`

| Function | Mô tả |
|----------|-------|
| `loadProgram(path)` | Đọc file, return chunk |
| `compile(chunk)` | `load(..., env)` với restricted env |
| `createEnv(api)` | Build sandbox table |

---

### `scripting/api.lua`

| Function | Player-visible |
|----------|----------------|
| `move_to(target)` | ✓ |
| `nearest_ore()` | ✓ |
| `mine()` | ✓ |
| `cargo()` | ✓ |
| `capacity()` | ✓ |
| `deposit()` | ✓ |
| `waitUntilIdle()` | ✗ internal |
| `setRunner(runner)` | ✗ wiring |

API functions **yield** qua runner helper.

---

### `ui/hud.lua`

| Function | Mô tả |
|----------|-------|
| `init(runner, world)` | Layout rects, load fonts |
| `update(dt)` | Button states |
| `draw()` | Full HUD |
| `mousepressed(x,y,btn)` | Return handled |
| `keypressed(key)` | Shortcuts |

**UI regions:** xem [07-ui-hud.md](./07-ui-hud.md)

---

### `player/program.lua`

Script mặc định — copy từ issue. Player sửa file này trong editor.

```lua
while true do
    while cargo() < capacity() do
        move_to(nearest_ore())
        mine()
    end

    move_to("base")
    deposit()
end
```

---

### `assets/SOURCE.md`

Template:

```markdown
# Asset Sources

## Sprites — Robot Lab Asset Pack
- Author: Murphy's Dad
- Source: https://murphysdad.itch.io/robot-lab-asset-pack
- License: CC0 1.0
- Files used: drone.png, floor.png, ...

## Audio — (tên pack)
- ...
```

---

## `package.path` setup

Trong `main.lua` đầu file:

```lua
-- Cho phép require("game.world") từ root
local root = love.filesystem.getSource()
package.path = package.path .. ";" .. root .. "/?.lua"
                              .. ";" .. root .. "/?/init.lua"
```

Hoặc dùng relative requires tùy convention — **nhất quán** trong toàn repo.

---

## Files KHÔNG tạo trong V0.1

```text
lib/
vendor/lua/          # third-party lua libs
scenes/level1.json    # scene editor output
.editorconfig         # optional, không bắt buộc
tests/                # unless explicitly requested later
```
