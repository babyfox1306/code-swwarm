# 04 — Player API Specification

> Đây là **hợp đồng công khai** giữa game và player script.  
> Thay đổi signature hoặc semantics = breaking change — **không làm trong V0.1**.

---

## API surface

```lua
move_to(target)    -- blocking
nearest_ore()      -- instant, returns target
mine()             -- blocking
cargo()            -- instant, returns number
capacity()         -- instant, returns number
deposit()          -- blocking
```

Không có globals khác visible cho player.

---

## `move_to(target)`

### Signature

```lua
move_to(target: string | ore_target) -> nil
```

### Accepted targets

| Target | Type | Behavior |
|--------|------|----------|
| `"base"` | string | Di chuyển drone đến vùng base |
| Ore handle | opaque (returned by `nearest_ore()`) | Di chuyển đến ore node đó |

### Behavior

1. Validate target — invalid → `error("Invalid move target: ...")`
2. Nếu ore depleted → `error("Ore node depleted")` (hoặc tương đương)
3. Set drone intent `moving`
4. **Yield** coroutine cho đến khi drone trong range của target
5. Return (nil)

### Range threshold

```lua
ARRIVAL_DISTANCE = 8  -- pixels, tune in constants
```

### Must NOT

- Teleport instantly
- Expose `{x=, y=}` cho player để tự set
- Block main thread without yielding

### Examples

```lua
move_to("base")
move_to(nearest_ore())
```

### Error cases

```lua
move_to("moon")        -- Invalid move target
move_to(123)           -- Invalid move target
move_to(nil)           -- Invalid move target
```

---

## `nearest_ore()`

### Signature

```lua
nearest_ore() -> ore_target
```

### Behavior

1. Tìm ore node còn `remaining > 0` gần nhất theo Euclidean distance từ drone
2. Nếu không có → `error("No ore available")`
3. Return opaque handle (không phải table modifiable)

### Handle implementation (gợi ý nội bộ)

```lua
-- Internal structure — player không thấy fields
{ __type = "ore_target", id = 2 }
```

Metatable `__tostring` → `"ore#2"` (debug friendly, optional)

### Must NOT

- Return nil silently (phải error nếu hết ore)
- Return raw world ore table

---

## `mine()`

### Signature

```lua
mine() -> nil
```

### Preconditions

- Drone trong mining range của **một** ore node
- Ore node còn resource
- Cargo < capacity

### Behavior

1. Xác định ore node gần nhất trong range (hoặc ore đang đứng tại)
2. Nếu không trong range → `error("Not in range of ore")`
3. Nếu cargo full → `error("Cargo full")`
4. Nếu node empty → `error("Ore depleted")`
5. Start mining action — visible timer
6. **Yield** until mining action completes
7. Transfer ore: `node.remaining -= n`, `drone.cargo += n`

### Mining yield per action

```lua
ORE_PER_MINE_TICK = 1  -- hoặc 2, tune
MINE_DURATION = 1.5    -- seconds
```

### Must NOT

- Instant mine trong 1 frame (cần visible delay)
- Mine through capacity cap

---

## `cargo()`

### Signature

```lua
cargo() -> integer
```

Returns current drone cargo. Always `>= 0`.

---

## `capacity()`

### Signature

```lua
capacity() -> integer
```

Returns max cargo. Constant trong V0.1 (e.g. `5`).

---

## `deposit()`

### Signature

```lua
deposit() -> nil
```

### Preconditions

- Drone trong base range

### Behavior

1. Nếu không tại base → `error("Not at base")`
2. Nếu cargo == 0 → có thể no-op hoặc error — **chọn một**, document:
   - **Recommended:** no-op (return silently) — script loop vẫn chạy
3. Start deposit action — short visible delay (~0.5s)
4. **Yield** until complete
5. `deposited += cargo`, `cargo = 0`
6. If `deposited >= WIN_ORE_TARGET` → trigger WIN state

### Must NOT

- Deposit remotely
- Skip animation entirely

---

## Blocking semantics

"Blocking" = từ góc nhìn **player script**, function chỉ return sau khi action hoàn tất.

Implementation = coroutine yield trong `api.lua`:

```lua
function api.move_to(target)
    validateAndStartMove(target)
    runner.waitUntil(function()
        return drone.state == "idle" and drone.actionComplete
    end)
end
```

**Không** dùng:

```lua
while drone.state == "moving" do end  -- BUSY WAIT = freeze
```

---

## Error handling contract

| Layer | Behavior |
|-------|----------|
| API validation | `error("message")` |
| Runner | `pcall`/`xpcall` catch → status=error |
| HUD | Show `runner.getError()` |
| Game | Continues running, simulation drawable |

Error messages — clear, English OK:

```text
Runtime error: [string "player/program.lua"]:3: Invalid move target: moon
Execution stopped: instruction budget exceeded
```

---

## Reference program

File: `player/program.lua`

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

### Expected trace (first iteration)

```text
nearest_ore() → ore#1
move_to(ore#1)  → [yield moving...] → arrive
mine()          → [yield mining...] → +1 cargo
... repeat until cargo == capacity ...
move_to("base") → [yield moving...] → arrive
deposit()       → [yield depositing...] → deposited += cargo
```

---

## Sandbox exposure

Chỉ expose đúng 6 functions trong `sandbox.createEnv()`:

```lua
return {
    move_to = api.move_to,
    nearest_ore = api.nearest_ore,
    mine = api.mine,
    cargo = api.cargo,
    capacity = api.capacity,
    deposit = api.deposit,
}
```

Optional debug (off by default): `print` wrapped to game log.

---

## API versioning note

V0.1 frozen. Future commands (`scan()`, `build()`, etc.) = issue khác.
