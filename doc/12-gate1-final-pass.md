# 12 — Gate 1 Final Pass (cho freebuff)

> **Trạng thái hiện tại:** `YELLOW` — rất gần PASS, **chưa đóng Issue #1**  
> **Commit tham chiếu:** `c9ed8b0` — *V0.1 playable core loop — M1-M10 complete*  
> **Đọc file này trước** khi làm thêm bất cứ feature nào.

---

## Bạn đang ở đâu?

M1–M10 **đã xong về code**. Không cần đập lại architecture, không thêm enemy/shop/level 2.

Việc còn lại là **final pass ngắn**: sửa 1–2 gap nhỏ + **chứng minh runtime** scenarios A–E.

```
┌─────────────────────────────────────────────────────────┐
│  Architecture / core loop     → PASS (static review)   │
│  Assets / VFX / HUD           → PASS                   │
│  Runtime verification         → UNKNOWN  ← làm ở đây │
│  Music feel                   → borderline             │
└─────────────────────────────────────────────────────────┘
```

Khi xong file này → báo: **CODE SWARM V0.1 — GATE 1 PASS**

---

## Đã PASS — đừng sửa lung tung

| Hạng mục | Ghi chú |
|----------|---------|
| Mouse RUN/STOP/RESET | `main.lua` → `doAction()` |
| Keyboard F5 / R / Esc / F8 | Khớp README |
| Layout 960×540, nút trong màn | `ui/hud.lua` |
| 6 Player API | `scripting/api.lua` |
| `mine()` nhớ ore từ `move_to()` | `drone.lastMoveTarget` |
| Sandbox | `load(..., "t", env)` — **hợp lệ LuaJIT 2.1** |
| Coroutine + instruction budget | `scripting/runner.lua` |
| WIN @ 20 + stop script | `main.lua` gọi `runner:onWin()` |
| 7 SFX file + drone hum | `game/audio.lua` + `assets/audio/sfx/` |
| Sprites/tiles/VFX | `game/assets.lua`, `game/effects.lua` |
| Demo hardcode / phím T | Đã xóa |

---

## Việc BẮT BUỘC trước khi đóng Gate 1

### Task 1 — Runtime error SFX (code fix)

**Vấn đề:** `Audio.play("error")` chỉ chạy khi RUN fail compile/load. Lỗi **trong lúc script chạy** (`foo()`, `move_to("moon")`, budget exceeded) chỉ hiện HUD, **không có tiếng**.

**File:** `main.lua` — trong `love.update`, block sync error.

**Hiện tại:**

```lua
if runner:getStatus() == "error" then
    hud:setError(runner:getError())
end
```

**Cần:** phát error SFX **một lần** khi chuyển sang trạng thái error (tránh spam mỗi frame).

Gợi ý implementation:

```lua
-- đầu main.lua, sau local hud = ...
local lastRunnerStatus = "idle"

-- trong love.update, thay block error:
local status = runner:getStatus()
if status == "error" then
    if lastRunnerStatus ~= "error" then
        Audio.play("error")
    end
    hud:setError(runner:getError())
elseif status ~= "error" then
    -- optional: không clear error ở đây nếu STOP đã clear
end
lastRunnerStatus = status
```

Hoặc đặt flag `runner.errorSfxPlayed` trong `runner.lua` khi set `status = "error"`.

**Verify:** `player/program.lua` = `foo()` → RUN → nghe error SFX + HUD đỏ.

---

### Task 2 — Ambience / music (quyết định + hành động)

**Hiện tại:** ambience = sine wave procedural 4s loop (`game/audio.lua`).

Issue chấp nhận: *"looping background music **or** ambience"*.

**Làm một trong hai:**

| Option | Hành động |
|--------|-----------|
| **A — Giữ procedural** | Nghe tay — nếu đủ “lab/industrial hum” thì OK. Ghi trong QA report: *“Ambience procedural accepted for V0.1”* |
| **B — Thay track thật** | Tải 1 file CC0 ngắn (~30–60s loop) → `assets/audio/music/ambience.ogg` → load trong `Audio.load()`, ghi `assets/SOURCE.md` |

**Không** spend > 30 phút tìm nhạc. Kenney / OpenGameArt CC0 là đủ.

---

### Task 3 — Runtime evidence A–E (bắt buộc)

Issue #1 yêu cầu manual verify. **Phải chạy `love .` thật** và điền bảng.

Tạo file: **`doc/qa-gate1-evidence.md`** (copy template bên dưới, điền Pass/Fail + ghi chú).

#### Scenario A — Happy path

1. `player/program.lua` = script mặc định (while loop mining)
2. RUN → đợi WIN
3. **Expected:**
   - ORE dừng **đúng 20/20** (không 21+)
   - Overlay MISSION COMPLETE
   - Drone **đứng yên**, script stopped (`status = won`)
   - RESET → chơi lại được

#### Scenario B — Runtime error

`player/program.lua`:

```lua
foo()
```

RUN → **Expected:** HUD error, game responsive, error SFX (sau Task 1), STOP/RESET OK.

#### Scenario C — Infinite loop

```lua
while true do
end
```

RUN → **Expected:** không freeze, budget error hoặc STOP hoạt động, RESET recovery.

#### Scenario D — Invalid target

```lua
move_to("moon")
```

RUN → **Expected:** controlled error, không crash.

#### Scenario E — RESET during action

1. Script mining mặc định → RUN
2. Khi drone đang move/mine → RESET
3. **Expected:** drone về base, cargo 0, ore 0/20, ores full, IDLE.

---

### Task 4 (khuyến nghị) — Ore sprite đúng asset

**Vấn đề:** `assets/sprites/ore.png` hiện giống spritesheet **nhân vật đi bộ**, không phải quặng/thùng. `SOURCE.md` ghi “radioactive barrel”.

**Fix nhanh:**

1. Copy `assets/vendor/robot-lab/exports/robot-lab_v1.0/radioactive_barrel.png` → `assets/sprites/ore.png`
2. Cập nhật `game/assets.lua` — số frame / kích thước quad nếu khác 8×16
3. Verify trong game ore node trông như resource prop

Không blocker gameplay — nhưng nên fix trước khi đóng Gate 1 nếu còn 10 phút.

---

## Template — `doc/qa-gate1-evidence.md`

Copy và điền sau khi test:

```markdown
# Gate 1 — Runtime QA Evidence

- **Tester:** freebuff
- **Date:** YYYY-MM-DD
- **Commit:** (git rev-parse --short HEAD)
- **LÖVE version:** love --version hoặc 11.5
- **OS:** Windows / ...

## Results

| ID | Scenario | Pass? | Notes |
|----|----------|-------|-------|
| A | Happy path → WIN @ 20 | ☐ | |
| B | `foo()` runtime error | ☐ | Error SFX: ☐ |
| C | `while true do end` | ☐ | |
| D | `move_to("moon")` | ☐ | |
| E | RESET mid-action | ☐ | |

## Presentation check

| Item | Pass? |
|------|-------|
| Drone sprite (not green rectangle) | ☐ |
| Floor tiles visible | ☐ |
| Ore looks like resource (not wrong sprite) | ☐ |
| Mining VFX visible | ☐ |
| Deposit VFX visible | ☐ |
| Ambience / music acceptable | ☐ |

## Final gate question

> Does this feel like a small actual game, or a technical test?

Answer: ...

## Sign-off

- [ ] All scenarios A–E Pass
- [ ] Task 1 (runtime error SFX) done
- [ ] Task 2 (ambience decision documented)
- [ ] Ready to close Issue #1
```

---

## KHÔNG làm trong final pass

- Enemy, combat, shop, factory
- Level 2, campaign, procedural map
- Đổi player language sang Python/JS
- In-game IDE đầy đủ
- ECS / refactor lớn
- Feature mới cho Issue #2

**Player language V0.1 = Lua — locked.** Issue #2 bàn sau khi Gate 1 PASS.

---

## Thứ tự làm (30–60 phút)

```
1. Fix runtime error SFX          (~10 min)
2. (Optional) Fix ore.png           (~10 min)
3. Nghe ambience — giữ hoặc thay   (~10–20 min)
4. Chạy scenarios A–E             (~15 min)
5. Điền doc/qa-gate1-evidence.md   (~5 min)
6. Commit + comment Issue #1        (~5 min)
```

---

## Commit message gợi ý

```
fix: Gate 1 final pass — runtime error SFX + QA evidence

- Play error sound when runner hits runtime error (not only compile)
- Add doc/qa-gate1-evidence.md with manual test results
- (optional) Replace ore sprite with radioactive_barrel
```

---

## Khi nào được báo GATE 1 PASS?

Chỉ khi **tất cả** đúng:

- [ ] Task 1 done
- [ ] Task 2 decided (procedural OK **hoặc** real track + SOURCE.md)
- [ ] `doc/qa-gate1-evidence.md` — A–E đều Pass
- [ ] Không regression: mouse + keyboard controls vẫn OK
- [ ] Không thêm out-of-scope

Báo owner:

```text
CODE SWARM V0.1 — GATE 1 PASS
Commit: <hash>
Evidence: doc/qa-gate1-evidence.md
Issue #1 ready to close.
```

---

## Prompt ngắn (nếu cần paste lại)

```
Đọc doc/12-gate1-final-pass.md. Gate 1 = YELLOW.
Làm Task 1–3 (error SFX, ambience decision, runtime A–E + qa-gate1-evidence.md).
Optional Task 4 ore sprite. Không thêm feature. Báo GATE 1 PASS khi xong.
```
