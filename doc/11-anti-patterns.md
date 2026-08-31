# 11 — Anti-patterns & FAQ

> Đọc khi tempted thêm feature hoặc khi stuck.

---

## Anti-patterns — ĐỪNG LÀM

### 1. Gọi player script trực tiếp trên main thread

```lua
-- BAD
dofile("player/program.lua")
```

→ Freeze guaranteed với `while true`.

### 2. Busy-wait trong API

```lua
-- BAD
function api.move_to(t)
    startMove(t)
    while drone.state == "moving" do end
end
```

→ Dùng coroutine yield.

### 3. Expose world/drone table cho player

```lua
-- BAD
env.drone = world.drone
```

→ Player set `drone.x = 999`.

### 4. Teleport drone trong move_to

```lua
-- BAD
drone.x, drone.y = target.x, target.y
```

→ Phải simulate over frames.

### 5. ECS / class hierarchy sâu

```lua
-- BAD for V0.1
EntityManager:addComponent(drone, Transform.new())
```

→ Plain tables + functions.

### 6. Scene editor / JSON levels

→ Hardcode positions trong `constants.lua` đủ.

### 7. Thêm API "tiện"

```lua
wait(1)
print_debug()
goto(x, y)
```

→ Scope creep. Chỉ 6 hàm.

### 8. Asset manager 500 dòng

→ `love.graphics.newImage` + table là đủ.

### 9. In-game Monaco editor

→ External edit `program.lua` + RUN reload.

### 10. Fix art trước simulation

→ M2 placeholders → M3–M6 logic → M7 art.

---

## FAQ

### Q: `require` trong player script?

**A:** Không. Sandbox không expose `require`.

### Q: Player dùng `if` / `while` / `function`?

**A:** Có — đó là Lua bình thường trong chunk. Chỉ giới hạn **globals/callables** available.

### Q: `move_to` khi drone đang busy?

**A:** Option đơn giản: error `"Drone busy"`. Hoặc queue — không cần V0.1.

### Q: Script kết thúc trước WIN?

**A:** Status → idle. Drone đứng yên. OK.

### Q: Nhiều `mine()` liên tiếp không yield?

**A:** Mỗi `mine()` phải blocking đủ duration.

### Q: `nearest_ore()` khi đứng tại ore?

**A:** Return node đó nếu còn ore.

### Q: Win khi script đang trong `move_to`?

**A:** Deposit trigger win → `runner.onWin()` stop script.

### Q: LÖVE version?

**A:** 11.4+ recommended. Test trên target platform.

### Q: package.path không work?

**A:**

```lua
package.path = love.filesystem.getSource() .. "/?.lua;" .. package.path
```

### Q: love.filesystem vs io.open cho program.lua?

**A:** Dùng `love.filesystem` — sandbox consistent với LÖVE.

### Q: Drone đi xuyên "wall" decorative?

**A:** OK V0.1 — walls visual only.

### Q: Không tìm được ore sprite?

**A:** Custom 16×16 crystal pixel — 15 phút, ghi SOURCE.md.

### Q: Audio file quá lớn?

**A:** OGG compress, music < 5MB, trim loops.

---

## Khi reviewer reject

| Feedback | Action |
|----------|--------|
| "Looks like tech demo" | M7–M9, không thêm gameplay |
| "Freezes on RUN" | Fix runner M5 |
| "Can't win" | Tune constants + ore amounts |
| "Too scope" | Re-read [00-overview.md](./00-overview.md) out-of-scope |

---

## Contact / handoff

- Issue: GitHub #1
- Docs: `doc/README.md`
- Implementer: **freebuff**
