# 09 — Constants

> **Một file duy nhất** cho magic numbers.  
> File: `game/constants.lua`

---

## Full constants table

```lua
local C = {}

-- ─── Win condition ───────────────────────────────────────────
C.WIN_ORE_TARGET = 20

-- ─── Drone ───────────────────────────────────────────────────
C.DRONE_SPEED = 120              -- pixels / second
C.CARGO_CAPACITY = 5
C.DRONE_START_X = 80
C.DRONE_START_Y = 200

-- ─── Ranges (pixels) ─────────────────────────────────────────
C.ARRIVAL_DISTANCE = 8           -- move_to complete threshold
C.MINING_RANGE = 24              -- must be within to mine()
C.BASE_RANGE = 48                -- must be within to deposit()

-- ─── Action durations (seconds) ────────────────────────────────
C.MINE_DURATION = 1.5
C.DEPOSIT_DURATION = 0.6

-- ─── Ore ─────────────────────────────────────────────────────
C.ORE_PER_MINE = 1               -- ore units per mine() action
C.ORE_INITIAL_AMOUNT = 10        -- per node

-- Ore positions (world coords, inside 800×400 play area)
C.ORE_POSITIONS = {
    { id = 1, x = 400, y = 80  },
    { id = 2, x = 650, y = 200 },
    { id = 3, x = 400, y = 320 },
}

-- ─── Base ────────────────────────────────────────────────────
C.BASE_X = 80
C.BASE_Y = 200

-- ─── World viewport (for draw/scissor) ───────────────────────
C.WORLD_X = 80
C.WORLD_Y = 80
C.WORLD_W = 800
C.WORLD_H = 400

-- ─── Script runner ───────────────────────────────────────────
C.INSTRUCTION_BUDGET = 50000     -- per frame
C.HOOK_INSTRUCTION_INTERVAL = 1000

-- ─── Visual scale ────────────────────────────────────────────
C.SPRITE_SCALE = 2

-- ─── Animation ───────────────────────────────────────────────
C.DRONE_BOB_SPEED = 4            -- radians/sec equivalent
C.DRONE_BOB_AMPLITUDE = 2        -- pixels
C.DRONE_ANIM_FRAME_TIME = 0.15   -- seconds per frame

-- ─── Audio volumes ───────────────────────────────────────────
C.VOL_MUSIC = 0.3
C.VOL_SFX = 0.8
C.VOL_DRONE_LOOP = 0.2

-- ─── Debug ───────────────────────────────────────────────────
C.DEBUG = false                  -- set true during dev only

return C
```

---

## Usage

```lua
local C = require("game.constants")

if world.depositedOre >= C.WIN_ORE_TARGET then
    world.triggerWin()
end
```

---

## Tuning guide

### Game quá chậm

| Knob | Direction |
|------|-----------|
| `DRONE_SPEED` | ↑ 150–180 |
| `MINE_DURATION` | ↓ 1.0 |
| `ORE_PER_MINE` | ↑ 2 |
| `CARGO_CAPACITY` | ↑ 8 (ít trip hơn) |

### Game quá nhanh / không kịp nhìn

| Knob | Direction |
|------|-----------|
| `DRONE_SPEED` | ↓ 80–100 |
| `MINE_DURATION` | ↑ 2.0 |
| `DEPOSIT_DURATION` | ↑ 1.0 |

### Infinite loop quá sớm trigger budget

| Knob | Direction |
|------|-----------|
| `INSTRUCTION_BUDGET` | ↑ 100000 |

Không set quá cao — mất tác dụng chống freeze.

### Mining frustrating (range)

| Knob | Direction |
|------|-----------|
| `MINING_RANGE` | ↑ 32 |
| `ARRIVAL_DISTANCE` | ↑ 12 |

---

## Balance target

- Full WIN run: **45–90 giây** với default script
- Ít nhất **4 chuyến** base (20 ore / 5 cargo)

---

## Không hardcode elsewhere

Bad:

```lua
-- drone.lua
if self.cargo >= 5 then  -- magic number
```

Good:

```lua
if self.cargo >= C.CARGO_CAPACITY then
```

Lint bằng mắt trước merge M10.
