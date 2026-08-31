# 00 — Overview

## Một câu mô tả sản phẩm

CODE SWARM là game lập trình: người chơi **không điều khiển drone bằng WASD**, mà viết script Lua để tự động hóa — đào quặng, về base, nạp, lặp lại cho đến khi thắng.

## Core loop (phải cảm nhận được khi chơi)

```text
CODE → RUN → WATCH → FAIL / SUCCEED → EDIT → RUN AGAIN
```

## Gate 1 — loop gameplay tối thiểu

```text
find ore → move to ore → mine → fill cargo → return to base → deposit → repeat → 20 ore deposited → WIN
```

Script reference phải hoàn thành level:

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

## Hai trụ cột chất lượng Gate 1

Issue #1 + 2 comment bổ sung yêu cầu **cả hai**:

| # | Trụ cột | Nghĩa là |
|---|---------|----------|
| 1 | **Loop works** | API, runner, simulation, RUN/STOP/RESET, WIN đều đúng |
| 2 | **Loop feels like a game** | Sprite thật, animation, SFX, ambience, HUD có thiết kế |

Build chỉ logic mà trông/như technical test → **chưa DONE**.

## Luồng thực thi bắt buộc

```text
player/program.lua
        ↓
scripting/runner.lua      (coroutine + budget)
        ↓
scripting/sandbox.lua     (env giới hạn)
        ↓
scripting/api.lua         (move_to, mine, ...)
        ↓
game/drone.lua            (intent queue / current action)
        ↓
game/world.lua            (update simulation mỗi frame)
        ↓
love.draw / ui/hud.lua    (hiển thị)
```

**Cấm:** player code gọi thẳng `drone.x = 100` hoặc mutate bảng world.

## Player API — chỉ 6 hàm

```lua
move_to(target)
nearest_ore()
mine()
cargo()
capacity()
deposit()
```

Không thêm API khác trong V0.1.

## Controls bắt buộc

| Action | UI | Keyboard (gợi ý) |
|--------|-----|------------------|
| RUN | Nút | `F5` hoặc `R` |
| STOP | Nút | `Escape` |
| RESET | Nút | `F8` |

## State machine — game level

```text
                    ┌─────────┐
         RESET ────►│  IDLE   │◄──── STOP
                    └────┬────┘
                         │ RUN (valid script)
                         ▼
                    ┌─────────┐
              ┌────►│ RUNNING │────┐
              │     └────┬────┘    │
              │          │ error   │ deposited >= 20
              │          ▼         ▼
              │     ┌─────────┐ ┌──────┐
              └─────│  ERROR  │ │ WON  │
                    └─────────┘ └──────┘
```

Trong RUNNING: script có thể bị STOP → `STOPPED` (hoặc quay IDLE).

## Out of scope — TUYỆT ĐỐI KHÔNG LÀM

Nếu đang code một trong các mục dưới đây → **dừng**, quay lại core loop.

- Enemies, combat, weapons
- Nhiều drone, drone classes, upgrades
- Shop, economy phức tạp, factories, conveyor
- Tech tree, campaign, story, dialogue
- Procedural maps, multiple levels
- Online, multiplayer, leaderboard, cloud save
- Backend, database, Steam
- In-game IDE đầy đủ (code editor phức tạp)
- ECS framework, plugin architecture, DI
- npm, Node, browser, Godot, Unity, ...
- Pathfinding A* (direct movement đủ)
- Asset framework / content pipeline

## Nguyên tắc code

- Module nhỏ, tên rõ, Lua tables đơn giản
- Constants tập trung ở `game/constants.lua`
- Comment chỉ khi behavior không hiển nhiên
- Một AI/dev đọc repo phải trace được full execution path trong < 30 phút

## Definition of Done — tóm tắt

Xem checklist đầy đủ: [10-testing.md](./10-testing.md)

Câu hỏi cuối trước khi đóng issue:

> Tôi có thể viết script nhỏ, bấm RUN, nhìn drone chạy logic của tôi cho đến WIN — và nó **trông + nghe như game thật** không?

Nếu không → chưa xong.
