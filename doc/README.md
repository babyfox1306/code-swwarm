# CODE SWARM — V0.1 Implementation Docs

> **Thi công:** freebuff  
> **Issue:** [#1 — Playable Core Loop](https://github.com/babyfox1306/code-swwarm/issues/1)  
> **Mục tiêu:** Vertical slice chơi được — viết code → RUN → drone đào quặng → nạp base → WIN @ 20 ore

---

## Cách dùng bộ doc này

Đọc theo thứ tự số. **Không nhảy bước.** Mỗi milestone có checklist riêng — tick xong mới sang milestone tiếp.

| # | File | Nội dung |
|---|------|----------|
| 00 | [00-overview.md](./00-overview.md) | Tổng quan, nguyên tắc, out-of-scope |
| 01 | [01-architecture.md](./01-architecture.md) | Kiến trúc, luồng dữ liệu, module boundaries |
| 02 | [02-file-structure.md](./02-file-structure.md) | Cây thư mục + spec từng file |
| 03 | [03-milestones.md](./03-milestones.md) | **Lộ trình thi công từng bước** (quan trọng nhất) |
| 04 | [04-api-spec.md](./04-api-spec.md) | Player API — hợp đồng bắt buộc |
| 05 | [05-script-runner.md](./05-script-runner.md) | Sandbox, coroutine, chống freeze |
| 06 | [06-simulation.md](./06-simulation.md) | Drone, ore, base, world state machine |
| 07 | [07-ui-hud.md](./07-ui-hud.md) | Layout HUD, controls, state display |
| 08 | [08-assets-audio.md](./08-assets-audio.md) | Sprite, tile, SFX, music |
| 09 | [09-constants.md](./09-constants.md) | Số liệu tuning — một nơi duy nhất |
| 10 | [10-testing.md](./10-testing.md) | Kịch bản test + Definition of Done |
| 12 | [12-gate1-final-pass.md](./12-gate1-final-pass.md) | **Final pass Gate 1** — việc còn lại trước khi đóng Issue #1 |

> **Nếu M1–M10 đã xong:** đọc **[12-gate1-final-pass.md](./12-gate1-final-pass.md)** thay vì làm thêm feature.

---

## Quy tắc vàng (đọc trước khi code)

1. **PLAYABLE LOOP > mọi thứ khác** — mỗi commit phải tiến gần hơn tới game chơi được.
2. **Không over-engineer** — module nhỏ, state rõ, không ECS/DI/framework.
3. **Player code không mutate world trực tiếp** — mọi thứ qua API + simulation.
4. **`while true do end` không được freeze game** — non-negotiable.
5. **Primitive shapes chỉ dùng tạm khi dev** — Gate 1 phải có sprite + audio thật.
6. **Out-of-scope = cấm** — xem [00-overview.md](./00-overview.md).

---

## Tech stack

| Thành phần | Lựa chọn |
|------------|----------|
| Engine | LÖVE 11.x |
| Language | Lua 5.1 (LÖVE embedded) |
| Chạy game | `love .` từ root repo |
| Player code | `player/program.lua` |
| Assets | Local PNG/OGG trong `assets/` |

---

## Thứ tự thi công tóm tắt

```
M1 Boot → M2 Static World → M3 Simulation → M4 Player API
    → M5 Script Runner → M6 Full Loop → M7 Assets → M8 Audio → M9 Polish → M10 QA
```

Chi tiết từng milestone: **[03-milestones.md](./03-milestones.md)**

---

## Khi bị kẹt

| Triệu chứng | Đọc file |
|-------------|----------|
| Không biết file nào viết gì | [02-file-structure.md](./02-file-structure.md) |
| `move_to` / `mine` behavior | [04-api-spec.md](./04-api-spec.md) + [06-simulation.md](./06-simulation.md) |
| Game freeze khi RUN | [05-script-runner.md](./05-script-runner.md) |
| HUD / nút bấm | [07-ui-hud.md](./07-ui-hud.md) |
| Sprite / sound thiếu gì | [08-assets-audio.md](./08-assets-audio.md) |
| Không biết xong chưa | [10-testing.md](./10-testing.md) |
