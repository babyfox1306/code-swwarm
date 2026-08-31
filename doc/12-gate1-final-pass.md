# 12 — Gate 1 Final Pass (cho freebuff)

> **Trạng thái hiện tại:** `YELLOW` — **một blocker anti-freeze LuaJIT**  
> **Commit tham chiếu:** `9eab18c` + runner patch (`jit.off` + hook per-resume)  
> **Issue #1:** vẫn **open** — chưa đóng cho đến C3 pass  
> **KHI NÀO ĐÓNG:** C3 pass trên máy thật + cập nhật `qa-gate1-evidence.md`

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

## Final-blocker checklist

| # | Item | Status |
|---|------|--------|
| 1 | **Anti-freeze LuaJIT-safe** | 🟡 code fixed — **C3 must pass on device** |
| 2 | Budget 50k real instructions | ✅ |
| 3 | STOP escapes ERROR → stopped | ✅ |
| 4 | No double error SFX | ✅ |
| 5 | Root MIT LICENSE | ✅ |
| 6 | Scenarios A–E | ✅ (9eab18c) |
| 7 | Scenario C3 JIT loop | ☐ **mandatory re-test** |
| 8 | `qa-gate1-evidence.md` commit SHA | ☐ update after re-test |
| 9 | No Issue #2 before PASS | ✅ |

### Anti-freeze — yêu cầu kỹ thuật (LuaJIT)

LuaJIT **không gọi debug hook** trên code đã JIT-compile (tight loop). C/C2 pass **không đủ** chứng minh.

**Runner phải có:**

```lua
local jit = require("jit")
jit.off(fn, true)   -- sau compile player chunk

-- mỗi frame, chỉ khi resume:
debug.sethook(co, hook, "c", HOOK_INTERVAL)
coroutine.resume(co)
debug.sethook(co, nil)   -- tháo ngay — không để hook sống khi drone yield
```

**Scenario C3** (`doc/10-testing.md`):

```lua
local x = 0
while true do
    x = x + 1
end
```

Chạy `love .` → budget error vài giây → STOP/RESET OK → tick C3 trong `qa-gate1-evidence.md`.

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
