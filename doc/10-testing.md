# 10 — Testing & Definition of Done

## Manual test scenarios

Chạy **tất cả** trước khi đóng issue #1.

---

### Scenario A — Happy path (bắt buộc)

**Setup:** `player/program.lua` = default mining loop

| Step | Action | Expected |
|------|--------|----------|
| 1 | Start `love .` | Window opens, ORE 0/20, drone at base |
| 2 | Press RUN | Status RUNNING, drone moves |
| 3 | Observe | Drone mines nearest ore, cargo increases |
| 4 | Observe | When cargo full, returns to base |
| 5 | Observe | Deposit increases ORE counter |
| 6 | Repeat | Cycles continue automatically |
| 7 | Wait | ORE reaches 20/20 |
| 8 | Observe | WIN overlay + win SFX |
| 9 | Press RESET | Back to 0/20, IDLE |
| 10 | RUN again | Playable from start |

**Pass:** No manual WASD at any point.

---

### Scenario B — Runtime error

**Program:**

```lua
foo()
```

| Step | Expected |
|------|----------|
| RUN | Status ERROR, message visible |
| Game | Still responsive, world visible |
| STOP | Works |
| RESET | Clears error, IDLE |

---

### Scenario C — Infinite loop

**Program:**

```lua
while true do
end
```

| Step | Expected |
|------|----------|
| RUN | Does NOT freeze window |
| Within few seconds | Budget error OR still responsive with STOP working |
| STOP | Halts |
| RESET | Full recovery |

**Fail nếu:** cửa sổ not responding, phải force quit.

---

### Scenario C2 — Hot loop (non-yielding API)

**Program:**

```lua
while true do
    cargo()
end
```

| Step | Expected |
|------|----------|
| RUN | Does NOT freeze |
| Within few seconds | Budget error |
| STOP / RESET | Work |

---

### Scenario C3 — JIT-friendly hot loop (bắt buộc cho LuaJIT)

**Program:**

```lua
local x = 0
while true do
    x = x + 1
end
```

| Step | Expected |
|------|----------|
| RUN | Does NOT freeze — budget error within seconds |
| STOP | Halts if still running |
| RESET | Full recovery |

**Tại sao:** LuaJIT **không gọi debug hook** trên code đã JIT-compile. Scenario C/C2 có thể pass nhưng C3 mới là stress test thật. Runner phải có `jit.off(fn, true)` và hook chỉ arm quanh `coroutine.resume()`.

**Fail nếu:** game not responding — anti-freeze chưa LuaJIT-safe.

---

### Scenario D — Invalid target

**Program:**

```lua
move_to("moon")
```

| Step | Expected |
|------|----------|
| RUN | Controlled error in HUD |
| Game | No crash |

---

### Scenario E — Reset during action

**Program:** default mining loop

| Step | Action | Expected |
|------|--------|----------|
| 1 | RUN | Drone moving or mining |
| 2 | RESET mid-action | Execution stops |
| 3 | Check | Drone at base, cargo 0, ore 0/20, ores full |
| 4 | RUN | Works normally |

---

### Scenario F — Cargo cap

**Program (test):**

```lua
while cargo() < 100 do
    move_to(nearest_ore())
    mine()
end
```

| Expected |
|----------|
| cargo never exceeds capacity() |
| No crash when ore still available |

---

### Scenario G — Depleted ore skip

Sau nhiều vòng, một ore hết.

| Expected |
|----------|
| `nearest_ore()` returns another node |
| Script continues without manual fix |

---

### Scenario H — Deposit empty cargo

**Program:**

```lua
move_to("base")
deposit()
```

| Expected |
|----------|
| No crash (no-op OK) |
| deposited unchanged |

---

### Scenario I — Offline / fresh clone

| Step | Expected |
|------|----------|
| Clone repo on machine without itch.io access | — |
| `love .` | Runs with all sprites/sounds local |
| No network errors | — |

---

### Scenario J — Presentation gate

Mở game fresh, hỏi:

> Does this feel like a small actual game?

| Check | Pass |
|-------|------|
| Real sprites, not placeholder shapes | ☐ |
| Floor/environment coherent | ☐ |
| Mining visually obvious | ☐ |
| Deposit visually obvious | ☐ |
| HUD designed, not debug dump | ☐ |
| SFX on key actions | ☐ |
| Background music/ambience | ☐ |
| RUN/STOP/ERROR/WIN feedback | ☐ |

---

## Definition of Done — master checklist

Copy vào PR description khi xong.

### Core tech

- [ ] Runs in LÖVE2D only (`love .`)
- [ ] Visible 2D world
- [ ] 1 drone, 1 base, ≥3 ore nodes
- [ ] Player code in `player/program.lua`
- [ ] RUN / STOP / RESET work
- [ ] 6 API functions behave per [04-api-spec.md](./04-api-spec.md)
- [ ] `move_to` visible movement, no teleport
- [ ] `mine` visible delay + cargo transfer
- [ ] Cargo never exceeds capacity
- [ ] `deposit` updates total, clears cargo
- [ ] HUD: ore X/20, cargo, status, error
- [ ] 20 ore → WIN state
- [ ] Script errors shown, no LÖVE crash
- [ ] Infinite loop cannot freeze app
- [ ] Sandbox blocks os/io/loadfile
- [ ] Default script completes level unattended
- [ ] RESET after WIN works

### Visual / audio (issue comments)

- [ ] Local PNG/spritesheets, not primitive primary art
- [ ] Drone recognizable sprite + motion
- [ ] Sci-fi/industrial floor treatment
- [ ] Base looks like station/building
- [ ] Ore looks intentional
- [ ] Mining feedback visible
- [ ] Deposit feedback visible
- [ ] HUD intentionally designed
- [ ] Key SFX present (see [08-assets-audio.md](./08-assets-audio.md))
- [ ] Looping music or ambience
- [ ] `assets/SOURCE.md` complete
- [ ] Offline after clone

### Out of scope verified absent

- [ ] No combat, shop, multiplayer, ECS, npm, etc.

---

## Smoke test command

```bash
# From repo root
love .
```

Windows: đảm bảo `love` trong PATH hoặc drag folder lên love.exe.

---

## Known acceptable limitations V0.1

| Limitation | OK? |
|------------|-----|
| Edit code in external editor only | ✓ |
| No pathfinding around walls | ✓ |
| Single level | ✓ |
| English UI only | ✓ |
| No save game | ✓ |

---

## Bug severity

| Severity | Examples | Block release? |
|----------|----------|----------------|
| P0 | Freeze, crash, can't WIN | Yes |
| P1 | API wrong, RESET broken | Yes |
| P2 | Missing SFX, HUD ugly | Yes per issue comments |
| P3 | Minor visual glitch | No if timeboxed |

---

## Sign-off

| Role | Name | Date | OK |
|------|------|------|-----|
| Implementer | freebuff | | ☐ |
| Reviewer | babyfox1306 | | ☐ |
