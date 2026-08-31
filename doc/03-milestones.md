# 03 — Milestones (Lộ trình thi công)

> **Quy tắc:** Hoàn thành checklist milestone N trước khi bắt đầu N+1.  
> Mỗi milestone nên = 1 commit (hoặc 1 PR nhỏ) có message rõ.

---

## M1 — Bootable LÖVE project

**Mục tiêu:** `love .` mở cửa sổ, nền màu, không crash.

### Tasks

- [ ] Tạo `main.lua` — `love.load` set background color
- [ ] Tạo `conf.lua` — title "CODE SWARM", 960×540
- [ ] Setup `package.path` cho require modules
- [ ] Verify LÖVE 11.x installed

### Files tạo

```text
main.lua
conf.lua
```

### Verify

```bash
love .
```

→ Cửa sổ mở, không error console.

### Commit message gợi ý

`feat: bootstrap LÖVE project (M1)`

---

## M2 — Static world (chưa simulation)

**Mục tiêu:** Nhìn thấy map, base, drone, 3 ore, HUD placeholder.

### Tasks

- [ ] `game/constants.lua` — placeholder positions, WIN_ORE=20
- [ ] `game/world.lua` — init + draw only
- [ ] `game/drone.lua` — position + draw (rectangle OK tạm)
- [ ] `game/ore.lua` — 3 nodes + draw
- [ ] `game/base.lua` — draw
- [ ] `ui/hud.lua` — header, ore 0/20, cargo 0/5, status IDLE, 3 nút
- [ ] Wire `main.lua` load/draw/update(hud only)

### Layout map (world coordinates)

```text
Map: 800×400 playable area (centered in window)
Base:  (80, 200)
Drone: (80, 200) — start at base
Ore 1: (400, 80)
Ore 2: (650, 200)
Ore 3: (400, 320)
```

Điều chỉnh khi có sprite — giữ relative spacing.

### Verify

- [ ] 3 ore nodes visible & distinguishable
- [ ] Base visible left side
- [ ] Drone visible at base
- [ ] HUD shows 0/20 ore, cargo 0/capacity
- [ ] RUN/STOP/RESET buttons visible (chưa cần hoạt động)

### Commit

`feat: static world + HUD shell (M2)`

---

## M3 — World simulation (hardcoded, no script)

**Mục tiêu:** Drone tự động demo loop bằng hardcode trong `world.lua` hoặc debug key — chứng minh movement/mining/deposit works.

### Tasks

- [ ] Drone state machine: idle → moving → mining → depositing
- [ ] Movement interpolation over multiple frames (lerp toward target)
- [ ] Mining timer (~1.5s) — ore↓ cargo↑
- [ ] Cargo cap enforced
- [ ] Deposit at base — deposited counter↑ cargo=0
- [ ] Win when deposited >= 20
- [ ] RESET keyboard/debug restores state

### Tạm thời

Press `T` (test key) để chạy một chu kỳ: move ore → mine → move base → deposit.

Hoặc `world.demoMode = true` auto-run.

### Verify

- [ ] Drone **không teleport** — di chuyển mượt
- [ ] Mining có delay visible
- [ ] Cargo không vượt capacity
- [ ] Deposit cập nhật HUD counter
- [ ] 20 ore → WIN text xuất hiện

### Commit

`feat: drone simulation state machine (M3)`

---

## M4 — Player API layer

**Mục tiêu:** 6 API functions wired to drone intents (chưa cần coroutine — có thể gọi thủ công từ console test).

### Tasks

- [ ] `scripting/api.lua` — implement 6 functions
- [ ] `move_to("base")`, `move_to(oreTarget)`
- [ ] `nearest_ore()` — return handle
- [ ] `mine()`, `deposit()` — blocking via busy wait **tạm** (sẽ thay bằng yield M5)
- [ ] Invalid target → `error("...")` with pcall catch test
- [ ] `player/program.lua` — default script file

### Verify (manual REPL-style hoặc test chunk)

```lua
-- test.lua nội bộ, không ship
pcall(function()
    move_to(nearest_ore())
    mine()
end)
```

- [ ] `cargo()` returns correct value after mine
- [ ] `move_to("moon")` → controlled error

### Commit

`feat: player API bridge to simulation (M4)`

---

## M5 — Controlled script runner

**Mục tiêu:** RUN/STOP/RESET + coroutine yield + instruction budget. **Game không freeze.**

### Tasks

- [ ] `scripting/sandbox.lua` — restricted env
- [ ] `scripting/runner.lua` — full lifecycle
- [ ] Refactor `api.lua` — `runner.yieldUntil(drone.isBusy)` thay busy-wait
- [ ] Debug hook instruction budget (e.g. 50,000 ops/frame)
- [ ] RUN loads `player/program.lua` fresh
- [ ] STOP halts coroutine, drone finishes or cancels action (document choice: cancel pending)
- [ ] RESET → world.reset + runner idle
- [ ] Errors display in HUD

### Anti-freeze test (BẮT BUỘC pass)

`player/program.lua`:

```lua
while true do end
```

→ Game responsive, buttons work, budget message or auto-stop.

### Verify

| Scenario | Expected |
|----------|----------|
| RUN valid script | Drone executes |
| STOP mid-run | Halt, status STOPPED |
| RESET mid-run | Full initial state |
| `foo()` in program | Error in HUD, no crash |
| Infinite loop | No freeze |

### Commit

`feat: sandboxed coroutine runner with instruction budget (M5)`

---

## M6 — Full gameplay loop

**Mục tiêu:** Default `player/program.lua` hoàn thành level đến WIN không can thiệp tay.

### Tasks

- [ ] Tune speeds/timers ([09-constants.md](./09-constants.md))
- [ ] Ore amount per node đủ cho 20 deposited (e.g. 10 each)
- [ ] `nearest_ore()` skips depleted nodes
- [ ] Win overlay blocks confusion (semi-transparent overlay + big text)
- [ ] After WIN, script stops; RESET works

### Verify — Scenario A (happy path)

1. Start game — 0/20
2. RUN
3. Watch full cycle until WIN
4. No keyboard control needed

### Commit

`feat: complete Gate 1 core loop to WIN (M6)`

---

## M7 — Visual assets integration

**Mục tiêu:** Thay placeholder bằng sprite thật — game nhìn như robotics lab.

### Tasks

- [ ] Download [Robot Lab Asset Pack](https://murphysdad.itch.io/robot-lab-asset-pack)
- [ ] Place under `assets/vendor/robot-lab/`
- [ ] Create `assets/SOURCE.md`
- [ ] Slice/copy usable sprites → `assets/sprites/`, `assets/tiles/`
- [ ] Tiled floor background
- [ ] Drone spritesheet animation (hover/move frames)
- [ ] Base building sprite
- [ ] Ore prop (pack hoặc derived 16×16 crystal)
- [ ] `love.graphics.setDefaultFilter("nearest", "nearest")`
- [ ] Integer scale (×2 or ×3) for crisp pixels

### Verify

- [ ] No colored circles/rects as primary art
- [ ] Coherent sci-fi industrial look
- [ ] Game runs offline after clone

### Commit

`feat: integrate Robot Lab CC0 sprites (M7)`

---

## M8 — Animation & VFX juice

**Mục tiêu:** Movement feel, mining feedback, deposit feedback.

### Tasks

- [ ] `game/effects.lua` — simple particle pool
- [ ] Mining: beam line or ore pulse + particles
- [ ] Deposit: base flash + particles
- [ ] Drone bob while idle/hover
- [ ] Optional: orient drone toward movement direction

### Verify

- [ ] Mining visually obvious
- [ ] Deposit visually obvious
- [ ] Drone not static sprite sliding

### Commit

`feat: mining/deposit VFX and drone motion (M8)`

---

## M9 — Audio

**Mục tiêu:** Game có sound — không im lặng.

### Tasks

- [ ] Source free/CC0 SFX (kenney.nl, freesound.org, etc.)
- [ ] Document in `assets/SOURCE.md`
- [ ] Files in `assets/audio/sfx/` and `assets/audio/music/`
- [ ] Implement in `main.lua` or `game/audio.lua` (thin wrapper)

### Minimum sounds

| Event | File |
|-------|------|
| UI click | `ui_click.ogg` |
| RUN | `run_start.ogg` |
| STOP | `run_stop.ogg` |
| Drone loop | `drone_hum.ogg` (loop, low volume) |
| Mining | `mine.ogg` |
| Deposit | `deposit.ogg` |
| Error | `error.ogg` |
| Win | `win.ogg` |
| Ambience | `ambience.ogg` (loop, quieter than SFX) |

### Mix levels (starting point)

```lua
music: 0.3
sfx:   0.8
drone: 0.2
```

### Verify

- [ ] All state transitions have audio feedback
- [ ] No clipping / ear pain
- [ ] Works offline

### Commit

`feat: SFX and background ambience (M9)`

---

## M10 — HUD polish & QA

**Mục tiêu:** HUD đọc như game UI; pass full test matrix.

### Tasks

- [ ] HUD panels với background rects / 9-slice optional
- [ ] Color-coded status: running=green, error=red, won=gold
- [ ] Error message area multi-line truncate
- [ ] Run full [10-testing.md](./10-testing.md) checklist
- [ ] Fix bugs found
- [ ] Remove debug keys / demo mode
- [ ] Update root `README.md` — how to run, controls

### Final gate question

> Does this feel like a small actual game?

If no → iterate M7–M9, **not** add features.

### Commit

`feat: HUD polish and V0.1 QA pass (M10)`

---

## Timeline gợi ý (không cứng)

| Milestone | Effort ước lượng |
|-----------|------------------|
| M1–M2 | 2–4 giờ |
| M3 | 4–6 giờ |
| M4–M5 | 6–10 giờ (phần khó nhất) |
| M6 | 2–4 giờ |
| M7–M9 | 4–8 giờ |
| M10 | 2–4 giờ |

**Tổng:** ~20–36 giờ cho 1 dev có kinh nghiệm LÖVE.

---

## Khi muốn skip — KHÔNG ĐƯỢC skip

- M5 (runner) — core requirement
- M6 (full loop) — definition of product
- M7+ (assets/audio) — mandatory per issue comments

## Được phép song song (cẩn thận)

- M7 assets có thể tải trong lúc M3–M5 nếu không distraction
- M9 audio có thể làm song song M8

**Không** làm M7 thay cho M3 — simulation trước, đẹp sau.
